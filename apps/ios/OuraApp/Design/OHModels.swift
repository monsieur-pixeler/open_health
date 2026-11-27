import SwiftUI

// Plain view models for the new design. They hold only what the screens show,
// so the screens stay previewable. Mapping from `Summary` comes later.

enum OHTone {
    case good, attention, neutral

    var color: Color {
        switch self {
        case .good: OHTheme.teal
        case .attention: OHTheme.amber
        case .neutral: OHTheme.muted
        }
    }
}

struct OHScore {
    let value: Int
    let average: Int
    let tone: OHTone

    var fraction: Double { Double(min(max(value, 0), 100)) / 100 }
    var averageFraction: Double { Double(min(max(average, 0), 100)) / 100 }
}

enum OHSleepStage: CaseIterable, Hashable {
    case awake, rem, light, deep

    var title: String {
        switch self {
        case .awake: "Wakker"
        case .rem: "REM"
        case .light: "Licht"
        case .deep: "Diep"
        }
    }

    var color: Color {
        switch self {
        case .awake: Color(ohHex: 0xE8B86B)
        case .rem: Color(ohHex: 0xB79CF5)
        case .light: Color(ohHex: 0x9DB4F0)
        case .deep: Color(ohHex: 0x5B6FD6)
        }
    }

    /// Row in the hypnogram, top to bottom.
    var lane: Int {
        switch self {
        case .awake: 0
        case .rem: 1
        case .light: 2
        case .deep: 3
        }
    }

    /// Bar height in the compact hypnogram (deeper sleep, taller bar).
    var depth: CGFloat {
        switch self {
        case .awake: 0.32
        case .rem: 0.77
        case .light: 0.55
        case .deep: 1
        }
    }
}

/// One stretch of a stage, as fractions of the night (0...1).
struct OHStageSegment: Identifiable {
    let id = UUID()
    let start: Double
    let end: Double
    let stage: OHSleepStage
}

struct OHNight {
    let bedtime: Date
    let wake: Date
    let asleep: TimeInterval
    let efficiency: Double
    let latency: TimeInterval
    let segments: [OHStageSegment]
    let stageTotals: [OHSleepStage: TimeInterval]
    let lowestHeartRate: Int
    let averageHRV: Int
    let score: OHScore
    let headline: String
    let message: String
}

struct OHVital: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let unit: String
    let note: String
    let tone: OHTone
}

struct OHToday {
    let date: Date
    let recovery: OHScore
    let sleep: OHScore
    let activity: OHScore
    let hrv: Int
    /// HRV against the personal baseline, as a ratio (0.92 = 8% below).
    let hrvRatio: Double
    let restingHeartRate: Int
    let headline: String
    let message: String
    let night: OHNight
    let vitals: [OHVital]
}

struct OHTimelineEvent: Identifiable {
    enum Kind { case woke, fellAsleep, activity }

    let id = UUID()
    let kind: Kind
    let start: Date
    var end: Date? = nil
    let title: String
    let detail: String
    var tag: String? = nil

    var systemImage: String {
        switch kind {
        case .woke: "sunrise"
        case .fellAsleep: "moon"
        case .activity: "figure.walk"
        }
    }
}

struct OHTimelineDay: Identifiable {
    let id = UUID()
    let title: String
    let recovery: Int?
    let sleep: Int?
    let activity: Int?
    let events: [OHTimelineEvent]
}

struct OHWeekDay: Identifiable {
    let id = UUID()
    let date: Date
    let recovery: Int?
    let isToday: Bool
    let isFuture: Bool
}

struct OHRingState {
    let modelName: String
    let batteryPercent: Int
    let isCharging: Bool
    let isConnected: Bool
    let lastSync: Date?
}

// MARK: - Sample data for previews

