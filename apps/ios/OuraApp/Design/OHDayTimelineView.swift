import SwiftUI

/// "Tijdlijn": the week strip and, per day, the scores and what happened.
/// Named OHDayTimelineView so it never clashes with SwiftUI's own TimelineView.
struct OHDayTimelineView: View {
    let week: [OHWeekDay]
    let days: [OHTimelineDay]
    var onPickDate: () -> Void = {}
    var onSelectDay: (OHWeekDay) -> Void = { _ in }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OHSpace.xl) {
                header
                weekStrip
                ForEach(days) { day in
                    daySection(day)
                }
            }
            .padding(.horizontal, OHSpace.page)
            .padding(.bottom, OHSpace.xxl)
        }
        .scrollIndicators(.hidden)
        .background(OHAtmosphere(mood: .plain).ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Text("Tijdlijn")
                .font(.ohSerif(.largeTitle))
                .foregroundStyle(OHTheme.ink)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: OHSpace.s)
            Button(action: onPickDate) {
                Image(systemName: "calendar")
            }
            .buttonStyle(OHGlassCircleButtonStyle())
            .accessibilityLabel("Kies een datum")
        }
        .padding(.top, OHSpace.s)
    }

    private var weekStrip: some View {
        HStack(spacing: 0) {
            ForEach(week) { day in
                Button {
                    onSelectDay(day)
                } label: {
                    WeekDayCell(day: day)
                }
                .buttonStyle(.plain)
                .disabled(day.isFuture)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func daySection(_ day: OHTimelineDay) -> some View {
        VStack(alignment: .leading, spacing: OHSpace.l) {
            VStack(alignment: .leading, spacing: OHSpace.xs) {
                Text(day.title)
                    .font(.ohSerif(.title))
                    .foregroundStyle(OHTheme.ink)
                    .accessibilityAddTraits(.isHeader)
                HStack(spacing: OHSpace.l) {
                    scoreChip(day.recovery, "herstel", OHTheme.amber)
                    scoreChip(day.sleep, "slaap", OHTheme.teal)
                    scoreChip(day.activity, "activiteit", OHTheme.inkSoft)
                }
            }
            VStack(spacing: 0) {
                ForEach(Array(day.events.enumerated()), id: \.element.id) { index, event in
                    OHTimelineRow(event: event, isLast: index == day.events.count - 1)
                }
            }
        }
    }

    @ViewBuilder
    private func scoreChip(_ value: Int?, _ label: String, _ color: Color) -> some View {
        if let value {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text("\(value)").monospacedDigit().foregroundStyle(OHTheme.ink)
                Text(label).foregroundStyle(OHTheme.muted)
            }
            .font(.subheadline)
            .accessibilityElement(children: .combine)
        }
    }
}

private struct WeekDayCell: View {
    let day: OHWeekDay

    @ScaledMetric(relativeTo: .subheadline) private var diameter: CGFloat = 40

    var body: some View {
        VStack(spacing: OHSpace.s) {
            Text(day.date, format: .dateTime.weekday(.narrow))
                .font(.caption)
                .foregroundStyle(OHTheme.muted)
            ZStack {
                if day.isToday {
                    Circle().fill(Color.white.opacity(0.14))
                }
                if let recovery = day.recovery {
                    Circle().stroke(Color.white.opacity(0.12), lineWidth: 2)
                    Circle()
                        .trim(from: 0, to: Double(recovery) / 100)
                        .stroke(OHTheme.amber, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                Text(day.date, format: .dateTime.day())
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(day.isFuture ? Color(ohHex: 0x5E5B58) : (day.recovery == nil ? OHTheme.muted : OHTheme.ink))
            }
            .frame(width: diameter, height: diameter)
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(day.isToday ? .isSelected : [])
    }

    private var accessibilityText: String {
        let date = day.date.formatted(.dateTime.weekday(.wide).day().month(.wide))
        if let recovery = day.recovery { return "\(date), herstel \(recovery)" }
        return date
    }
}

#Preview {
    OHDayTimelineView(week: OHSample.week, days: OHSample.days)
        .preferredColorScheme(.dark)
}
