import SwiftUI

struct CountdownLabel: View {
    let remainingSeconds: TimeInterval
    let phase: TimerPhase
    let state: TimerState

    var body: some View {
        VStack(spacing: 2) {
            Text(TimeFormatting.formatted(remainingSeconds))
                .font(.system(size: Constants.countdownFontSize, weight: .ultraLight, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
                .contentTransition(.numericText())
                .opacity(state == .paused ? 0.5 : 1.0)
                .animation(.easeInOut(duration: 0.6), value: state == .paused)
        }
    }
}
