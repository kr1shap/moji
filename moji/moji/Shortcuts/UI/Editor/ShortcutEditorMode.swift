import SwiftData

enum ShortcutEditorMode: Identifiable {
    case add
    case edit(EmojiShortcut)

    var title: String {
        switch self {
        case .add:
            "Add Shortcut"
        case .edit:
            "Edit Shortcut"
        }
    }

    var shortcut: EmojiShortcut? {
        switch self {
        case .add:
            nil
        case let .edit(shortcut):
            shortcut
        }
    }

    var id: String {
        switch self {
        case .add:
            "add"
        case let .edit(shortcut):
            "edit-\(shortcut.persistentModelID)"
        }
    }
}
