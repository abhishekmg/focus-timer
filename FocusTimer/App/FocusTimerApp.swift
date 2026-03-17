import SwiftUI
import SwiftData

@main
struct FocusTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(
                preferences: appDelegate.viewModel.preferences,
                onReset: appDelegate.viewModel.reset
            )
            .frame(width: 350, height: 450)
        }
        .defaultSize(width: 350, height: 450)
    }
}
