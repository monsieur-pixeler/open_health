import SwiftUI

/// The four tabs of the new design. On iOS 26 the system draws the tab bar as a
/// floating glass pill by itself; on iOS 17 and 18 it is the standard tab bar.
struct OHAppShell: View {
    enum Tab: Hashable { case today, timeline, sleep, ring }

    let today: OHToday
    let week: [OHWeekDay]
    let days: [OHTimelineDay]
    let ring: OHRingState

    @State private var selection: Tab = .today

    var body: some View {
        TabView(selection: $selection) {
            OHTodayView(today: today, onOpenSleep: { selection = .sleep })
                .tabItem { Label("Vandaag", systemImage: "sun.max") }
                .tag(Tab.today)

            OHDayTimelineView(week: week, days: days)
                .tabItem { Label("Tijdlijn", systemImage: "list.bullet") }
                .tag(Tab.timeline)

            OHSleepView(night: today.night)
                .tabItem { Label("Slaap", systemImage: "moon") }
                .tag(Tab.sleep)

            OHRingView(ring: ring)
                .tabItem { Label("Ring", systemImage: "circle.circle") }
                .tag(Tab.ring)
        }
        .tint(OHTheme.ink)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    OHAppShell(today: OHSample.today, week: OHSample.week, days: OHSample.days, ring: OHSample.ring)
}
