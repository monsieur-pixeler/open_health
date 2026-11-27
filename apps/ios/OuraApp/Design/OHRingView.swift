import SwiftUI

/// "Mijn ring": battery, status and the actions this app really has.
struct OHRingView: View {
    let ring: OHRingState
    var onSync: () async -> Bool = { true }
    var onBackupKey: () -> Void = {}
    var onExportRawData: () -> Void = {}
    var onWipe: () async -> Void = {}

    @State private var isSyncing = false
    @State private var completedSyncs = 0
    @State private var isConfirmingWipe = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OHSpace.l) {
                Text("Mijn ring")
                    .font(.ohSerif(.largeTitle))
                    .foregroundStyle(OHTheme.ink)
                    .padding(.top, OHSpace.s)
                    .accessibilityAddTraits(.isHeader)

                OHBatteryCard(ring: ring)

                VStack(spacing: 0) {
                    actionRow("Nu synchroniseren", systemImage: "arrow.triangle.2.circlepath", color: OHTheme.teal,
                              hint: "Haalt de nieuwe metingen van je ring op", showsProgress: isSyncing) {
                        Task { await sync() }
                    }
                    .disabled(isSyncing || !ring.isConnected)
                    divider
                    actionRow("Sleutel back-uppen", systemImage: "key", color: OHTheme.ink,
                              hint: "Bewaart de koppelsleutel in je iCloud-sleutelhanger", action: onBackupKey)
                    divider
                    actionRow("Ruwe data exporteren", systemImage: "square.and.arrow.up", color: OHTheme.ink,
                              hint: "Maakt een kopie van alle ringgegevens op deze iPhone, zonder sleutel", action: onExportRawData)
                    divider
                    actionRow("Ring wissen", systemImage: "trash", color: OHTheme.danger,
                              hint: "Vraagt eerst om bevestiging") {
                        isConfirmingWipe = true
                    }
                }
                .padding(.horizontal, OHSpace.l)
                .background(OHTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                Label("Geen account, geen cloud, geen abonnement", systemImage: "checkmark.shield")
                    .font(.footnote)
                    .foregroundStyle(OHTheme.muted)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, OHSpace.page)
            .padding(.bottom, OHSpace.xxl)
        }
        .scrollIndicators(.hidden)
        .background(OHAtmosphere(mood: .plain).ignoresSafeArea())
        .confirmationDialog("Ring wissen?", isPresented: $isConfirmingWipe, titleVisibility: .visible) {
            Button("Ring wissen", role: .destructive) {
                Task { await onWipe() }
            }
            Button("Annuleren", role: .cancel) {}
        } message: {
            Text("De koppelsleutel, alle verbindingen en de metingen die nog alleen op de ring staan worden gewist. Synchroniseer eerst. Dit kun je niet ongedaan maken.")
        }
        .sensoryFeedback(.success, trigger: completedSyncs)
        .sensoryFeedback(.warning, trigger: isConfirmingWipe) { _, isShowing in isShowing }
    }

    private var divider: some View {
        Divider().overlay(OHTheme.hairline)
    }

    private func actionRow(
        _ title: String,
        systemImage: String,
        color: Color,
        hint: String,
        showsProgress: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: OHSpace.m) {
                Label(title, systemImage: systemImage)
                    .foregroundStyle(color)
                Spacer(minLength: OHSpace.s)
                if showsProgress {
                    ProgressView().tint(OHTheme.ink)
                }
            }
            .font(.body)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(hint)
    }

    private func sync() async {
        withAnimation(.snappy(duration: 0.25)) { isSyncing = true }
        let succeeded = await onSync()
        withAnimation(.snappy(duration: 0.25)) { isSyncing = false }
        if succeeded { completedSyncs += 1 }
    }
}

/// The drawn ring inside a battery gauge, with the status underneath.
private struct OHBatteryCard: View {
    let ring: OHRingState

    @ScaledMetric(relativeTo: .title) private var gaugeSize: CGFloat = 200
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shownFraction: Double = 0

    private var fraction: Double { Double(min(max(ring.batteryPercent, 0), 100)) / 100 }

    private var stateLine: String {
        guard ring.isConnected else { return "Niet verbonden" }
        return ring.isCharging ? "Gekoppeld · laadt op" : "Gekoppeld · aan het meten"
    }

    var body: some View {
        VStack(spacing: OHSpace.xs) {
            ZStack {
                Circle().stroke(Color(ohHex: 0x2E2E34), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: shownFraction)
                    .stroke(ring.batteryPercent <= 15 ? OHTheme.amber : OHTheme.ink,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                OHRingIllustration()
                    .padding(gaugeSize * 0.18)
            }
            .frame(width: min(gaugeSize, 260), height: min(gaugeSize, 260))
            .padding(.bottom, OHSpace.m)

            Text("Batterij \(OHFormat.percent(fraction))")
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(OHTheme.ink)
            Text(stateLine)
                .font(.subheadline)
                .foregroundStyle(OHTheme.inkSoft)
            if let lastSync = ring.lastSync {
                Text("\(ring.modelName) · laatste synchronisatie \(lastSync, format: .dateTime.hour().minute())")
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(OHTheme.muted)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(OHSpace.xl)
        .background(OHTheme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .accessibilityElement(children: .combine)
        .onAppear { animate(to: fraction) }
        .onChange(of: fraction) { _, newValue in animate(to: newValue) }
    }

    private func animate(to value: Double) {
        if reduceMotion {
            shownFraction = value
        } else {
            withAnimation(.easeOut(duration: 0.5)) { shownFraction = value }
        }
    }
}

/// A simple drawn ring: dark outside, metal inside, two sensor dots.
private struct OHRingIllustration: View {
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            ZStack {
                Ellipse().fill(Color(ohHex: 0x0E0E11))
                    .frame(width: w, height: w * 0.65)
                    .offset(y: w * 0.06)
                Ellipse().fill(Color(ohHex: 0x1D1D22))
                    .overlay(Ellipse().strokeBorder(Color(ohHex: 0x3B3B42), lineWidth: 1.5))
                    .frame(width: w, height: w * 0.65)
                Ellipse().fill(Color(ohHex: 0x2B2B32))
                    .frame(width: w * 0.76, height: w * 0.46)
                    .offset(y: w * 0.03)
                Ellipse().strokeBorder(Color(ohHex: 0x9A9AA2).opacity(0.6), lineWidth: 2)
                    .frame(width: w * 0.76, height: w * 0.43)
                    .offset(y: w * 0.06)
                HStack(spacing: w * 0.28) {
                    sensor(w)
                    sensor(w)
                }
                .offset(y: w * 0.22)
            }
            .frame(width: w, height: geometry.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func sensor(_ w: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 1.5, style: .continuous)
            .fill(OHTheme.teal)
            .frame(width: w * 0.06, height: w * 0.035)
    }
}

#Preview {
    OHRingView(ring: OHSample.ring, onSync: {
        try? await Task.sleep(for: .seconds(1))
        return true
    })
    .preferredColorScheme(.dark)
}
