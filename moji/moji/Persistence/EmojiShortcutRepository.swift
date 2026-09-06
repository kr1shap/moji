import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class EmojiShortcutRepository {
    private(set) var shortcuts: [EmojiShortcut] = []
    private(set) var runtimeIndex: [String: String] = [:]

    @ObservationIgnored private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        try? refresh()
    }

    @discardableResult
    func create(alias: String, emoji: String) throws -> EmojiShortcut {
        let normalizedAlias = try normalizedAlias(from: alias)
        try validateEmoji(emoji)
        try ensureAliasIsAvailable(normalizedAlias)

        let shortcut = EmojiShortcut(alias: normalizedAlias, emoji: emoji.trimmingCharacters(in: .whitespacesAndNewlines))
        modelContext.insert(shortcut)
        try saveAndRefresh()
        return shortcut
    }

    func update(_ shortcut: EmojiShortcut, alias: String, emoji: String) throws {
        let normalizedAlias = try normalizedAlias(from: alias)
        try validateEmoji(emoji)
        try ensureAliasIsAvailable(normalizedAlias, excluding: shortcut)

        shortcut.alias = normalizedAlias
        shortcut.emoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        shortcut.updatedAt = .now
        try saveAndRefresh()
    }

    func delete(_ shortcut: EmojiShortcut) throws {
        modelContext.delete(shortcut)
        try saveAndRefresh()
    }

    func setEnabled(_ isEnabled: Bool, for shortcut: EmojiShortcut) throws {
        shortcut.isEnabled = isEnabled
        shortcut.updatedAt = .now
        try saveAndRefresh()
    }

    func refresh() throws {
        let descriptor = FetchDescriptor<EmojiShortcut>(sortBy: [SortDescriptor(\.alias)])
        shortcuts = try modelContext.fetch(descriptor)
        runtimeIndex = Dictionary(
            uniqueKeysWithValues: shortcuts
                .filter(\.isEnabled)
                .map { ($0.alias, $0.emoji) }
        )
    }

    func normalizedAlias(from alias: String) throws -> String {
        let normalizedAlias = alias
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !normalizedAlias.isEmpty else {
            throw EmojiShortcutValidationError.emptyAlias
        }
        guard normalizedAlias.unicodeScalars.count <= ShortcodeStateMachine.maximumAliasLength else {
            throw EmojiShortcutValidationError.aliasTooLong
        }
        guard normalizedAlias.unicodeScalars.allSatisfy(isAllowedAliasScalar) else {
            throw EmojiShortcutValidationError.invalidAliasCharacters
        }
        return normalizedAlias
    }

    private func validateEmoji(_ emoji: String) throws {
        guard !emoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw EmojiShortcutValidationError.emptyEmoji
        }
    }

    private func ensureAliasIsAvailable(_ alias: String, excluding shortcut: EmojiShortcut? = nil) throws {
        let conflictingShortcut = shortcuts.first { candidate in
            guard candidate.alias == alias else { return false }
            guard let shortcut else { return true }
            return candidate.persistentModelID != shortcut.persistentModelID
        }
        guard conflictingShortcut == nil else {
            throw EmojiShortcutValidationError.duplicateAlias
        }
    }

    private func saveAndRefresh() throws {
        try modelContext.save()
        try refresh()
    }

    private func isAllowedAliasScalar(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 48 ... 57, 65 ... 90, 97 ... 122, 43, 45, 95:
            true
        default:
            false
        }
    }
}
