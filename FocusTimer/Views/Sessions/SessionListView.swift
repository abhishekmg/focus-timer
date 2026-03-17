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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("sessions")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.textTertiary)
                .kerning(2)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 12)

            if sessions.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        .frame(width: 40, height: 40)
                    Text("no sessions yet")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.textTertiary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(sessions) { session in
                            SessionRowView(session: session) {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    modelContext.delete(session)
                                    try? modelContext.save()
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }
            }
        }
    }
}
