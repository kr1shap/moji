import SwiftUI

struct EmojiShortcutRow: View {
    let shortcut: EmojiShortcut
    let onEdit: () -> Void
    let onToggleEnabled: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(shortcut.emoji)
                .font(.system(size: 24))
                .frame(width: 38, height: 38)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(":\(shortcut.alias):")
                    .font(.header)
                Text(shortcut.isEnabled ? "enabled." : "disabled.")
                    .font(.label)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Menu {
                Button("Edit", systemImage: "pencil", action: onEdit)
                Button(
                    shortcut.isEnabled ? "Disable" : "Enable",
                    systemImage: shortcut.isEnabled ? "pause.circle" : "play.circle",
                    action: onToggleEnabled
                )
                Divider()
                Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
            } label: {
                MojiActionLabel("configure")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .accessibilityLabel("Actions for :\(shortcut.alias):")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
