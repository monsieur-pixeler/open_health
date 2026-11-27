import SwiftUI

/// "Slaap": the night score, the hypnogram and time per stage.
struct OHSleepView: View {
    let night: OHNight
    var onPickNight: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OHSpace.xl) {
                header
                OHHero(label: "Slaap", score: night.score, headline: night.headline, message: night.message)
                hypnogramCard
                stagesCard
                detailsCard
            }
            .padding(.horizontal, OHSpace.page)
            .padding(.bottom, OHSpace.xxl)
        }
        .scrollIndicators(.hidden)
        .background(OHAtmosphere(mood: .night).ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Text("Nacht tot \(night.wake, format: .dateTime.weekday(.wide).day().month(.wide))")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(OHTheme.inkSoft)
            Spacer(minLength: OHSpace.s)
            Button(action: onPickNight) {
                Image(systemName: "calendar")
            }
            .buttonStyle(OHGlassCircleButtonStyle())
            .accessibilityLabel("Kies een nacht")
        }
        .padding(.top, OHSpace.s)
    }

    private var hypnogramCard: some View {
        VStack(alignment: .leading, spacing: OHSpace.m) {
            HStack(alignment: .firstTextBaseline) {
                Text("Slaapfasen").font(.headline).foregroundStyle(OHTheme.ink)
                Spacer(minLength: OHSpace.s)
                Text("Op je iPhone berekend").font(.footnote).foregroundStyle(OHTheme.muted)
            }
            HStack(spacing: OHSpace.s) {
                VStack(alignment: .leading) {
                    ForEach([OHSleepStage.awake, .rem, .light, .deep], id: \.self) { stage in
                        Text(stage.title)
                            .frame(maxHeight: .infinity)
                    }
                }
                .font(.caption)
                .foregroundStyle(OHTheme.muted)
                .accessibilityHidden(true)

                OHHypnogram(segments: night.segments, style: .lanes)
            }
            .frame(height: 104)
            HStack {
                Text(night.bedtime, format: .dateTime.hour().minute())
                Spacer()
                Text(night.wake, format: .dateTime.hour().minute())
            }
            .font(.caption)
            .monospacedDigit()
            .foregroundStyle(OHTheme.muted)
        }
        .ohCard()
    }

    private var stagesCard: some View {
        VStack(alignment: .leading, spacing: OHSpace.l) {
            OHStageBar(totals: night.stageTotals)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: OHSpace.xl), GridItem(.flexible())], spacing: OHSpace.m) {
                ForEach([OHSleepStage.deep, .light, .rem, .awake], id: \.self) { stage in
                    OHStageRow(stage: stage, duration: night.stageTotals[stage] ?? 0)
                }
            }
        }
        .ohCard()
    }

    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow("Inslaaptijd", OHFormat.duration(night.latency))
            Divider().overlay(OHTheme.hairline)
            detailRow("Laagste hartslag", "\(night.lowestHeartRate) bpm")
            Divider().overlay(OHTheme.hairline)
            detailRow("Gemiddelde HRV", "\(night.averageHRV) ms")
        }
        .ohCard(padding: 0)
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(OHTheme.ink)
            Spacer(minLength: OHSpace.s)
            Text(value).monospacedDigit().foregroundStyle(OHTheme.muted)
        }
        .font(.body)
        .padding(.horizontal, OHSpace.l)
        .frame(minHeight: 48)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    OHSleepView(night: OHSample.night)
        .preferredColorScheme(.dark)
}
