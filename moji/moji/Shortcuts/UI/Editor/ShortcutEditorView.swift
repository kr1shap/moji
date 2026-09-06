import SwiftUI

struct ShortcutEditorView: View {
    let mode: ShortcutEditorMode
    let onSave: (String, String) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: ShortcutEditorField?
    @State private var alias: String = "skull"
    @State private var emoji: String = ""
    @State private var validationMessage: String?

    init(
        mode: ShortcutEditorMode,
        validationMessage: String? = nil,
        onSave: @escaping (String, String) throws -> Void
    ) {
        self.mode = mode
        self.onSave = onSave
        _alias = State(initialValue: mode.shortcut?.alias ?? "")
        _emoji = State(initialValue: mode.shortcut?.emoji ?? "")
        _validationMessage = State(initialValue: validationMessage)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(mode.title)
                .font(.title2)

            Form {
                TextField("Shortcut name", text: $alias, prompt: Text("skull"))
                    .focused($focusedField, equals: .alias)
                    .accessibilityHint("Use letters, numbers, underscores, hyphens, or plus signs. Colons are added automatically.")
                    .accessibilityIdentifier("shortcutAliasField")

                TextField("Emoji", text: $emoji, prompt: Text(""))
                    .focused($focusedField, equals: .emoji)
                    .accessibilityIdentifier("shortcutEmojiField")

                if let validationMessage {
                    Label(validationMessage, systemImage: "exclamationmark.triangle")
                        .font(.callout)
                        .foregroundStyle(.red)
                        .accessibilityLabel("Validation error: \(validationMessage)")
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .accessibilityIdentifier("cancelShortcutButton")

                Spacer()

                Button("Save", systemImage: "checkmark", action: save)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityHint("Saves this shortcut")
                    .accessibilityIdentifier("saveShortcutButton")
            }
        }
        .padding()
        .frame(width: 360)
        .onAppear {
            focusedField = mode.shortcut == nil ? .alias : .emoji
        }
        .onChange(of: alias) {
            validationMessage = nil
        }
        .onChange(of: emoji) {
            validationMessage = nil
        }
    }

    private func save() {
        do {
            try onSave(alias, emoji)
            dismiss()
        } catch let error as LocalizedError {
            validationMessage = error.errorDescription ?? "Moji could not save this shortcut."
        } catch {
            validationMessage = "Moji could not save this shortcut."
        }
    }
}

// Preview-only examples for editor modes and validation states.
#Preview("Add") {
    ShortcutEditorView(mode: .add) { _, _ in }
}

#Preview("Validation Error") {
    ShortcutEditorView(
        mode: .add,
        validationMessage: EmojiShortcutValidationError.invalidAliasCharacters.errorDescription
    ) { _, _ in }
}

#Preview("Edit") {
    ShortcutEditorView(
        mode: .edit(EmojiShortcut(alias: "skull", emoji: "💀"))
    ) { _, _ in }
}
