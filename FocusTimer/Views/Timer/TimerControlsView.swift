import SwiftUI

struct TimerControlsView: View {
    let state: TimerState
    let phase: TimerPhase
    let onStartPause: () -> Void
    let onSkip: () -> Void
    let onRevert: () -> Void

    private var accentColor: Color {
        phase == .work ? .ember : .sage
    }

    var body: some View {
        HStack(spacing: 40) {
            // Revert — small, understated
            Button(action: onRevert) {
                Image(systemName: "backward.end")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            // Play/pause — the focal point
            Button(action: onStartPause) {
                ZStack {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 44, height: 44)
                        .shadow(color: accentColor.opacity(0.3), radius: 12, x: 0, y: 4)

                    Image(systemName: playPauseIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.backgroundDark)
                        .offset(x: state == .running ? 0 : 1.5) // optical center for play icon
                }
            }
            .buttonStyle(.plain)

            // Skip — small, understated
            Button(action: onSkip) {
                Image(systemName: "forward.end")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
    }

    private var playPauseIcon: String {
        switch state {
        case .running: "pause.fill"
        case .idle, .paused, .finished: "play.fill"
        }
    }
}
