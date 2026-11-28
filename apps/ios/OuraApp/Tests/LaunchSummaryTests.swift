import XCTest
import SwiftUI
@testable import OuraApp

private final class SummaryBox: @unchecked Sendable { var value: Summary? }
private final class ReadCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var hits = 0
    func hit() { lock.lock(); hits += 1; lock.unlock() }
    var count: Int { lock.lock(); defer { lock.unlock() }; return hits }
}

/// The home must never sit on "Loading your data…" behind the automatic ring sync,
/// which holds `WorkGate` for its whole run (TestFlight 0.1.2 (10)).
final class LaunchSummaryTests: XCTestCase {
    private func missingDBPath() -> String {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("launch-\(UUID().uuidString)/oura.db").path
    }

    /// Fresh install: no cache, no DB file, and a sync already owns the gate.
    /// The first summary must arrive without waiting for that sync.
    func testFreshInstallGetsSummaryWhileSyncHoldsTheGate() async {
        let gate = WorkGate()
        await gate.acquire()   // a running sync, never released in this test
        let path = missingDBPath()
        let done = expectation(description: "first summary")
        let box = SummaryBox()
        Task {
            box.value = await LaunchSummary.first(dbPath: path, gate: gate, isAvailable: { false }) { _ in
                XCTFail("must not read a database that does not exist")
                return Summary()
            }
            done.fulfill()
        }
        await fulfillment(of: [done], timeout: 2)
        XCTAssertNotNil(box.value)
        XCTAssertEqual(box.value?.error, LaunchSummary.noDataMessage)
        XCTAssertTrue(box.value?.nights.isEmpty ?? false, "no invented values on the empty state")
    }

    /// With a database on disk the first summary is the real model-free read,
    /// taken under the gate and released afterwards.
    func testExistingDatabaseIsReadUnderTheGate() async throws {
        let path = try existingDBPath()
        let gate = WorkGate()
        await gate.acquire()   // another owner (a sync) holds the database
        let reads = ReadCounter()
        let done = expectation(description: "first summary")
        let box = SummaryBox()
        Task {
            box.value = await LaunchSummary.first(dbPath: path, gate: gate, isAvailable: { true }) { readPath in
                reads.hit()
                var stored = Summary()
                stored.digest = "read from \(URL(fileURLWithPath: readPath).lastPathComponent)"
                return stored
            }
            done.fulfill()
        }
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(reads.count, 0, "the database must not be read while another owner holds the gate")
        await gate.release()
        await fulfillment(of: [done], timeout: 2)
        XCTAssertEqual(reads.count, 1)
        XCTAssertEqual(box.value?.digest, "read from oura.db")
        XCTAssertNil(box.value?.error)
        // The gate is free again: a sync that starts next does not hang.
        let reacquired = expectation(description: "gate released")
        Task { await gate.acquire(); reacquired.fulfill() }
        await fulfillment(of: [reacquired], timeout: 2)
    }

    /// Backgrounded or locked while waiting for the gate: skip the read, free the gate.
    func testUnavailableAppSkipsTheReadAndReleasesTheGate() async throws {
        let path = try existingDBPath()
        let gate = WorkGate()
        let reads = ReadCounter()
        let first = await LaunchSummary.first(dbPath: path, gate: gate, isAvailable: { false }) { _ in
            reads.hit()
            return Summary()
        }
        XCTAssertNil(first)
        XCTAssertEqual(reads.count, 0)
        let reacquired = expectation(description: "gate released")
        Task { await gate.acquire(); reacquired.fulfill() }
        await fulfillment(of: [reacquired], timeout: 2)
    }

    private func existingDBPath() throws -> String {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("launch-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: dir) }
        let path = dir.appendingPathComponent("oura.db").path
        XCTAssertTrue(FileManager.default.createFile(atPath: path, contents: Data()))
        return path
    }

    /// The loading screen always offers the way to the sync sheet.
    @MainActor func testLoadingViewOffersSyncAction() {
        var opened = false
        let view = LoadingView(ring: RingSync()) { opened = true }
        XCTAssertEqual(LoadingView.syncActionTitle, "Sync your ring")
        view.onSync()
        XCTAssertTrue(opened)
    }

    /// Opt-in render of the loading screen (dark, default and largest text) for the
    /// design check: pass TEST_RUNNER_SNAPSHOT_DIR=<dir> to the test run. Skipped otherwise.
    @MainActor func testRenderLoadingViewSnapshots() throws {
        guard let dir = ProcessInfo.processInfo.environment["SNAPSHOT_DIR"], !dir.isEmpty else {
            throw XCTSkip("set TEST_RUNNER_SNAPSHOT_DIR to render the loading screen")
        }
        let ring = RingSync()
        ring.busy = true
        ring.status = "Resuming sync…"
        for (name, size) in [("loading-dark", DynamicTypeSize.large), ("loading-dark-ax5", .accessibility5)] {
            let root = ZStack { Obs.canvas; LoadingView(ring: ring) {} }.dynamicTypeSize(size)
            let host = UIHostingController(rootView: root)
            // A window outside a scene is never displayed, so it would draw blank.
            let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
            let window = UIWindow(windowScene: scene)
            window.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
            window.overrideUserInterfaceStyle = .dark
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.5))
            let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
                _ = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            let url = URL(fileURLWithPath: dir).appendingPathComponent("\(name).png")
            try XCTUnwrap(image.pngData()).write(to: url)
            window.isHidden = true
        }
    }
}
