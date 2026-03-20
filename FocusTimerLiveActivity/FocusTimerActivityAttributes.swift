import ActivityKit
import Foundation

struct FocusTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phase: String
        var timerState: String
        var endTime: Date
        var progress: Double
    }

    var taskName: String
    var totalDuration: TimeInterval
}
