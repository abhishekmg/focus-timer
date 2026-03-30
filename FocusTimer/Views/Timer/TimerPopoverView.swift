#if os(macOS)
import SwiftUI
import SwiftData

struct TimerPopoverView: View {
    @Bindable var viewModel: TimerViewModel
    var onDetach: (() -> Void)?
    var onClose: (() -> Void)?

    @State private var currentScreen: Screen = .timer

    private enum Screen {
        case timer, sessions, settings
    }

    var body: some View {
        ZStack {
            Color.black

            VStack(spacing: 0) {
                // Main content
                switch currentScreen {
                case .timer:
                    timerContent
                case .sessions:
                    SessionListView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .settings:
                    SettingsView(preferences: viewModel.preferences, onReset: viewModel.reset, onDurationChanged: viewModel.syncIdleDuration)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Bottom separator
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.06), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 0.5)

                // Bottom bar
                bottomBar
            }

            // Sync toast
            VStack {
                SyncToast(isVisible: viewModel.showSyncToast)
                    .padding(.top, 40)
                Spacer()
            }
            .allowsHitTesting(false)

            // Top-right buttons (only on timer screen)
            if currentScreen == .timer {
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
        }
        .frame(width: Constants.popoverWidth, height: Constants.popoverHeight)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var timerContent: some View {
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
    }

    private var bottomBar: some View {
        ZStack {
            // Centered session & break counts
            HStack(spacing: 12) {
                Text("\(viewModel.completedSessionsToday)")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.ember)
                Text("\(viewModel.completedBreaksToday)")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.sage)
            }

            // Left & right buttons
            HStack(spacing: 0) {
                bottomBarButton(icon: "timer", screen: .timer)
                Button {
                    viewModel.forceSync()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.3))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                Spacer()
                HStack(spacing: 2) {
                    bottomBarButton(icon: "list.dash", screen: .sessions)
                    bottomBarButton(icon: "slider.horizontal.3", screen: .settings)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func bottomBarButton(icon: String, screen: Screen) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentScreen = currentScreen == screen && screen != .timer ? .timer : screen
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(currentScreen == screen ? .white.opacity(0.8) : .white.opacity(0.3))
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
    }
}
#endif
