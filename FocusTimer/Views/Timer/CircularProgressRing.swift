import SwiftUI

struct CircularProgressRing: View {
    let progress: Double
    let phase: TimerPhase
    let state: TimerState

    private var accentColor: Color {
        phase == .work ? .ember : .sage
    }

    var body: some View {
        ZStack {
            // Outer subtle glow when running
            if state == .running {
                Circle()
                    .stroke(accentColor.opacity(0.08), lineWidth: 40)
                    .frame(width: Constants.ringSize + 20, height: Constants.ringSize + 20)
                    .blur(radius: 20)
            }

            // Track — barely visible
            Circle()
                .stroke(Color.ringTrack, lineWidth: Constants.ringStrokeWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    phase == .work ? Color.workGradient : Color.breakGradient,
                    style: StrokeStyle(
                        lineWidth: Constants.ringStrokeWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: progress)

            // Endpoint dot
            if progress > 0.01 && progress < 0.99 {
                Circle()
                    .fill(accentColor)
                    .frame(width: 9, height: 9)
                    .shadow(color: accentColor.opacity(0.6), radius: 6, x: 0, y: 0)
                    .offset(y: -Constants.ringSize / 2)
                    .rotationEffect(.degrees(360 * progress - 90))
                    .animation(.easeInOut(duration: 0.8), value: progress)
            }
        }
        .frame(width: Constants.ringSize, height: Constants.ringSize)
    }
}
