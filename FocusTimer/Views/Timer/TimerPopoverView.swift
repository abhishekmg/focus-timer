import SwiftUI
import SwiftData

struct TimerPopoverView: View {
    @Bindable var viewModel: TimerViewModel
    var onDetach: (() -> Void)?
    @State private var showingSessions = false
    @State private var showingSettings = false

    private var accentColor: Color {
        viewModel.phase == .work ? .ember : .sage
    }

    var body: some View {
        ZStack {
            // Background with subtle noise texture
            Color.backgroundDark
            noiseOverlay

            VStack(spacing: 0) {
                if showingSessions {
                    sessionsView
                } else if showingSettings {
                    settingsWrapper
                } else {
                    timerView
                }

                // Bottom separator — subtle gradient line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.06), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 0.5)

                BottomBarView(
                    completedSessions: viewModel.completedSessionsToday,
                    targetSessions: viewModel.totalSessionsTarget,
                    onSessionsTapped: { withAnimation(.easeInOut(duration: 0.25)) { showingSessions.toggle(); showingSettings = false } },
                    onSettingsTapped: { withAnimation(.easeInOut(duration: 0.25)) { showingSettings.toggle(); showingSessions = false } },
                    onDetachTapped: { onDetach?() }
                )
            }
        }
        .frame(width: Constants.popoverWidth, height: Constants.popoverHeight)
    }

    // Subtle grain texture
    private var noiseOverlay: some View {
        Canvas { context, size in
            for _ in 0..<600 {
                let x = Double.random(in: 0...size.width)
                let y = Double.random(in: 0...size.height)
                let opacity = Double.random(in: 0.01...0.04)
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(.white.opacity(opacity))
                )
            }
        }
        .allowsHitTesting(false)
    }

    private var timerView: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 28)

            // Phase label — refined, small caps feel
            Text(viewModel.phase.label.lowercased())
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(accentColor.opacity(0.7))
                .kerning(3)

            Spacer()
                .frame(height: 24)

            // Ring + countdown
            ZStack {
                CircularProgressRing(
                    progress: viewModel.progress,
                    phase: viewModel.phase,
                    state: viewModel.state
                )

                CountdownLabel(
                    remainingSeconds: viewModel.remainingSeconds,
                    phase: viewModel.phase,
                    state: viewModel.state
                )
            }

            Spacer()
                .frame(height: 20)

            TaskNameField(
                taskName: $viewModel.taskName,
                isEditable: viewModel.state == .idle
            )

            Spacer()
                .frame(height: 24)

            TimerControlsView(
                state: viewModel.state,
                phase: viewModel.phase,
                onStartPause: viewModel.startPause,
                onSkip: viewModel.skip,
                onRevert: viewModel.revert
            )

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var sessionsView: some View {
        SessionListView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var settingsWrapper: some View {
        SettingsView(preferences: viewModel.preferences, onReset: viewModel.reset)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
