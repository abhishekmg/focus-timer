import Foundation

@MainActor
@Observable
final class SyncService {
    private let kvStore = NSUbiquitousKeyValueStore.default
    private let deviceID: String
    private var onChange: ((SyncService) -> Void)?

    // Published remote state
    var remoteTimerState: String = "idle"
    var remoteEndTime: Date?
    var remotePausedRemaining: TimeInterval?
    var remotePhase: String = "work"
    var remoteTaskName: String = ""

    private enum Keys {
        static let timerState = "sync_timerState"
        static let endTime = "sync_endTime"
        static let pausedRemaining = "sync_pausedRemaining"
        static let phase = "sync_phase"
        static let taskName = "sync_taskName"
        static let deviceID = "sync_deviceID"
    }

    init() {
        // Stable per-device ID
        let key = "focustimer_device_id"
        if let existing = UserDefaults.standard.string(forKey: key) {
            self.deviceID = existing
        } else {
            let newID = UUID().uuidString
            UserDefaults.standard.set(newID, forKey: key)
            self.deviceID = newID
        }
    }

    func startObserving(onChange: @escaping (SyncService) -> Void) {
        self.onChange = onChange

        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kvStore,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.handleRemoteChange()
            }
        }

        kvStore.synchronize()
    }

    // MARK: - Publish local state

    func publishRunning(endTime: Date, phase: TimerPhase, taskName: String) {
        kvStore.set("running", forKey: Keys.timerState)
        kvStore.set(endTime.timeIntervalSince1970, forKey: Keys.endTime)
        kvStore.set(phase.rawValue, forKey: Keys.phase)
        kvStore.set(taskName, forKey: Keys.taskName)
        kvStore.set(deviceID, forKey: Keys.deviceID)
        kvStore.removeObject(forKey: Keys.pausedRemaining)
        kvStore.synchronize()
    }

    func publishPaused(remaining: TimeInterval, phase: TimerPhase, taskName: String) {
        kvStore.set("paused", forKey: Keys.timerState)
        kvStore.set(remaining, forKey: Keys.pausedRemaining)
        kvStore.set(phase.rawValue, forKey: Keys.phase)
        kvStore.set(taskName, forKey: Keys.taskName)
        kvStore.set(deviceID, forKey: Keys.deviceID)
        kvStore.removeObject(forKey: Keys.endTime)
        kvStore.synchronize()
    }

    func publishIdle() {
        kvStore.set("idle", forKey: Keys.timerState)
        kvStore.set(deviceID, forKey: Keys.deviceID)
        kvStore.removeObject(forKey: Keys.endTime)
        kvStore.removeObject(forKey: Keys.pausedRemaining)
        kvStore.synchronize()
    }

    // MARK: - Handle remote changes

    private func handleRemoteChange() {
        // Ignore our own changes
        let remoteDevice = kvStore.string(forKey: Keys.deviceID) ?? ""
        guard remoteDevice != deviceID else { return }

        remoteTimerState = kvStore.string(forKey: Keys.timerState) ?? "idle"
        remotePhase = kvStore.string(forKey: Keys.phase) ?? "work"
        remoteTaskName = kvStore.string(forKey: Keys.taskName) ?? ""

        let endTimeInterval = kvStore.double(forKey: Keys.endTime)
        if endTimeInterval > 0 {
            remoteEndTime = Date(timeIntervalSince1970: endTimeInterval)
        } else {
            remoteEndTime = nil
        }

        let paused = kvStore.double(forKey: Keys.pausedRemaining)
        remotePausedRemaining = paused > 0 ? paused : nil

        onChange?(self)
    }
}
