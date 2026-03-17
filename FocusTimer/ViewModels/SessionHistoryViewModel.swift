import Foundation
import SwiftData

@MainActor
@Observable
final class SessionHistoryViewModel {
    var sessions: [FocusSession] = []
    private var modelContext: ModelContext?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSessions()
    }

    func loadSessions() {
        guard let modelContext else { return }
        let startOfDay = Calendar.current.startOfDay(for: .now)
        var descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { $0.startedAt >= startOfDay },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 50
        sessions = (try? modelContext.fetch(descriptor)) ?? []
    }

    func deleteSession(_ session: FocusSession) {
        modelContext?.delete(session)
        try? modelContext?.save()
        loadSessions()
    }
}
