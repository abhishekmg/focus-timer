import SwiftUI
import SwiftData

struct TimerPopoverView: View {
    @Bindable var viewModel: TimerViewModel
    var onDetach: (() -> Void)?
    var onClose: (() -> Void)?

    var body: some View {
        ZStack {
            Color.black

            VStack(spacing: 0) {
                Spacer()

                ParticleThemeView(
                    progress: viewModel.progress,
                    phase: viewModel.phase,
                    state: viewModel.state
                )
                .frame(width: 200, height: 200)

                Spacer()
                    .frame(height: 28)

                CountdownLabel(
                    remainingSeconds: viewModel.remainingSeconds,
                    phase: viewModel.phase,
                    state: viewModel.state
                )

                Spacer()
                    .frame(height: 28)

                TimerControlsView(
                    state: viewModel.state,
                    phase: viewModel.phase,
                    onStartPause: viewModel.startPause,
                    onSkip: viewModel.skip,
                    onRevert: viewModel.revert
                )

                Spacer()
            }

            // Top-right buttons
            VStack {
                HStack(spacing: 8) {
                    Spacer()
                    if let onDetach {
                        Button(action: onDetach) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(.white.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                    }
                    if let onClose {
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(.white.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
                Spacer()
            }
        }
        .frame(width: Constants.popoverWidth, height: Constants.popoverHeight)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
