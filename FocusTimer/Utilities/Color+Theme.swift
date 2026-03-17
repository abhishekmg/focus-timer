import SwiftUI

extension Color {
    // Near-black with a warm brown undertone — not pure black, not blue-black
    static let backgroundDark = Color(red: 0.067, green: 0.063, blue: 0.059)   // warm charcoal
    static let surfaceDark = Color(red: 0.098, green: 0.090, blue: 0.082)      // elevated surface

    // Ember palette — warm coral that feels like glowing coals
    static let ember = Color(red: 0.96, green: 0.38, blue: 0.28)              // #F56147
    static let emberGlow = Color(red: 1.0, green: 0.52, blue: 0.32)           // #FF8552
    static let emberDim = Color(red: 0.76, green: 0.28, blue: 0.20)           // softer state

    // Rest palette — sage, not neon green
    static let sage = Color(red: 0.56, green: 0.78, blue: 0.63)               // #8FC7A1
    static let sageDim = Color(red: 0.40, green: 0.60, blue: 0.46)

    // Text hierarchy
    static let textPrimary = Color(red: 0.93, green: 0.91, blue: 0.88)        // warm white
    static let textSecondary = Color(red: 0.58, green: 0.54, blue: 0.50)      // warm gray
    static let textTertiary = Color(red: 0.38, green: 0.35, blue: 0.32)       // subtle

    // Ring
    static let ringTrack = Color.white.opacity(0.04)

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
