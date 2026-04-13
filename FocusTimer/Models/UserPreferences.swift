import SwiftUI

@MainActor
@Observable
final class UserPreferences {
    var workDuration: Double {
        didSet { save("workDuration", workDuration) }
    }
    var breakDuration: Double {
        didSet { save("breakDuration", breakDuration) }
    }
    var soundEnabled: Bool {
        didSet { save("soundEnabled", soundEnabled) }
    }
    var notificationsEnabled: Bool {
        didSet { save("notificationsEnabled", notificationsEnabled) }
    }
    var autoStartBreaks: Bool {
        didSet { save("autoStartBreaks", autoStartBreaks) }
    }
    var autoStartWork: Bool {
        didSet { save("autoStartWork", autoStartWork) }
    }
    var selectedTheme: ThemeIdentifier {
        didSet { save("selectedTheme", selectedTheme.rawValue) }
    }

    private let cloudStore = NSUbiquitousKeyValueStore.default
    nonisolated(unsafe) private var observer: NSObjectProtocol?

    init() {
        let defaults = UserDefaults.standard
        let cloud = NSUbiquitousKeyValueStore.default

        // Prefer cloud values, fall back to local
        self.workDuration = (cloud.object(forKey: "workDuration") as? Double)
            ?? (defaults.object(forKey: "workDuration") as? Double)
            ?? Constants.defaultWorkDuration
        self.breakDuration = (cloud.object(forKey: "breakDuration") as? Double)
            ?? (defaults.object(forKey: "breakDuration") as? Double)
            ?? Constants.defaultBreakDuration
        self.soundEnabled = (cloud.object(forKey: "soundEnabled") as? Bool)
            ?? (defaults.object(forKey: "soundEnabled") as? Bool)
            ?? true
        self.notificationsEnabled = (cloud.object(forKey: "notificationsEnabled") as? Bool)
            ?? (defaults.object(forKey: "notificationsEnabled") as? Bool)
            ?? true
        self.autoStartBreaks = (cloud.object(forKey: "autoStartBreaks") as? Bool)
            ?? (defaults.object(forKey: "autoStartBreaks") as? Bool)
            ?? false
        self.autoStartWork = (cloud.object(forKey: "autoStartWork") as? Bool)
            ?? (defaults.object(forKey: "autoStartWork") as? Bool)
            ?? false
        self.selectedTheme = ThemeIdentifier(
            rawValue: cloud.string(forKey: "selectedTheme")
                ?? defaults.string(forKey: "selectedTheme")
                ?? "particle"
        ) ?? .particle

        // Listen for remote changes
        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.loadFromCloud()
            }
        }
        cloud.synchronize()
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    private func save(_ key: String, _ value: Any) {
        UserDefaults.standard.set(value, forKey: key)
        cloudStore.set(value, forKey: key)
        cloudStore.synchronize()
    }

    private func loadFromCloud() {
        let store = cloudStore

        if let v = store.object(forKey: "workDuration") as? Double, v != workDuration {
            workDuration = v
        }
        if let v = store.object(forKey: "breakDuration") as? Double, v != breakDuration {
            breakDuration = v
        }
        if let v = store.object(forKey: "soundEnabled") as? Bool, v != soundEnabled {
            soundEnabled = v
        }
        if let v = store.object(forKey: "notificationsEnabled") as? Bool, v != notificationsEnabled {
            notificationsEnabled = v
        }
        if let v = store.object(forKey: "autoStartBreaks") as? Bool, v != autoStartBreaks {
            autoStartBreaks = v
        }
        if let v = store.object(forKey: "autoStartWork") as? Bool, v != autoStartWork {
            autoStartWork = v
        }
        if let v = store.string(forKey: "selectedTheme"), let theme = ThemeIdentifier(rawValue: v), theme != selectedTheme {
            selectedTheme = theme
        }
    }
}
