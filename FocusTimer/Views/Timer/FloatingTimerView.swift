import SwiftUI

struct FloatingTimerView: View {
    @Bindable var viewModel: TimerViewModel
    var onClose: (() -> Void)?

    @State private var isHovering = false

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)

            ZStack {
                Color.black

                ParticleThemeView(
                    progress: viewModel.progress,
                    phase: viewModel.phase,
                    state: viewModel.state
                )
                .frame(width: side * 0.85, height: side * 0.85)

                // Overlay — small timer top-left, close button top-right on hover
                // Hover overlay — timer, close, play/pause
                if isHovering {
                    VStack {
                        HStack {
                            Text(TimeFormatting.formatted(viewModel.remainingSeconds))
                                .font(.system(size: 16, weight: .thin, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(10)
                            Spacer()
                            if let onClose {
                                Button(action: onClose) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.6))
                                        .frame(width: 20, height: 20)
                                        .background(Circle().fill(.white.opacity(0.1)))
                                }
                                .buttonStyle(.plain)
                                .padding(8)
                            }
                        }
                        Spacer()
                        Button(action: viewModel.startPause) {
                            Image(systemName: viewModel.state == .running ? "pause.fill" : "play.fill")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(.white.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 10)
                    }
                    .transition(.opacity)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}
