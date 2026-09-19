import SwiftUI

struct ShortcutImportPreviewRow: View {
    let entry: ShortcutImportEntry

    var body: some View {
        HStack(spacing: 10) {
            Text(entry.emoji)
                .font(.replacementText)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: 180, alignment: .leading)
                .accessibilityHidden(true)

            Text(":\(entry.alias):")
                .font(.header)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 8)

            Text(entry.action.rawValue)
                .font(.label)
                .foregroundStyle(entry.action == .override ? Color.orange : Color.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Row \(entry.rowNumber), shortcut \(entry.alias), \(entry.emoji), \(entry.action.rawValue)"
        )
    }
}

#Preview("Import Preview Row") {
    ShortcutImportPreviewRow(
        entry: ShortcutImportEntry(
            rowNumber: 1,
            alias: "shrug",
            emoji: "¯\\_(ツ)_/¯, honestly this replacement is intentionally long",
            action: .override
        )
    )
    .padding()
    .frame(width: 500)
}
