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
    var totalSessionsTarget: Int = 8

    private let engine = TimerEngine()
    private let notificationService = NotificationService()
    private let soundService = SoundService()
    let preferences = UserPreferences()

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
            let isLong = sessionCount > 0 && sessionCount % preferences.sessionsBeforeLongBreak == 0
            return isLong ? preferences.longBreakDuration : preferences.breakDuration
        }
    }

    var menuBarText: String {
        guard state == .running || state == .paused else { return "" }
        let dot = phase == .work ? "🔴" : "🟢"
        return "\(TimeFormatting.shortFormatted(remainingSeconds)) \(dot)"
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadTodaySessions()
        notificationService.requestPermission()
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
        transitionPhase()
    }

    func revert() {
        engine.stop()
        currentSession = nil
        remainingSeconds = totalDuration
        state = .idle
    }

    func reset() {
        engine.stop()
        currentSession = nil
        state = .idle
        phase = .work
        sessionCount = 0
        remainingSeconds = preferences.workDuration
        taskName = ""
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

        engine.start { [weak self] in
            self?.tick()
        }
    }

    private func pause() {
        engine.stop()
        state = .paused
    }

    private func resume() {
        state = .running
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
            }

            if preferences.soundEnabled {
                soundService.playCompletionSound()
            }

            if preferences.notificationsEnabled {
                let title = phase == .work ? "Focus session complete!" : "Break is over!"
                let body = phase == .work ? "Time for a break." : "Ready to focus again?"
                notificationService.sendNotification(title: title, body: body)
            }

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
}
