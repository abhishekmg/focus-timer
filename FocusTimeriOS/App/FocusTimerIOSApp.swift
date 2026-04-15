import SwiftUI
import SwiftData

@main
struct FocusTimerIOSApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = TimerViewModel()

    var body: some Scene {
        WindowGroup {
            MainTimerScreen(viewModel: viewModel)
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: FocusSession.self)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.recalculateFromEndTime()
                viewModel.forceSync()
            }
        }
    }
}
