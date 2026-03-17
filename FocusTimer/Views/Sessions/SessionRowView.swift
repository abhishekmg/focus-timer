import SwiftUI

struct SessionRowView: View {
    let session: FocusSession
    let onDelete: () -> Void

    private var phaseColor: Color {
        session.timerPhase == .work ? .ember : .sage
    }

    var body: some View {
        HStack(spacing: 12) {
            // Thin vertical accent bar
            RoundedRectangle(cornerRadius: 1)
                .fill(phaseColor.opacity(session.completed ? 1.0 : 0.3))
                .frame(width: 2, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(session.taskName.isEmpty ? session.timerPhase.label.lowercased() : session.taskName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.textPrimary)

                Text(formattedTime)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "minus.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
            }
            .buttonStyle(.plain)
            .opacity(0.6)
        }
        .padding(.vertical, 6)
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let start = formatter.string(from: session.startedAt)
        let duration = Int(session.duration / 60)
        return "\(start) · \(duration)m"
    }
}
