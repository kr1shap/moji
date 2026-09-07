import SwiftUI

struct ShortcutManagementView: View {
    @Environment(AppCoordinator.self) private var coordinator

    @Environment(\.dismiss) private var dismiss
    @State private var editorMode: ShortcutEditorMode?
    @State private var shortcutPendingDeletion: EmojiShortcut?
    @State private var isDeleteConfirmationPresented = false
    @State private var errorMessage = ""
    @State private var isErrorPresented = false

    var body: some View {
        VStack(spacing: 0) {
            header
            shortcutContent
            footer
        }
        .padding(15)
        .frame(width: 440)
        .frame(minHeight: 350)
        .sheet(item: $editorMode) { mode in
            ShortcutEditorView(mode: mode, onSave: saveShortcut)
        }
        .confirmationDialog(
            "Delete Shortcut?",
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: deleteShortcut)
            Button("Cancel", role: .cancel) {}
        } message: {
            if let shortcutPendingDeletion {
                Text("This removes :\(shortcutPendingDeletion.alias): from Moji.")
            }
        }
        .alert("Couldn’t Update Shortcuts", isPresented: $isErrorPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Shortcut management")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 4) {
            Image("moji")
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text("shortcuts")
                    .font(.appTitle)
                Text("the phrases you use the most.")
                    .font(.bodyText)
            }
            .padding(.top, 5)

            Spacer(minLength: 4)
            MojiActionButton("add", action: { editorMode = .add })
                .padding(.top, 1)
                .accessibilityLabel("Add shortcut")
                .accessibilityIdentifier("addShortcutButton")
        }
    }

    @ViewBuilder
    private var shortcutContent: some View {
        if coordinator.repository.shortcuts.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 24))
                Text("no shortcuts yet")
                    .font(.header)
                Text("add one to replace a typed alias with an emoji.")
                    .font(.bodyText)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 210)
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(coordinator.repository.shortcuts, id: \.persistentModelID) { shortcut in
                        EmojiShortcutRow(
                            shortcut: shortcut,
                            onEdit: { editorMode = .edit(shortcut) },
                            onToggleEnabled: { updateEnabledState(for: shortcut) },
                            onDelete: { confirmDeletion(of: shortcut) }
                        )
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(minHeight: 210)
            .padding(.top, 14)
        }
    }

    private var footer: some View {
        HStack(alignment: .bottom, spacing: 4) {
            Text("\(coordinator.repository.shortcuts.count) configured")
                .font(.bodyText)
                .foregroundStyle(.secondary)
            Spacer(minLength: 4)
            MojiActionButton("done", action: dismiss.callAsFunction)
                .accessibilityIdentifier("doneButton")
        }
        .padding(.top, 10)
    }

    private func saveShortcut(alias: String, emoji: String) throws {
        switch editorMode {
        case .add:
            _ = try coordinator.createShortcut(alias: alias, emoji: emoji)
        case let .edit(shortcut):
            try coordinator.updateShortcut(shortcut, alias: alias, emoji: emoji)
        case nil:
            return
        }
    }

    private func updateEnabledState(for shortcut: EmojiShortcut) {
        do {
            try coordinator.setShortcutEnabled(!shortcut.isEnabled, for: shortcut)
        } catch {
            present(error)
        }
    }

    private func confirmDeletion(of shortcut: EmojiShortcut) {
        shortcutPendingDeletion = shortcut
        isDeleteConfirmationPresented = true
    }

    private func deleteShortcut() {
        guard let shortcutPendingDeletion else { return }
        do {
            try coordinator.deleteShortcut(shortcutPendingDeletion)
        } catch {
            present(error)
        }
        self.shortcutPendingDeletion = nil
    }

    private func present(_ error: Error) {
        errorMessage = (error as? LocalizedError)?.errorDescription ?? "Moji could not complete that change."
        isErrorPresented = true
    }
}

// Preview-only examples for management-screen data states.
#Preview("Empty") {
    ShortcutManagementView()
        .environment(AppCoordinator.preview())
}

#Preview("Populated") {
    ShortcutManagementView()
        .environment(AppCoordinator.preview(shortcuts: [
            ("skull", "💀", true),
            ("party", "🎉", false)
        ]))
}
