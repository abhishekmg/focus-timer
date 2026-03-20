import SwiftUI

struct TimerControlsView: View {
    let state: TimerState
    let phase: TimerPhase
    let onStartPause: () -> Void
    let onSkip: () -> Void
    let onRevert: () -> Void

    @State private var playHover = false

    var body: some View {
        Button(action: onStartPause) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 48, height: 48)

                Image(systemName: playPauseIcon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .offset(x: state == .running ? 0 : 1.5)
            }
            .contentShape(Circle())
            .scaleEffect(playHover ? 1.06 : 1.0)
            .animation(.easeOut(duration: 0.15), value: playHover)
        }
        .buttonStyle(.plain)
        #if os(macOS)
        .onHover { playHover = $0 }
        #endif
    }

    private var playPauseIcon: String {
        switch state {
        case .running: "pause.fill"
        case .idle, .paused, .finished: "play.fill"
        }
    }
}
