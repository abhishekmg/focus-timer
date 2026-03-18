import SwiftUI

struct TaskNameField: View {
    @Binding var taskName: String
    let isEditable: Bool

    @State private var isFocused = false

    var body: some View {
        if isEditable {
            TextField("what are you working on?", text: $taskName)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 220)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.surfaceGlass)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.borderSubtle, lineWidth: 0.5)
                        )
                )
        } else {
            Text(taskName.isEmpty ? "—" : taskName)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.textSecondary)
        }
    }
}
