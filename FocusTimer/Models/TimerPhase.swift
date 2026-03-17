import Foundation

enum TimerPhase: String, Sendable {
    case work
    case rest

    var label: String {
        switch self {
        case .work: "Focus"
        case .rest: "Break"
        }
    }
}
