import SwiftUI

// Shared building blocks for the four screens.

/// A score inside a thin progress ring, with its label underneath.
struct OHScoreRing: View {
    let value: String
    let label: String
    let fraction: Double
    let tint: Color

    @ScaledMetric(relativeTo: .title3) private var diameter: CGFloat = 64

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(Color.black.opacity(0.25))
                Circle().stroke(OHTheme.track, lineWidth: 3)
                Circle()
                    .trim(from: 0, to: min(max(fraction, 0), 1))
                    .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(value)
                    .font(.title3)
                    .monospacedDigit()
                    .foregroundStyle(OHTheme.ink)
            }
            .frame(width: diameter, height: diameter)

            Text(label)
                .font(.caption)
                .foregroundStyle(OHTheme.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(minWidth: diameter + OHSpace.s)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) \(value)")
    }
}

/// Thin bar: where today sits, with a tick at the personal average.
struct OHBaselineBar: View {
    let fraction: Double
    let average: Double
    let tint: Color

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(OHTheme.track).frame(height: 2)
                Capsule().fill(tint).frame(width: width * clamp(fraction), height: 2)
                Capsule()
                    .fill(OHTheme.ink)
                    .frame(width: 2, height: 12)
                    .offset(x: width * clamp(average) - 1)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(height: 16)
        .accessibilityHidden(true)
    }

    private func clamp(_ value: Double) -> CGFloat {
        CGFloat(min(max(value, 0), 1))
    }
}

/// The big number, the serif headline and the one-line explanation.
struct OHHero: View {
    let label: String
    let score: OHScore
    let headline: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    @ScaledMetric(relativeTo: .largeTitle) private var numberSize: CGFloat = 88

    var body: some View {
        VStack(alignment: .leading, spacing: OHSpace.s) {
            HStack {
                Text(label.uppercased())
                    .font(.footnote.weight(.medium))
                    .tracking(1.6)
                Spacer(minLength: OHSpace.s)
                Text("Gemiddeld \(score.average)")
                    .font(.footnote)
                    .monospacedDigit()
            }
            .foregroundStyle(OHTheme.inkSoft)

            Text("\(score.value)")
                .font(.system(size: numberSize, weight: .light))
                .monospacedDigit()
                .foregroundStyle(OHTheme.ink)
                .accessibilityLabel("\(label) \(score.value), gemiddeld \(score.average)")

            OHBaselineBar(fraction: score.fraction, average: score.averageFraction, tint: score.tone.color)

            Text(headline)
                .font(.ohSerif(.largeTitle))
                .foregroundStyle(OHTheme.ink)
                .padding(.top, OHSpace.s)
                .accessibilityAddTraits(.isHeader)

            Text(message)
                .font(.body)
                .foregroundStyle(OHTheme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: OHSpace.xs) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                    }
                }
                .buttonStyle(OHGlassCapsuleButtonStyle())
                .padding(.top, OHSpace.s)
            }
        }
    }
}

/// Sleep stages across the night. `.lanes` puts each stage on its own row,
/// `.compact` draws taller bars for deeper sleep.
struct OHHypnogram: View {
    enum Style { case lanes, compact }

    let segments: [OHStageSegment]
    var style: Style = .lanes

    var body: some View {
        Canvas { context, size in
            if style == .lanes {
                for lane in 0..<4 {
                    let y = laneCenter(lane, in: size)
                    var line = Path()
                    line.move(to: CGPoint(x: 0, y: y))
                    line.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(line, with: .color(OHTheme.hairline), lineWidth: 1)
                }
            }
            for segment in segments {
                let x = CGFloat(segment.start) * size.width
                let width = max(CGFloat(segment.end - segment.start) * size.width - 1, 1)
                let rect: CGRect
                switch style {
                case .lanes:
                    let barHeight = min(12, size.height / 6)
                    rect = CGRect(
                        x: x,
                        y: laneCenter(segment.stage.lane, in: size) - barHeight / 2,
                        width: width,
                        height: barHeight
                    )
                case .compact:
                    let height = size.height * segment.stage.depth
                    rect = CGRect(x: x, y: size.height - height, width: width, height: height)
                }
                context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(segment.stage.color))
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Slaapfasen van de nacht")
    }

    private func laneCenter(_ lane: Int, in size: CGSize) -> CGFloat {
        size.height * (CGFloat(lane) + 0.5) / 4
    }
}

/// Colored dot, stage name, time.
struct OHStageRow: View {
    let stage: OHSleepStage
    let duration: TimeInterval

    var body: some View {
        HStack(spacing: OHSpace.s) {
            Circle().fill(stage.color).frame(width: 10, height: 10)
            Text(stage.title).foregroundStyle(OHTheme.muted)
            Spacer(minLength: OHSpace.s)
            Text(OHFormat.duration(duration)).monospacedDigit().foregroundStyle(OHTheme.ink)
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }
}

/// Proportional bar of the four stages.
struct OHStageBar: View {
    let totals: [OHSleepStage: TimeInterval]

    private var order: [OHSleepStage] { [.deep, .light, .rem, .awake] }
    private var sum: TimeInterval { max(order.reduce(0) { $0 + (totals[$1] ?? 0) }, 1) }

    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 2
            let available = geometry.size.width - spacing * CGFloat(order.count - 1)
            HStack(spacing: spacing) {
                ForEach(order, id: \.self) { stage in
                    Rectangle()
                        .fill(stage.color)
                        .frame(width: available * CGFloat((totals[stage] ?? 0) / sum))
                }
            }
        }
        .frame(height: 8)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }
}

/// One event on the day timeline: round node, time, card.
struct OHTimelineRow: View {
    let event: OHTimelineEvent
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: OHSpace.l) {
            VStack(spacing: 0) {
                Image(systemName: event.systemImage)
                    .font(.body)
                    .foregroundStyle(OHTheme.inkSoft)
                    .frame(width: 40, height: 40)
                    .background(OHTheme.node, in: Circle())
                    .overlay(Circle().strokeBorder(OHTheme.nodeBorder))
                if !isLast {
                    Rectangle()
                        .fill(OHTheme.connector)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: OHSpace.s) {
                timeText
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(OHTheme.muted)
                    .frame(minHeight: 40, alignment: .center)

                VStack(alignment: .leading, spacing: OHSpace.xs) {
                    Text(event.title).font(.headline).foregroundStyle(OHTheme.ink)
                    Text(event.detail).font(.subheadline).foregroundStyle(OHTheme.muted)
                    if let tag = event.tag {
                        Text(tag)
                            .font(.caption)
                            .foregroundStyle(OHTheme.inkSoft)
                            .padding(.horizontal, OHSpace.s)
                            .padding(.vertical, OHSpace.xs)
                            .background(Color(ohHex: 0x2C2C33), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .padding(.top, OHSpace.s)
                    }
                }
                .ohCard(cornerRadius: 20)
                .padding(.bottom, isLast ? 0 : OHSpace.l)
            }
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder private var timeText: some View {
        if let end = event.end {
            Text("\(event.start, format: .dateTime.hour().minute()) – \(end, format: .dateTime.hour().minute())")
        } else {
            Text(event.start, format: .dateTime.hour().minute())
        }
    }
}
