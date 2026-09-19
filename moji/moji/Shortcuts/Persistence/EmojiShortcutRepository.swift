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

    func prepareImport(_ result: ShortcutCSVParseResult) -> ShortcutImportPreview {
        var issues = result.issues
        var entriesByAlias: [String: ShortcutImportEntry] = [:]
        var aliasOrder: [String] = []
        var supersededRowCount = 0
        let existingAliases = Set(shortcuts.map(\.alias))

        for row in result.rows {
            do {
                let alias = try normalizedAlias(from: row.alias)
                try validateEmoji(row.emoji)
                let emoji = row.emoji.trimmingCharacters(in: .whitespacesAndNewlines)

                if entriesByAlias[alias] != nil {
                    supersededRowCount += 1
                    aliasOrder.removeAll { $0 == alias }
                }

                entriesByAlias[alias] = ShortcutImportEntry(
                    rowNumber: row.rowNumber,
                    alias: alias,
                    emoji: emoji,
                    action: existingAliases.contains(alias) ? .override : .add
                )
                aliasOrder.append(alias)
            } catch {
                let message = (error as? LocalizedError)?.errorDescription
                    ?? "This row could not be validated."
                issues.append(ShortcutImportIssue(rowNumber: row.rowNumber, message: message))
            }
        }

        let entries = aliasOrder.compactMap { entriesByAlias[$0] }
        return ShortcutImportPreview(
            entries: entries,
            issues: issues.sorted { $0.rowNumber < $1.rowNumber },
            supersededRowCount: supersededRowCount
        )
    }

    func applyImport(_ preview: ShortcutImportPreview) throws -> ShortcutImportResult {
        let existingShortcuts = Dictionary(uniqueKeysWithValues: shortcuts.map { ($0.alias, $0) })
        let updateDate = Date.now
        var importedShortcuts = shortcuts

        for entry in preview.entries {
            if let shortcut = existingShortcuts[entry.alias] {
                shortcut.emoji = entry.emoji
                shortcut.updatedAt = updateDate
            } else {
                let shortcut = EmojiShortcut(alias: entry.alias, emoji: entry.emoji)
                modelContext.insert(shortcut)
                importedShortcuts.append(shortcut)
            }
        }

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            try? refresh()
            throw error
        }
        publish(importedShortcuts)

        return ShortcutImportResult(
            addedCount: preview.addedCount,
            updatedCount: preview.updatedCount,
            skippedCount: preview.skippedCount
        )
    }

    func refresh() throws {
        let descriptor = FetchDescriptor<EmojiShortcut>(sortBy: [SortDescriptor(\.alias)])
        publish(try modelContext.fetch(descriptor))
    }

    private func publish(_ shortcuts: [EmojiShortcut]) {
        self.shortcuts = shortcuts.sorted { $0.alias < $1.alias }
        runtimeIndex = Dictionary(
            uniqueKeysWithValues: self.shortcuts
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
