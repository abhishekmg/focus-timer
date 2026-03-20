#if os(iOS)
import ActivityKit
import Foundation

@MainActor
final class LiveActivityService {
    private var currentActivity: Activity<FocusTimerAttributes>?

    func startActivity(taskName: String, totalDuration: TimeInterval, phase: TimerPhase, endTime: Date, progress: Double) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = FocusTimerAttributes(
            taskName: taskName,
            totalDuration: totalDuration
        )

        let state = FocusTimerAttributes.ContentState(
            phase: phase.rawValue,
            timerState: "running",
            endTime: endTime,
            progress: progress
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: endTime.addingTimeInterval(60)),
                pushType: nil
            )
            currentActivity = activity
        } catch {
            // Live Activity not available — silently continue
        }
    }

    func updateActivity(phase: TimerPhase, timerState: String, endTime: Date, progress: Double) {
        guard let activity = currentActivity else { return }

        let state = FocusTimerAttributes.ContentState(
            phase: phase.rawValue,
            timerState: timerState,
            endTime: endTime,
            progress: progress
        )

        Task {
            await activity.update(.init(state: state, staleDate: endTime.addingTimeInterval(60)))
        }
    }

    func endActivity() {
        guard let activity = currentActivity else { return }

        let finalState = FocusTimerAttributes.ContentState(
            phase: "work",
            timerState: "idle",
            endTime: .now,
            progress: 1.0
        )

        Task {
            await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }
}
#endif
