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
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.textTertiary)
                .kerning(3)
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
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(sessions) { session in
                            SessionRowView(session: session) {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    modelContext.delete(session)
                                    try? modelContext.save()
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
