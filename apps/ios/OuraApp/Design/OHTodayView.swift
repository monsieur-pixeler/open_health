import SwiftUI

/// "Vandaag": score rings, the recovery hero, last night and the vitals.
struct OHTodayView: View {
    let today: OHToday
    var onSync: () async -> Void = {}
    var onExplainRecovery: () -> Void = {}
    var onOpenSleep: () -> Void = {}

    @State private var isSyncing = false
    @State private var completedSyncs = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OHSpace.xl) {
                header
                scoreRings
                OHHero(
                    label: "Herstel",
                    score: today.recovery,
                    headline: today.headline,
                    message: today.message,
                    actionTitle: "Wat speelt mee",
                    action: onExplainRecovery
                )
                nightCard
                vitals
            }
            .padding(.horizontal, OHSpace.page)
            .padding(.bottom, OHSpace.xxl)
        }
        .scrollIndicators(.hidden)
        .background(OHAtmosphere(mood: .dawn).ignoresSafeArea())
        .sensoryFeedback(.success, trigger: completedSyncs)
    }

    private var header: some View {
        HStack {
            Text(today.date, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(OHTheme.inkSoft)
            Spacer(minLength: OHSpace.s)
            Button {
                Task { await sync() }
            } label: {
                if isSyncing {
                    ProgressView().tint(OHTheme.ink)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
            }
            .buttonStyle(OHGlassCircleButtonStyle())
            .disabled(isSyncing)
            .accessibilityLabel(isSyncing ? "Bezig met synchroniseren" : "Synchroniseer met ring")
            .accessibilityHint("Haalt de nieuwe metingen van je ring op")
        }
        .padding(.top, OHSpace.s)
    }

    private var scoreRings: some View {
        ScrollView(.horizontal) {
            HStack(spacing: OHSpace.l) {
                OHScoreRing(value: "\(today.recovery.value)", label: "Herstel",
                            fraction: today.recovery.fraction, tint: today.recovery.tone.color)
                OHScoreRing(value: "\(today.sleep.value)", label: "Slaap",
                            fraction: today.sleep.fraction, tint: today.sleep.tone.color)
                OHScoreRing(value: "\(today.activity.value)", label: "Activiteit",
                            fraction: today.activity.fraction, tint: OHTheme.inkSoft)
                OHScoreRing(value: "\(today.hrv)", label: "HRV",
                            fraction: today.hrvRatio, tint: today.hrvRatio < 1 ? OHTheme.amber : OHTheme.teal)
                OHScoreRing(value: "\(today.restingHeartRate)", label: "Hartslag",
                            fraction: 1, tint: Color.white.opacity(0.45))
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, OHSpace.page, for: .scrollContent)
        .padding(.horizontal, -OHSpace.page)
    }

    private var nightCard: some View {
        Button(action: onOpenSleep) {
            VStack(alignment: .leading, spacing: OHSpace.m) {
                HStack {
                    Text("Afgelopen nacht").font(.headline).foregroundStyle(OHTheme.ink)
                    Spacer(minLength: OHSpace.s)
                    Text(OHFormat.duration(today.night.asleep))
                        .monospacedDigit()
                        .foregroundStyle(OHTheme.muted)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(OHTheme.muted)
                }
                OHHypnogram(segments: today.night.segments, style: .compact)
                    .frame(height: 40)
                HStack {
                    Text(today.night.bedtime, format: .dateTime.hour().minute())
                    Spacer()
                    Text("Efficiëntie \(OHFormat.percent(today.night.efficiency))")
                    Spacer()
                    Text(today.night.wake, format: .dateTime.hour().minute())
                }
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(OHTheme.muted)
            }
            .ohCard()
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opent de details van je slaap")
    }

    private var vitals: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: OHSpace.m), GridItem(.flexible())], spacing: OHSpace.m) {
            ForEach(today.vitals) { vital in
                VStack(alignment: .leading, spacing: OHSpace.xs) {
                    Text(vital.title).font(.footnote).foregroundStyle(OHTheme.muted)
                    HStack(alignment: .firstTextBaseline, spacing: OHSpace.xs) {
                        Text(vital.value).font(.title2.weight(.light)).monospacedDigit()
                        Text(vital.unit).font(.subheadline).foregroundStyle(OHTheme.muted)
                    }
                    .foregroundStyle(OHTheme.ink)
                    Text(vital.note).font(.footnote).foregroundStyle(vital.tone.color)
                }
                .ohCard(cornerRadius: 20)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func sync() async {
        withAnimation(.snappy(duration: 0.25)) { isSyncing = true }
        await onSync()
        withAnimation(.snappy(duration: 0.25)) { isSyncing = false }
        completedSyncs += 1
    }
}

#Preview {
    OHTodayView(today: OHSample.today, onSync: { try? await Task.sleep(for: .seconds(1)) })
        .preferredColorScheme(.dark)
}
