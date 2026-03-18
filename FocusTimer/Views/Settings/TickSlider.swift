import SwiftUI

struct TickSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>

    @State private var isDragging = false

    private let trackHeight: CGFloat = 20
    private let thumbWidth: CGFloat = 6
    private let thumbHeight: CGFloat = 22

    private var steps: Int { Int(range.upperBound - range.lowerBound) }

    private func fraction(for val: Double) -> Double {
        (val - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width

            ZStack(alignment: .leading) {
                // Tick marks
                Canvas { context, size in
                    let tickCount = min(steps, 120)
                    let spacing = size.width / Double(tickCount)

                    for i in 0...tickCount {
                        let x = Double(i) * spacing
                        let isMajor = steps <= 30 ? (i % 5 == 0) : (i % 10 == 0)
                        let tickH: Double = isMajor ? 12 : 7
                        let tickW: Double = isMajor ? 1.5 : 1
                        let opacity: Double = isMajor ? 0.35 : 0.18

                        let rect = CGRect(
                            x: x - tickW / 2,
                            y: (size.height - tickH) / 2,
                            width: tickW,
                            height: tickH
                        )
                        context.fill(
                            Path(roundedRect: rect, cornerRadius: tickW / 2),
                            with: .color(.white.opacity(opacity))
                        )
                    }
                }
                .frame(height: trackHeight)

                // Thumb
                let thumbX = fraction(for: value) * (width - thumbWidth)
                RoundedRectangle(cornerRadius: 3)
                    .fill(.white.opacity(0.85))
                    .frame(width: thumbWidth, height: thumbHeight)
                    .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 1)
                    .offset(x: thumbX)
            }
            .frame(height: thumbHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        isDragging = true
                        let fraction = max(0, min(1, drag.location.x / width))
                        let stepped = (fraction * Double(steps)).rounded()
                        value = range.lowerBound + stepped
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .frame(height: thumbHeight)
    }
}
