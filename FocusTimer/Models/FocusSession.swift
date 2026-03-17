import Foundation
import SwiftData

@Model
final class FocusSession {
    var taskName: String
    var phase: String
    var duration: TimeInterval
    var startedAt: Date
    var completedAt: Date?
    var completed: Bool

    init(
        taskName: String = "",
        phase: String = TimerPhase.work.rawValue,
        duration: TimeInterval = Constants.defaultWorkDuration,
        startedAt: Date = .now
    ) {
        self.taskName = taskName
        self.phase = phase
        self.duration = duration
        self.startedAt = startedAt
        self.completed = false
    }

    var timerPhase: TimerPhase {
        TimerPhase(rawValue: phase) ?? .work
    }
}
