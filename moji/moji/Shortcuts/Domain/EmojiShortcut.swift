import Foundation
import SwiftData

@Model
final class EmojiShortcut {
    @Attribute(.unique) var alias: String
    var emoji: String
    var createdAt: Date
    var updatedAt: Date
    var isEnabled: Bool

    init(alias: String, emoji: String, isEnabled: Bool = true) {
        self.alias = alias
        self.emoji = emoji
        self.createdAt = .now
        self.updatedAt = .now
        self.isEnabled = isEnabled
    }
}
