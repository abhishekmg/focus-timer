import SwiftUI

struct TaskNameField: View {
    @Binding var taskName: String
    let isEditable: Bool

    var body: some View {
        if isEditable {
            TextField("task name", text: $taskName)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 200)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.03))
                )
        } else {
            Text(taskName.isEmpty ? "—" : taskName)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.textSecondary)
        }
    }
}
