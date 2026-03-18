import SwiftUI

@Observable
final class UserPreferences {
    var workDuration: Double {
        didSet { UserDefaults.standard.set(workDuration, forKey: "workDuration") }
    }
    var breakDuration: Double {
        didSet { UserDefaults.standard.set(breakDuration, forKey: "breakDuration") }
    }
    var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }
    var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }
    var autoStartBreaks: Bool {
        didSet { UserDefaults.standard.set(autoStartBreaks, forKey: "autoStartBreaks") }
    }
    var autoStartWork: Bool {
        didSet { UserDefaults.standard.set(autoStartWork, forKey: "autoStartWork") }
    }

    init() {
        let defaults = UserDefaults.standard
        self.workDuration = defaults.object(forKey: "workDuration") as? Double ?? Constants.defaultWorkDuration
        self.breakDuration = defaults.object(forKey: "breakDuration") as? Double ?? Constants.defaultBreakDuration
        self.soundEnabled = defaults.object(forKey: "soundEnabled") as? Bool ?? true
        self.notificationsEnabled = defaults.object(forKey: "notificationsEnabled") as? Bool ?? true
        self.autoStartBreaks = defaults.object(forKey: "autoStartBreaks") as? Bool ?? false
        self.autoStartWork = defaults.object(forKey: "autoStartWork") as? Bool ?? false
    }
}
