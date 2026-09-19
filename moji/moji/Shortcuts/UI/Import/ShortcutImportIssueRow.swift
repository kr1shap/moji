import SwiftUI

struct ShortcutImportIssueRow: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.circle")
            .font(.validationText)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview("Import Issue Row") {
    ShortcutImportIssueRow(message: "Row 3: Enter a shortcut name.")
        .padding()
        .frame(width: 500)
}
