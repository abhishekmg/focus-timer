import SwiftUI

struct ParticleThemeView: TimerThemeView {
    let progress: Double
    let phase: TimerPhase
    let state: TimerState

    @State private var particleSystem = ParticleSystem(count: Constants.particleCount)
    @State private var frozenTime: Double?

    init(progress: Double, phase: TimerPhase, state: TimerState) {
        self.progress = progress
        self.phase = phase
        self.state = state
    }

    private var effectiveProgress: Double {
        switch state {
        case .idle: 0.15    // ghostly preview
        case .running, .paused: max(progress, 0.05)
        case .finished: 1.0
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: state == .paused)) { timeline in
            Canvas { context, size in
                let time = currentTime(from: timeline.date)
                let centerX = size.width / 2
                let centerY = size.height / 2
                let sphereRadius = Constants.sphereRadius

                // Rotation
                let rotationY = time * 0.15
                let wobbleX = sin(time * 0.08) * 0.12

                // Project all visible particles
                var projected: [ProjectedParticle] = []
                projected.reserveCapacity(Constants.particleCount)

                for particle in particleSystem.particles {
                    if let p = particleSystem.project(
                        particle: particle,
                        time: time,
                        progress: effectiveProgress,
                        sphereRadius: sphereRadius,
                        centerX: centerX,
                        centerY: centerY,
                        rotationY: rotationY,
                        wobbleX: wobbleX
                    ) {
                        projected.append(p)
                    }
                }

                // Sort back-to-front
                projected.sort { $0.z < $1.z }

                // Idle ghost effect
                let globalOpacity = state == .idle ? 0.25 : 1.0

                // Draw particles
                for p in projected {
                    let rect = CGRect(
                        x: p.x - p.size / 2,
                        y: p.y - p.size / 2,
                        width: p.size,
                        height: p.size
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(.white.opacity(p.opacity * globalOpacity))
                    )
                }
            }
        }
        .onChange(of: state) { oldValue, newValue in
            if newValue == .paused {
                frozenTime = Date().timeIntervalSinceReferenceDate
            } else if oldValue == .paused {
                frozenTime = nil
            }
        }
    }

    private func currentTime(from date: Date) -> Double {
        if let frozen = frozenTime {
            return frozen
        }
        return date.timeIntervalSinceReferenceDate
    }
}
