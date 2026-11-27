import SwiftUI

// Design tokens for the "sfeervolle richting" (atmospheric dark design).
// Everything here is prefixed `OH` so it never clashes with the existing Theme.swift.

enum OHTheme {
    static let ink = Color(ohHex: 0xF3EEE8)       // primary text
    static let inkSoft = Color(ohHex: 0xE8E1DA)   // text on the atmospheric backgrounds
    static let muted = Color(ohHex: 0xA7A3A0)     // secondary text, 7:1 on `ground`
    static let ground = Color(ohHex: 0x141416)    // page background
    static let surface = Color(ohHex: 0x1F1F24)   // cards
    static let node = Color(ohHex: 0x26262C)      // timeline nodes
    static let nodeBorder = Color(ohHex: 0x34343B)
    static let connector = Color(ohHex: 0x2A2A30)
    static let hairline = Color.white.opacity(0.08)
    static let track = Color.white.opacity(0.20)

    static let amber = Color(ohHex: 0xE8B86B)     // "let op"
    static let teal = Color(ohHex: 0x7FD1C0)      // "goed"
    static let danger = Color(ohHex: 0xFF7A6B)    // destructive actions
}

enum OHSpace {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    /// Horizontal page margin.
    static let page: CGFloat = 20
}

extension Color {
    init(ohHex hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

extension Font {
    /// The display serif (Apple's New York), scaled with Dynamic Type.
    static func ohSerif(_ style: Font.TextStyle) -> Font {
        .system(style, design: .serif)
    }
}

// MARK: - Backgrounds

/// The painted sky behind a screen. Drawn, not a photo.
struct OHAtmosphere: View {
    enum Mood { case dawn, night, plain }
    let mood: Mood

    var body: some View {
        switch mood {
        case .dawn:
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: Color(ohHex: 0x1A2140), location: 0),
                        .init(color: Color(ohHex: 0x2F2E4E), location: 0.28),
                        .init(color: Color(ohHex: 0x463A4C), location: 0.44),
                        .init(color: Color(ohHex: 0x1C1B21), location: 0.64),
                        .init(color: OHTheme.ground, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                RadialGradient(
                    colors: [Color(ohHex: 0xCE8E68, opacity: 0.5), .clear],
                    center: UnitPoint(x: 0.72, y: 0.36),
                    startRadius: 0,
                    endRadius: 320
                )
            }
        case .night:
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: Color(ohHex: 0x111834), location: 0),
                        .init(color: Color(ohHex: 0x1F2548), location: 0.30),
                        .init(color: Color(ohHex: 0x1B1D2C), location: 0.56),
                        .init(color: OHTheme.ground, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                RadialGradient(
                    colors: [Color(ohHex: 0x6070C4, opacity: 0.35), .clear],
                    center: UnitPoint(x: 0.25, y: 0.30),
                    startRadius: 0,
                    endRadius: 300
                )
            }
        case .plain:
            LinearGradient(
                stops: [
                    .init(color: Color(ohHex: 0x1E2030), location: 0),
                    .init(color: OHTheme.ground, location: 0.28),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - Surfaces and buttons

struct OHCard: ViewModifier {
    var padding: CGFloat = OHSpace.l
    var cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                OHTheme.surface.opacity(0.92),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(OHTheme.hairline)
            )
    }
}

extension View {
    func ohCard(padding: CGFloat = OHSpace.l, cornerRadius: CGFloat = 24) -> some View {
        modifier(OHCard(padding: padding, cornerRadius: cornerRadius))
    }
}

/// Round 44 pt glass button for icon-only actions in the header.
struct OHGlassCircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(OHTheme.ink)
            .frame(width: 44, height: 44)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(Color.white.opacity(0.22)))
            .environment(\.colorScheme, .dark)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

/// Pill-shaped glass button for a secondary call to action.
struct OHGlassCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(OHTheme.ink)
            .padding(.horizontal, OHSpace.l + OHSpace.xs)
            .frame(minHeight: 44)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.22)))
            .environment(\.colorScheme, .dark)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Formatting

enum OHFormat {
    /// "8u 11m", "36m".
    static func duration(_ interval: TimeInterval) -> String {
        let totalMinutes = Int((interval / 60).rounded())
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours == 0 { return "\(minutes)m" }
        return "\(hours)u \(String(format: "%02d", minutes))m"
    }

    static func percent(_ fraction: Double) -> String {
        fraction.formatted(.percent.precision(.fractionLength(0)))
    }
}
