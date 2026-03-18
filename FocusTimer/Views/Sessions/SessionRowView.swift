import SwiftUI

struct SessionRowView: View {
    let session: FocusSession
    let onDelete: () -> Void

    @State private var isHovered = false

    private var phaseColor: Color {
        session.timerPhase == .work ? .ember : .sage
    }

    var body: some View {
        HStack(spacing: 12) {
            // Vertical accent bar with glow
            ZStack {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(phaseColor.opacity(session.completed ? 0.3 : 0.15))
                    .frame(width: 3, height: 30)
                    .blur(radius: 2)

                RoundedRectangle(cornerRadius: 1.5)
                    .fill(phaseColor.opacity(session.completed ? 1.0 : 0.3))
                    .frame(width: 2, height: 28)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(session.taskName.isEmpty ? session.timerPhase.label.lowercased() : session.taskName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.textPrimary)

                Text(formattedTime)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer()

            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(Color.surfaceGlass)
                        )
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.surfaceGlass : .clear)
        )
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let start = formatter.string(from: session.startedAt)
        let duration = Int(session.duration / 60)
        return "\(start) · \(duration)m"
    }
}
