import SwiftUI
import SwiftData

struct MainTimerScreen: View {
    @Bindable var viewModel: TimerViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var showSessions = false
    @State private var showSettings = false
    @State private var hasConfigured = false
    @State private var showSkipConfirmation = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                // Dim overlay when a sheet is presented, since pure-black
                // content doesn't visibly dim on its own.
                Color.black
                    .opacity((showSessions || showSettings) ? 0.35 : 0)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.25), value: showSessions)
                    .animation(.easeInOut(duration: 0.25), value: showSettings)
                    .allowsHitTesting(false)
                    .zIndex(2)

                // Toasts
                VStack(spacing: 4) {
                    SyncToast(isVisible: viewModel.showSyncToast)
                    SyncToast(isVisible: viewModel.showToast, message: viewModel.toastMessage)
                    Spacer()
                }
                .padding(.top, 16)
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

                    // Play/pause + skip
                    ZStack {
                        TimerControlsView(
                            state: viewModel.state,
                            phase: viewModel.phase,
                            onStartPause: viewModel.startPause,
                            onSkip: viewModel.skip,
                            onRevert: viewModel.revert
                        )

                        HStack {
                            Spacer()
                            Button {
                                showSkipConfirmation = true
                            } label: {
                                Image(systemName: "forward.end.fill")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.textTertiary)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.trailing, 40)
                    }

                    Spacer()

                    // Bottom bar
                    iOSBottomBar(
                        completedSessions: viewModel.completedSessionsToday,
                        completedBreaks: viewModel.completedBreaksToday,
                        onSyncTapped: { viewModel.forceSync() },
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
        .alert("skip this session?", isPresented: $showSkipConfirmation) {
            Button("skip", role: .destructive) {
                viewModel.skip()
            }
            Button("cancel", role: .cancel) { }
        } message: {
            Text(viewModel.phase == .work
                 ? "your current focus session will end and a break will start."
                 : "your current break will end and a focus session will start.")
        }
        .sheet(isPresented: $showSessions) {
            NavigationStack {
                SessionListView(onClearAll: { viewModel.resetTodayCounters() })
                    .navigationTitle("Sessions")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(white: 0.07))
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                ZStack {
                    SettingsView(
                        preferences: viewModel.preferences,
                        onReset: viewModel.reset,
                        onDurationChanged: viewModel.syncIdleDuration,
                        onShowToast: viewModel.showToastMessage
                    )

                    VStack {
                        SyncToast(isVisible: viewModel.showToast, message: viewModel.toastMessage)
                            .padding(.top, 8)
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }
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
            .presentationBackground(Color(white: 0.07))
        }
    }
}

// MARK: - iOS Bottom Bar

private struct iOSBottomBar: View {
    let completedSessions: Int
    let completedBreaks: Int
    let onSyncTapped: () -> Void
    let onSessionsTapped: () -> Void
    let onSettingsTapped: () -> Void

    var body: some View {
        ZStack {
            // Counters — centered in the full width so they align
            // with the play/pause button above.
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

            HStack(spacing: 0) {
                // Sync button
                Button(action: onSyncTapped) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .frame(width: 44, height: 44)
                }

                // Sessions button
                Button(action: onSessionsTapped) {
                    Image(systemName: "list.dash")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .frame(width: 44, height: 44)
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
        }
        .padding(.horizontal, 20)
    }
}
