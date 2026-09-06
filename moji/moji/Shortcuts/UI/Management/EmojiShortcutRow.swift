import SwiftUI

struct EmojiShortcutRow: View {
    let shortcut: EmojiShortcut
    let onEdit: () -> Void
    let onToggleEnabled: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(shortcut.emoji)
                .font(.title2)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(":\(shortcut.alias):")
                    .font(.body.monospaced())
                Text(shortcut.isEnabled ? "Enabled" : "Disabled")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Menu("Shortcut actions", systemImage: "ellipsis.circle") {
                Button("Edit", systemImage: "pencil", action: onEdit)
                Button(
                    shortcut.isEnabled ? "Disable" : "Enable",
                    systemImage: shortcut.isEnabled ? "pause.circle" : "play.circle",
                    action: onToggleEnabled
                )
                Divider()
                Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
            }
            .accessibilityLabel("Actions for :\(shortcut.alias):")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Shortcut :\(shortcut.alias):, \(shortcut.emoji), \(shortcut.isEnabled ? "enabled" : "disabled")")
    }
}

// Preview-only examples for shortcut-row states.
#Preview("Enabled") {
    EmojiShortcutRow(
        shortcut: EmojiShortcut(alias: "skull", emoji: "💀"),
        onEdit: {},
        onToggleEnabled: {},
        onDelete: {}
    )
    .padding()
}

#Preview("Disabled") {
    EmojiShortcutRow(
        shortcut: EmojiShortcut(alias: "party", emoji: "🎉", isEnabled: false),
        onEdit: {},
        onToggleEnabled: {},
        onDelete: {}
    )
    .padding()
}
