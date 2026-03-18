import SwiftUI

struct CountdownLabel: View {
    let remainingSeconds: TimeInterval
    let phase: TimerPhase
    let state: TimerState

    var body: some View {
        Text(TimeFormatting.formatted(remainingSeconds))
            .font(.system(size: Constants.countdownFontSize, weight: .thin, design: .monospaced))
            .foregroundStyle(.white)
            .contentTransition(.numericText())
            .opacity(state == .paused ? 0.4 : 1.0)
            .animation(.easeInOut(duration: 0.6), value: state == .paused)
    }
}
