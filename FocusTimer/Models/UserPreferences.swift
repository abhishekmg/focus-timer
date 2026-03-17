import SwiftUI

@Observable
final class UserPreferences {
    @ObservationIgnored
    @AppStorage("workDuration") var workDuration: Double = Constants.defaultWorkDuration

    @ObservationIgnored
    @AppStorage("breakDuration") var breakDuration: Double = Constants.defaultBreakDuration

    @ObservationIgnored
    @AppStorage("longBreakDuration") var longBreakDuration: Double = Constants.defaultLongBreakDuration

    @ObservationIgnored
    @AppStorage("sessionsBeforeLongBreak") var sessionsBeforeLongBreak: Int = Constants.sessionsBeforeLongBreak

    @ObservationIgnored
    @AppStorage("soundEnabled") var soundEnabled: Bool = true

    @ObservationIgnored
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true

    @ObservationIgnored
    @AppStorage("autoStartBreaks") var autoStartBreaks: Bool = false

    @ObservationIgnored
    @AppStorage("autoStartWork") var autoStartWork: Bool = false
}
