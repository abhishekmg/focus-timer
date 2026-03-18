import SwiftUI

struct BottomBarView: View {
    let completedSessions: Int
    let targetSessions: Int
    let onSessionsTapped: () -> Void
    let onSettingsTapped: () -> Void
    let onDetachTapped: () -> Void

    @State private var sessionsHover = false
    @State private var detachHover = false
    @State private var settingsHover = false

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onSessionsTapped) {
                Image(systemName: "list.dash")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(sessionsHover ? Color.textSecondary : Color.textTertiary)
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.surfaceGlass.opacity(sessionsHover ? 1.0 : 0.0))
                    )
            }
            .buttonStyle(.plain)
            .onHover { sessionsHover = $0 }

            Spacer()

            // Session pips — refined capsule design
            HStack(spacing: 6) {
                ForEach(0..<min(targetSessions, 8), id: \.self) { i in
                    Capsule()
                        .fill(i < completedSessions ? Color.ember : Color.white.opacity(0.08))
                        .frame(width: i < completedSessions ? 12 : 5, height: 5)
                        .animation(.easeOut(duration: 0.3), value: completedSessions)
                }
            }

            Spacer()

            HStack(spacing: 2) {
                Button(action: onDetachTapped) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(detachHover ? Color.textSecondary : Color.textTertiary)
                        .frame(width: 30, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.surfaceGlass.opacity(detachHover ? 1.0 : 0.0))
                        )
                }
                .buttonStyle(.plain)
                .onHover { detachHover = $0 }

                Button(action: onSettingsTapped) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(settingsHover ? Color.textSecondary : Color.textTertiary)
                        .frame(width: 30, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.surfaceGlass.opacity(settingsHover ? 1.0 : 0.0))
                        )
                }
                .buttonStyle(.plain)
                .onHover { settingsHover = $0 }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
