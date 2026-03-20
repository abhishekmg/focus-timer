import SwiftUI
import SwiftData

@main
struct FocusTimerIOSApp: App {
    @State private var viewModel = TimerViewModel()

    var body: some Scene {
        WindowGroup {
            MainTimerScreen(viewModel: viewModel)
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: FocusSession.self)
    }
}
