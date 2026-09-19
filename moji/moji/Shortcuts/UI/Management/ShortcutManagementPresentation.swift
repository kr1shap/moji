struct ShortcutManagementAlert {
    let title: String
    let message: String
}

enum ShortcutManagementSheet: Identifiable {
    case editor(ShortcutEditorMode)
    case importPreview(ShortcutImportPreview)

    var id: String {
        switch self {
        case let .editor(mode):
            "editor-\(mode.id)"
        case let .importPreview(preview):
            "import-\(preview.id.uuidString)"
        }
    }
}
