import Foundation

enum TimerState: String, Sendable {
    case idle
    case running
    case paused
    case finished
}
