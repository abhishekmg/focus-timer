import SwiftUI
import SwiftData

struct MainTimerScreen: View {
    @Bindable var viewModel: TimerViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var showSessions = false
    @State private var showSettings = false
    @State private var hasConfigured = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                // Sync toast
                VStack {
                    SyncToast(isVisible: viewModel.showSyncToast)
                        .padding(.top, 16)
                    Spacer()
                }
                .allowsHitTesting(false)
                .zIndex(1)

                VStack(spacing: 0) {
                    Spacer()

                    // Particle sphere — top 60%
                    ParticleThemeView(
                        progress: viewModel.progress,
                        phase: viewModel.phase,
                        state: viewModel.state
                    )
                    .frame(
                        width: geo.size.width * 0.75,
                        height: geo.size.width * 0.75
                    )

                    Spacer()
                        .frame(height: 32)

                    // Phase label
                    Text(viewModel.phase.label.lowercased())
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(viewModel.phase == .work ? Color.ember : Color.sage)
                        .kerning(3)

                    Spacer()
                        .frame(height: 12)

                    // Countdown
                    Text(TimeFormatting.formatted(viewModel.remainingSeconds))
                        .font(.system(size: 56, weight: .thin, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .opacity(viewModel.state == .paused ? 0.4 : 1.0)
                        .animation(.easeInOut(duration: 0.6), value: viewModel.state == .paused)

                    Spacer()
                        .frame(height: 20)

                    // Task name
                    TaskNameField(
                        taskName: $viewModel.taskName,
                        isEditable: viewModel.state == .idle || viewModel.state == .finished
                    )

                    Spacer()
                        .frame(height: 28)

                    // Play/pause button
                    TimerControlsView(
                        state: viewModel.state,
                        phase: viewModel.phase,
                        onStartPause: viewModel.startPause,
                        onSkip: viewModel.skip,
                        onRevert: viewModel.revert
                    )

                    Spacer()

                    // Bottom bar
                    iOSBottomBar(
                        completedSessions: viewModel.completedSessionsToday,
                        completedBreaks: viewModel.completedBreaksToday,
                        onSessionsTapped: { showSessions = true },
                        onSettingsTapped: { showSettings = true }
                    )
                    .padding(.bottom, 8)
                }
            }
        }
        .onAppear {
            if !hasConfigured {
                viewModel.configure(modelContext: modelContext)
                hasConfigured = true
            }
        }
        .sheet(isPresented: $showSessions) {
            NavigationStack {
                SessionListView()
                    .background(Color.black)
                    .navigationTitle("Sessions")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showSessions = false }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView(
                    preferences: viewModel.preferences,
                    onReset: viewModel.reset,
                    onDurationChanged: viewModel.syncIdleDuration
                )
                .background(Color.black)
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showSettings = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - iOS Bottom Bar

private struct iOSBottomBar: View {
    let completedSessions: Int
    let completedBreaks: Int
    let onSessionsTapped: () -> Void
    let onSettingsTapped: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Sessions button
            Button(action: onSessionsTapped) {
                Image(systemName: "list.dash")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // Session & break counts
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.ember)
                        .frame(width: 6, height: 6)
                    Text("\(completedSessions)")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.ember)
                }
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.sage)
                        .frame(width: 6, height: 6)
                    Text("\(completedBreaks)")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.sage)
                }
            }

            Spacer()

            // Settings button
            Button(action: onSettingsTapped) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 20)
    }
}
