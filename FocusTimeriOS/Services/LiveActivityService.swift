#if os(iOS)
import ActivityKit
import Foundation

@MainActor
final class LiveActivityService {
    private var currentActivity: Activity<FocusTimerAttributes>?
    private var tokenTask: Task<Void, Never>?
    var onPushTokenUpdate: ((String) -> Void)?

    func startActivity(taskName: String, totalDuration: TimeInterval, phase: TimerPhase, endTime: Date, progress: Double, remainingSeconds: TimeInterval) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // End all existing activities to prevent ghost duplicates
        endAllActivities()

        let attributes = FocusTimerAttributes(
            taskName: taskName,
            totalDuration: totalDuration
        )

        let state = FocusTimerAttributes.ContentState(
            phase: phase.rawValue,
            timerState: "running",
            endTime: endTime,
            progress: progress,
            remainingSeconds: remainingSeconds
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: Date.now.addingTimeInterval(4 * 3600)),
                pushType: .token
            )
            currentActivity = activity
            observePushToken(activity: activity)
        } catch {
            // Live Activity not available — silently continue
        }
    }

    func updateActivity(phase: TimerPhase, timerState: String, endTime: Date, progress: Double, remainingSeconds: TimeInterval, taskName: String = "", totalDuration: TimeInterval = 0) {
        // Adopt an orphaned *active* activity if our reference was lost (e.g. app relaunch).
        // Skip activities in any other state (ended/dismissed/stale) — those are dying
        // and updating them is a no-op that wastes the chance to create a fresh one.
        if currentActivity == nil,
           let existing = Activity<FocusTimerAttributes>.activities.first(where: { $0.activityState == .active }) {
            currentActivity = existing
            observePushToken(activity: existing)
        }

        // If the tracked activity is no longer active (e.g. it just ended for a phase
        // transition), drop it so we create a fresh one below.
        if let current = currentActivity, current.activityState != .active {
            currentActivity = nil
            tokenTask?.cancel()
            tokenTask = nil
        }

        // If no activity exists at all, create one (e.g. timer started on macOS, iOS in foreground)
        if currentActivity == nil {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            let attributes = FocusTimerAttributes(
                taskName: taskName,
                totalDuration: totalDuration
            )
            let contentState = FocusTimerAttributes.ContentState(
                phase: phase.rawValue,
                timerState: timerState,
                endTime: endTime,
                progress: progress,
                remainingSeconds: remainingSeconds
            )
            do {
                let activity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: contentState, staleDate: Date.now.addingTimeInterval(4 * 3600)),
                    pushType: .token
                )
                currentActivity = activity
                observePushToken(activity: activity)
            } catch {
                // Live Activity not available
            }
            return
        }

        let state = FocusTimerAttributes.ContentState(
            phase: phase.rawValue,
            timerState: timerState,
            endTime: endTime,
            progress: progress,
            remainingSeconds: remainingSeconds
        )

        let activity = currentActivity
        Task {
            await activity?.update(.init(state: state, staleDate: Date.now.addingTimeInterval(4 * 3600)))
        }
    }

    func endActivity() {
        endAllActivities()
    }

    // MARK: - Private

    /// Ends the tracked activity and any orphaned activities from prior sessions.
    private func endAllActivities() {
        let finalState = FocusTimerAttributes.ContentState(
            phase: "work",
            timerState: "idle",
            endTime: .now,
            progress: 1.0,
            remainingSeconds: 0
        )
        let finalContent = ActivityContent(state: finalState, staleDate: nil)

        // End all activities (tracked + orphans)
        for activity in Activity<FocusTimerAttributes>.activities {
            Task {
                await activity.end(finalContent, dismissalPolicy: .immediate)
            }
        }

        tokenTask?.cancel()
        tokenTask = nil
        currentActivity = nil
    }

    // MARK: - Push Token

    private func observePushToken(activity: Activity<FocusTimerAttributes>) {
        tokenTask?.cancel()

        // Publish the current token immediately if we have one, so Mac doesn't
        // keep sending to a stale token during the brief gap between phase
        // transitions (focus → break creates a brand new activity + token).
        if let tokenData = activity.pushToken {
            let token = tokenData.map { String(format: "%02x", $0) }.joined()
            onPushTokenUpdate?(token)
        }

        tokenTask = Task {
            for await tokenData in activity.pushTokenUpdates {
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                onPushTokenUpdate?(token)
            }
        }
    }
}
#endif
