import Foundation

enum ReplacementError: LocalizedError {
    case pasteboardWriteFailed
    case eventPostingFailed

    var errorDescription: String? {
        switch self {
        case .pasteboardWriteFailed:
            "Moji could not prepare the emoji for insertion."
        case .eventPostingFailed:
            "Moji could not post replacement input."
        }
    }
}
