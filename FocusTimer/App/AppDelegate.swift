#if os(macOS)
import AppKit
import SwiftData

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?
    let viewModel = TimerViewModel()
    var modelContainer: ModelContainer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let schema = Schema([FocusSession.self])

        // Try CloudKit first, fall back to local if existing store is incompatible
        let container: ModelContainer
        do {
            let cloudConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            container = try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            // Delete old incompatible store and retry with CloudKit
            let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
            for ext in ["", "-shm", "-wal"] {
                let url = storeURL.deletingLastPathComponent().appending(path: "default.store\(ext)")
                try? FileManager.default.removeItem(at: url)
            }
            do {
                let cloudConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .automatic
                )
                container = try ModelContainer(for: schema, configurations: [cloudConfig])
            } catch {
                // Last resort: local only — if this also fails, use in-memory
                do {
                    let localConfig = ModelConfiguration(
                        schema: schema,
                        isStoredInMemoryOnly: false,
                        cloudKitDatabase: .none
                    )
                    container = try ModelContainer(for: schema, configurations: [localConfig])
                } catch {
                    let memoryConfig = ModelConfiguration(
                        schema: schema,
                        isStoredInMemoryOnly: true
                    )
                    container = try! ModelContainer(for: schema, configurations: [memoryConfig])
                }
            }
        }

        self.modelContainer = container
        viewModel.configure(modelContext: container.mainContext)

        let controller = MenuBarController(viewModel: viewModel, modelContainer: container)
        self.menuBarController = controller
    }
}
#endif
