import SwiftUI

struct ThemeResolver: View {
    let id: ThemeIdentifier
    let progress: Double
    let phase: TimerPhase
    let state: TimerState

    var body: some View {
        switch id {
        case .particle:
            ParticleThemeView(progress: progress, phase: phase, state: state)
        }
    }
}
