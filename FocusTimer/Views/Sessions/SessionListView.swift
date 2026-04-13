import SwiftUI
import SwiftData

struct SessionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<FocusSession> { _ in true },
        sort: \FocusSession.startedAt,
        order: .reverse
    )
    private var sessions: [FocusSession]

    @State private var showingClearConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("sessions")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.textTertiary)
                    .kerning(3)
                Spacer()
                #if os(macOS)
                if !sessions.isEmpty {
                    Button {
                        showingClearConfirmation = true
                    } label: {
                        Text("clear all")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.textTertiary)
                            .kerning(2)
                    }
                    .buttonStyle(.plain)
                }
                #endif
            }
                .padding(.horizontal, 28)
                .padding(.top, 22)
                .padding(.bottom, 14)

            if sessions.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .stroke(Color.borderSubtle, lineWidth: 1)
                            .frame(width: 44, height: 44)

                        Image(systemName: "clock")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(Color.textTertiary.opacity(0.5))
                    }
                    Text("no sessions yet")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.textTertiary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                #if os(iOS)
                List {
                    ForEach(groupedSessions, id: \.key) { group in
                        Section {
                            ForEach(group.sessions) { session in
                                SessionRowView(session: session) {
                                    delete(session)
                                }
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets())
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        delete(session)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            Text(group.label)
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color.textTertiary)
                                .kerning(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 28)
                                .padding(.top, 6)
                                .padding(.bottom, 4)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.defaultMinListRowHeight, 0)
                #else
                ScrollView {
                    LazyVStack(spacing: 2, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupedSessions, id: \.key) { group in
                            Section {
                                ForEach(group.sessions) { session in
                                    SessionRowView(session: session) {
                                        delete(session)
                                    }
                                    .padding(.horizontal, 20)
                                }
                            } header: {
                                Text(group.label)
                                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(Color.textTertiary)
                                    .kerning(2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 28)
                                    .padding(.top, 14)
                                    .padding(.bottom, 6)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                #endif
            }
        }
        .confirmationDialog(
            "are you sure you want to clear all sessions?",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("yes, clear all", role: .destructive) {
                withAnimation(.easeOut(duration: 0.2)) {
                    for session in sessions {
                        modelContext.delete(session)
                    }
                    try? modelContext.save()
                }
            }
            Button("no", role: .cancel) { }
        }
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !sessions.isEmpty {
                    Button("Clear All", role: .destructive) {
                        showingClearConfirmation = true
                    }
                    .tint(.red)
                }
            }
        }
        #endif
    }

    private func delete(_ session: FocusSession) {
        withAnimation(.easeOut(duration: 0.2)) {
            modelContext.delete(session)
            try? modelContext.save()
        }
    }

    private struct SessionGroup {
        let key: Date
        let label: String
        let sessions: [FocusSession]
    }

    private var groupedSessions: [SessionGroup] {
        let calendar = Calendar.current
        let buckets = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startedAt)
        }
        return buckets
            .sorted { $0.key > $1.key }
            .map { key, value in
                SessionGroup(key: key, label: Self.label(for: key, calendar: calendar), sessions: value)
            }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private static let yearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    private static func label(for day: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(day) { return "today" }
        if calendar.isDateInYesterday(day) { return "yesterday" }
        let now = Date()
        if calendar.isDate(day, equalTo: now, toGranularity: .year) {
            return dateFormatter.string(from: day).lowercased()
        }
        return yearFormatter.string(from: day).lowercased()
    }
}
