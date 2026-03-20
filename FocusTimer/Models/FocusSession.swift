import Foundation
import SwiftData

@Model
final class FocusSession {
    var taskName: String = ""
    var phase: String = "work"
    var duration: TimeInterval = 1500
    var startedAt: Date = Date.now
    var completedAt: Date?
    var completed: Bool = false

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