enum OHSample {
    static func at(_ hour: Int, _ minute: Int, dayOffset: Int = 0) -> Date {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: .now))!
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
    }

    static let segments: [OHStageSegment] = {
        let raw: [(Double, Double, OHSleepStage)] = [
            (0.000, 0.023, .awake), (0.023, 0.121, .light), (0.121, 0.227, .deep),
            (0.227, 0.356, .light), (0.356, 0.432, .rem), (0.432, 0.545, .light),
            (0.545, 0.598, .deep), (0.598, 0.667, .light), (0.667, 0.686, .awake),
            (0.686, 0.754, .light), (0.754, 0.845, .rem), (0.845, 0.920, .light),
            (0.920, 0.973, .rem), (0.973, 1.000, .awake),
        ]
        return raw.map { OHStageSegment(start: $0.0, end: $0.1, stage: $0.2) }
    }()

    static let night = OHNight(
        bedtime: at(23, 4, dayOffset: -1),
        wake: at(7, 51),
        asleep: 8 * 3600 + 11 * 60,
        efficiency: 0.93,
        latency: 7 * 60,
        segments: segments,
        stageTotals: [.deep: 84 * 60, .light: 287 * 60, .rem: 120 * 60, .awake: 36 * 60],
        lowestHeartRate: 47,
        averageHRV: 84,
        score: OHScore(value: 81, average: 77, tone: .good),
        headline: "Je sliep goed door",
        message: "8u 11m geslapen bij 93% efficiëntie. De meeste diepe slaap viel voor 02:00."
    )

    static let today = OHToday(
        date: .now,
        recovery: OHScore(value: 68, average: 74, tone: .attention),
        sleep: OHScore(value: 81, average: 77, tone: .good),
        activity: OHScore(value: 54, average: 60, tone: .neutral),
        hrv: 84,
        hrvRatio: 0.92,
        restingHeartRate: 52,
        headline: "Rustig aan vandaag",
        message: "Je HRV ligt 8% onder je basis en je rusthartslag 2 slagen hoger. Je sliep wel lang genoeg.",
        night: night,
        vitals: [
            OHVital(title: "HRV in de nacht", value: "84", unit: "ms", note: "8% onder basis", tone: .attention),
            OHVital(title: "Rusthartslag", value: "52", unit: "bpm", note: "2 boven basis", tone: .attention),
            OHVital(title: "Huidtemperatuur", value: "+0,2", unit: "°C", note: "Binnen je bereik", tone: .neutral),
            OHVital(title: "Zuurstof (SpO₂)", value: "96", unit: "%", note: "Stabiel", tone: .good),
        ]
    )

    static let days: [OHTimelineDay] = [
        OHTimelineDay(
            title: "Vandaag", recovery: 68, sleep: 81, activity: 54,
            events: [
                OHTimelineEvent(kind: .woke, start: at(7, 51), title: "Wakker geworden", detail: "8u 11m geslapen · slaap 81"),
            ]
        ),
        OHTimelineDay(
            title: "Gisteren", recovery: 59, sleep: 63, activity: 96,
            events: [
                OHTimelineEvent(kind: .fellAsleep, start: at(23, 11, dayOffset: -1), title: "In slaap gevallen", detail: "Na 7 minuten"),
                OHTimelineEvent(kind: .activity, start: at(18, 20, dayOffset: -1), end: at(18, 38, dayOffset: -1),
                                title: "Wandeling", detail: "18 min · 92 kcal · gem. 118 bpm", tag: "Herkend uit bewegingsdata"),
            ]
        ),
    ]

    static let week: [OHWeekDay] = {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = (calendar.component(.weekday, from: today) + 5) % 7 // Monday = 0
        let monday = calendar.date(byAdding: .day, value: -weekday, to: today)!
        let recovery: [Int?] = [nil, nil, 15, 59, 68, nil, nil]
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: monday)!
            return OHWeekDay(
                date: date,
                recovery: date <= today ? recovery[offset] : nil,
                isToday: date == today,
                isFuture: date > today
            )
        }
    }()

    static let ring = OHRingState(
        modelName: "Ring 5",
        batteryPercent: 86,
        isCharging: false,
        isConnected: true,
        lastSync: at(7, 58)
    )
}
