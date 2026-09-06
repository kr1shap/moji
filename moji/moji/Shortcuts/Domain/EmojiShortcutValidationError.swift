import Foundation

enum EmojiShortcutValidationError: LocalizedError, Equatable {
    case emptyAlias
    case aliasTooLong
    case invalidAliasCharacters
    case emptyEmoji
    case duplicateAlias

    var errorDescription: String? {
        switch self {
        case .emptyAlias:
            "Enter a shortcut name."
        case .aliasTooLong:
            "Shortcut names can contain at most 32 characters."
        case .invalidAliasCharacters:
            "Use letters, numbers, underscores, hyphens, or plus signs."
        case .emptyEmoji:
            "Enter an emoji to use for this shortcut."
        case .duplicateAlias:
            "That shortcut name is already in use."
        }
    }
}
