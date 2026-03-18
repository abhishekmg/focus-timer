import SwiftUI

struct CircularProgressRing: View {
    let progress: Double
    let phase: TimerPhase
    let state: TimerState

    @State private var breathe = false

    private var accentColor: Color {
        phase == .work ? .ember : .sage
    }

    private var glowColor: Color {
        phase == .work ? .emberGlow : .sage
    }

    var body: some View {
        ZStack {
            // Ambient glow — breathes when idle, steady when running
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accentColor.opacity(state == .running ? 0.12 : 0.06), .clear],
                        center: .center,
                        startRadius: Constants.ringSize * 0.3,
                        endRadius: Constants.ringSize * 0.7
                    )
                )
                .frame(width: Constants.ringSize + 60, height: Constants.ringSize + 60)
                .scaleEffect(breathe ? 1.08 : 1.0)
                .animation(
                    state == .idle || state == .paused
                        ? .easeInOut(duration: 3.0).repeatForever(autoreverses: true)
                        : .easeInOut(duration: 0.6),
                    value: breathe
                )

            // Tick marks — watch-face inspired
            ForEach(0..<Constants.ringTickCount, id: \.self) { i in
                let isMajor = i % 5 == 0
                Rectangle()
                    .fill(Color.ringTickMark.opacity(isMajor ? 1.0 : 0.5))
                    .frame(width: isMajor ? 1.5 : 0.75, height: isMajor ? 8 : 5)
                    .offset(y: -(Constants.ringSize / 2 + 12))
                    .rotationEffect(.degrees(Double(i) * (360.0 / Double(Constants.ringTickCount))))
            }

            // Track ring — subtle with inner depth
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

            // Glow trail behind progress
            if progress > 0.01 {
                Circle()
                    .trim(from: max(0, CGFloat(progress) - 0.08), to: CGFloat(min(progress, 1.0)))
                    .stroke(
                        glowColor.opacity(0.4),
                        style: StrokeStyle(
                            lineWidth: Constants.ringStrokeWidth + 6,
                            lineCap: .round
                        )
                    )
                    .blur(radius: 6)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: progress)
            }

            // Endpoint dot with glow
            if progress > 0.01 && progress < 0.99 {
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(glowColor.opacity(0.5))
                        .frame(width: 16, height: 16)
                        .blur(radius: 6)

                    // Core dot
                    Circle()
                        .fill(accentColor)
                        .frame(width: 10, height: 10)

                    // Bright center
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 4, height: 4)
                }
                .offset(y: -Constants.ringSize / 2)
                .rotationEffect(.degrees(360 * progress - 90))
                .animation(.easeInOut(duration: 0.8), value: progress)
            }
        }
        .frame(width: Constants.ringSize, height: Constants.ringSize)
        .onAppear { breathe = true }
        .onChange(of: state) { _, _ in
            breathe = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { breathe = true }
        }
    }
}
