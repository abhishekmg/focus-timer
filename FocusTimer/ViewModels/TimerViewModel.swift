import Foundation
import SwiftData

@MainActor
@Observable
final class TimerViewModel {
    var state: TimerState = .idle
    var phase: TimerPhase = .work
    var remainingSeconds: TimeInterval = Constants.defaultWorkDuration
    var taskName: String = ""
    var completedSessionsToday: Int = 0
    var completedBreaksToday: Int = 0
    var showSyncToast: Bool = false

    private let engine = TimerEngine()
    private let notificationService = NotificationService()
    private let soundService: any SoundServiceProtocol
    let preferences: UserPreferences
    let syncService = SyncService()
    #if os(iOS)
    let liveActivityService = LiveActivityService()
    #endif

    private var modelContext: ModelContext?
    private var currentSession: FocusSession?
    private var sessionCount: Int = 0

    var progress: Double {
        let total = totalDuration
        guard total > 0 else { return 0 }
        return 1.0 - (remainingSeconds / total)
    }

    var totalDuration: TimeInterval {
        switch phase {
        case .work:
            return preferences.workDuration
        case .rest:
            return preferences.breakDuration
        }
    }

    #if os(macOS)
    var menuBarText: String {
        guard state == .running || state == .paused else { return "" }
        let dot = phase == .work ? "🔴" : "🟢"
        return "\(TimeFormatting.shortFormatted(remainingSeconds)) \(dot)"
    }
    #endif

    init(soundService: (any SoundServiceProtocol)? = nil, preferences: UserPreferences = UserPreferences()) {
        #if os(macOS)
        self.soundService = soundService ?? SoundService()
        #else
        self.soundService = soundService ?? SoundServiceiOS()
        #endif
        self.preferences = preferences
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadTodaySessions()
        notificationService.requestPermission()

        syncService.startObserving { [weak self] sync in
            self?.handleRemoteSync(sync)
        }
    }

    /// Call when preferences change to keep the idle display in sync
    func syncIdleDuration() {
        if state == .idle {
            remainingSeconds = totalDuration
        }
    }

    // MARK: - Controls

    func startPause() {
        switch state {
        case .idle, .finished:
            start()
        case .running:
            pause()
        case .paused:
            resume()
        }
    }

    func skip() {
        engine.stop()
        if phase == .work {
            completeCurrentSession(finished: false)
        }
        syncService.publishIdle()
        #if os(iOS)
        liveActivityService.endActivity()
        #endif
        transitionPhase()
    }

    func revert() {
        engine.stop()
        currentSession = nil
        remainingSeconds = totalDuration
        state = .idle
        syncService.publishIdle()
        #if os(iOS)
        liveActivityService.endActivity()
        #endif
    }

    func reset() {
        engine.stop()
        currentSession = nil
        state = .idle
        phase = .work
        sessionCount = 0
        remainingSeconds = preferences.workDuration
        taskName = ""
        syncService.publishIdle()
        #if os(iOS)
        liveActivityService.endActivity()
        #endif
    }

    // MARK: - Private

    private func start() {
        remainingSeconds = totalDuration
        state = .running

        if phase == .work {
            let session = FocusSession(
                taskName: taskName,
                phase: phase.rawValue,
                duration: totalDuration
            )
            currentSession = session
            modelContext?.insert(session)
        }

        let endTime = Date.now.addingTimeInterval(remainingSeconds)
        syncService.publishRunning(endTime: endTime, phase: phase, taskName: taskName)

        #if os(iOS)
        liveActivityService.startActivity(
            taskName: taskName,
            totalDuration: totalDuration,
            phase: phase,
            endTime: endTime,
            progress: progress
        )
        #endif

        engine.start { [weak self] in
            self?.tick()
        }
    }

    private func pause() {
        engine.stop()
        state = .paused
        syncService.publishPaused(remaining: remainingSeconds, phase: phase, taskName: taskName)

        #if os(iOS)
        liveActivityService.updateActivity(
            phase: phase,
            timerState: "paused",
            endTime: Date.now.addingTimeInterval(remainingSeconds),
            progress: progress
        )
        #endif
    }

    private func resume() {
        state = .running

        let endTime = Date.now.addingTimeInterval(remainingSeconds)
        syncService.publishRunning(endTime: endTime, phase: phase, taskName: taskName)

        #if os(iOS)
        liveActivityService.updateActivity(
            phase: phase,
            timerState: "running",
            endTime: endTime,
            progress: progress
        )
        #endif

        engine.start { [weak self] in
            self?.tick()
        }
    }

    private func tick() {
        guard state == .running else { return }
        remainingSeconds -= 1

        if remainingSeconds <= 0 {
            remainingSeconds = 0
            engine.stop()
            state = .finished

            if phase == .work {
                completeCurrentSession(finished: true)
                sessionCount += 1
            } else {
                completedBreaksToday += 1
            }

            if preferences.soundEnabled {
                soundService.playCompletionSound()
            }

            if preferences.notificationsEnabled {
                let title = phase == .work ? "Focus session complete!" : "Break is over!"
                let body = phase == .work ? "Time for a break." : "Ready to focus again?"
                notificationService.sendNotification(title: title, body: body)
            }

            syncService.publishIdle()
            #if os(iOS)
            liveActivityService.endActivity()
            #endif

            let shouldAutoStart = phase == .work ? preferences.autoStartBreaks : preferences.autoStartWork
            transitionPhase()
            if shouldAutoStart {
                start()
            }
        }
    }

    private func transitionPhase() {
        phase = (phase == .work) ? .rest : .work
        remainingSeconds = totalDuration
        state = .idle
        currentSession = nil
    }

    private func completeCurrentSession(finished: Bool) {
        currentSession?.completed = finished
        currentSession?.completedAt = .now
        try? modelContext?.save()
        if finished {
            completedSessionsToday += 1
        }
    }

    private func loadTodaySessions() {
        guard let modelContext else { return }
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { $0.startedAt >= startOfDay && $0.completed == true && $0.phase == "work" }
        )
        completedSessionsToday = (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Remote Sync

    private func handleRemoteSync(_ sync: SyncService) {
        let didSync: Bool

        switch sync.remoteTimerState {
        case "running":
            guard let endTime = sync.remoteEndTime else { return }
            let remaining = endTime.timeIntervalSince(.now)
            guard remaining > 0 else {
                if state != .idle && state != .finished {
                    state = .finished
                    engine.stop()
                    if preferences.notificationsEnabled {
                        let title = "Timer finished on another device"
                        notificationService.sendNotification(title: title, body: "")
                    }
                }
                didSync = true
                break
            }
            phase = TimerPhase(rawValue: sync.remotePhase) ?? .work
            taskName = sync.remoteTaskName
            remainingSeconds = remaining
            if state != .running {
                state = .running
                engine.start { [weak self] in
                    self?.tick()
                }
            }
            didSync = true

        case "paused":
            engine.stop()
            phase = TimerPhase(rawValue: sync.remotePhase) ?? .work
            taskName = sync.remoteTaskName
            remainingSeconds = sync.remotePausedRemaining ?? remainingSeconds
            state = .paused
            didSync = true

        case "idle":
            if state == .running || state == .paused {
                engine.stop()
                state = .idle
                remainingSeconds = totalDuration
                didSync = true
            } else {
                didSync = false
            }

        default:
            didSync = false
        }

        if didSync {
            showSyncToast = true
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3))
                showSyncToast = false
            }
        }
    }
}
