import SwiftUI

protocol TimerThemeView: View {
    init(progress: Double, phase: TimerPhase, state: TimerState)
}
