import SwiftUI

extension Color {
    // Pure black background for particle theme
    static let backgroundDark = Color.black
    static let surfaceDark = Color(white: 0.06)
    static let surfaceGlass = Color(white: 1.0, opacity: 0.035)

    // Text — pure white hierarchy
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.55)
    static let textTertiary = Color(white: 0.30)

    // Accent palettes — available for future use
    static let ember = Color(red: 0.96, green: 0.50, blue: 0.30)
    static let emberGlow = Color(red: 1.0, green: 0.60, blue: 0.35)
    static let emberDim = Color(red: 0.72, green: 0.32, blue: 0.18)
    static let emberMuted = Color(red: 0.96, green: 0.50, blue: 0.30).opacity(0.15)

    static let sage = Color(red: 0.42, green: 0.77, blue: 0.72)
    static let sageDim = Color(red: 0.30, green: 0.58, blue: 0.52)
    static let sageMuted = Color(red: 0.42, green: 0.77, blue: 0.72).opacity(0.15)

    // Ring
    static let ringTrack = Color.white.opacity(0.05)
    static let ringTickMark = Color.white.opacity(0.06)

    // Borders
    static let borderSubtle = Color.white.opacity(0.06)

    static var workGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [.ember, .emberGlow, .ember]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360)
        )
    }

    static var breakGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [.sage, .sageDim, .sage]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360)
        )
    }
}
