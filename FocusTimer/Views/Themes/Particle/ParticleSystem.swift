import Foundation

struct Particle {
    let theta: Double        // polar angle
    let phi: Double          // azimuthal angle
    let radius: Double       // 0..1 normalized
    let revealThreshold: Double  // 0..1, when this particle appears
    let driftSpeed: Double
    let driftAmplitude: Double
    let baseOpacity: Double
    let size: Double
    let phaseOffset: Double  // for drift animation
}

struct ProjectedParticle {
    let x: Double
    let y: Double
    let z: Double        // for depth sorting
    let opacity: Double
    let size: Double
}

final class ParticleSystem: Sendable {
    let particles: [Particle]

    init(count: Int) {
        var result: [Particle] = []
        result.reserveCapacity(count)

        let goldenRatio = (1.0 + sqrt(5.0)) / 2.0
        let surfaceCount = Int(Double(count) * 0.85)

        for i in 0..<count {
            // Fibonacci sphere for uniform distribution
            let t = Double(i) / Double(count - 1)
            let theta = acos(1.0 - 2.0 * t)
            let phi = 2.0 * .pi * Double(i) / goldenRatio

            // 85% surface, 15% interior
            let radius: Double
            if i < surfaceCount {
                radius = Double.random(in: 0.88...1.0)
            } else {
                radius = Double.random(in: 0.3...0.87)
            }

            // Uniform spread across full progress range with core-outward bias
            let coreOutward = (1.0 - radius) * 0.3  // slight head start for inner particles
            let revealThreshold = coreOutward + Double.random(in: 0...1) * (1.0 - coreOutward)

            let particle = Particle(
                theta: theta,
                phi: phi,
                radius: radius,
                revealThreshold: revealThreshold,
                driftSpeed: Double.random(in: 0.3...1.2),
                driftAmplitude: Double.random(in: 0.002...0.008),
                baseOpacity: Double.random(in: 0.6...1.0),
                size: Double.random(in: 1.5...3.5),
                phaseOffset: Double.random(in: 0...(2.0 * .pi))
            )
            result.append(particle)
        }

        self.particles = result
    }

    func project(
        particle: Particle,
        time: Double,
        progress: Double,
        sphereRadius: Double,
        centerX: Double,
        centerY: Double,
        rotationY: Double,
        wobbleX: Double
    ) -> ProjectedParticle? {
        // Check visibility
        guard particle.revealThreshold <= progress else { return nil }

        // Drift animation
        let drift = sin(time * particle.driftSpeed + particle.phaseOffset) * particle.driftAmplitude
        let r = particle.radius + drift
        let scaledR = r * sphereRadius

        // Spherical to cartesian
        let sinTheta = sin(particle.theta)
        var x = scaledR * sinTheta * cos(particle.phi)
        var y = scaledR * cos(particle.theta)
        var z = scaledR * sinTheta * sin(particle.phi)

        // Y-axis rotation
        let cosRY = cos(rotationY)
        let sinRY = sin(rotationY)
        let rx = x * cosRY + z * sinRY
        let rz = -x * sinRY + z * cosRY
        x = rx
        z = rz

        // X-axis wobble
        let cosWX = cos(wobbleX)
        let sinWX = sin(wobbleX)
        let wy = y * cosWX - z * sinWX
        let wz = y * sinWX + z * cosWX
        y = wy
        z = wz

        // Perspective projection
        let perspectiveD = sphereRadius * 4.0
        let scale = perspectiveD / (perspectiveD + z)
        let projX = centerX + x * scale
        let projY = centerY + y * scale

        // Depth-based opacity and size
        let normalizedZ = (z + sphereRadius) / (2.0 * sphereRadius) // 0 = back, 1 = front
        let depthOpacity = 0.2 + normalizedZ * 0.8

        // Fade-in over 0.15 progress window (~15% of total duration)
        let fadeIn = min(1.0, (progress - particle.revealThreshold) / 0.15)

        let finalOpacity = particle.baseOpacity * depthOpacity * fadeIn
        let finalSize = particle.size * (0.5 + normalizedZ * 0.5) * scale

        return ProjectedParticle(
            x: projX,
            y: projY,
            z: z,
            opacity: finalOpacity,
            size: finalSize
        )
    }
}
