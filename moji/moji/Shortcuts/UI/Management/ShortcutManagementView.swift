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
            HStack {
                Text("Shortcuts")
                    .font(.title2)
                Spacer()
                Button("Add Shortcut", systemImage: "plus") {
                    editorMode = .add
                }
                .accessibilityIdentifier("addShortcutButton")
            }
            .padding()

            Group {
                if coordinator.repository.shortcuts.isEmpty {
                    ContentUnavailableView(
                        "No Shortcuts",
                        systemImage: "face.smiling",
                        description: Text("Add a shortcut to replace a typed alias with an emoji.")
                    )
                } else {
                    List {
                        ForEach(coordinator.repository.shortcuts, id: \.persistentModelID) { shortcut in
                            EmojiShortcutRow(
                                shortcut: shortcut,
                                onEdit: { editorMode = .edit(shortcut) },
                                onToggleEnabled: { updateEnabledState(for: shortcut) },
                                onDelete: { confirmDeletion(of: shortcut) }
                            )
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .frame(minHeight: 240)

            Divider()

            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
        }
        .frame(minWidth: 440, minHeight: 400)
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
