import AppKit
import SwiftData

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?
    let viewModel = TimerViewModel()
    var modelContainer: ModelContainer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let schema = Schema([FocusSession.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            self.modelContainer = container
            viewModel.configure(modelContext: container.mainContext)

            let controller = MenuBarController(viewModel: viewModel, modelContainer: container)
            self.menuBarController = controller
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
