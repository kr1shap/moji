import SwiftData
import Testing
@testable import moji

@MainActor
struct EmojiShortcutRepositoryTests {
    @Test func createNormalizesAliasAndPublishesEnabledShortcut() throws {
        let repository = try makeRepository()

        let shortcut = try repository.create(alias: "  Skull  ", emoji: "💀")

        #expect(shortcut.alias == "skull")
        #expect(repository.shortcuts.map(\.alias) == ["skull"])
        #expect(repository.runtimeIndex == ["skull": "💀"])
    }

    @Test func createRejectsDuplicateAliasesAfterNormalization() throws {
        let repository = try makeRepository()
        _ = try repository.create(alias: "skull", emoji: "💀")

        #expect(throws: EmojiShortcutValidationError.duplicateAlias) {
            try repository.create(alias: " SKULL ", emoji: "☠️")
        }
    }

    @Test func createRejectsUnsupportedAliasCharacters() throws {
        let repository = try makeRepository()

        #expect(throws: EmojiShortcutValidationError.invalidAliasCharacters) {
            try repository.create(alias: "skull face", emoji: "💀")
        }
    }

    @Test func createAcceptsThirtyTwoCharacterAliasesAndRejectsLongerAliases() throws {
        let repository = try makeRepository()
        let maximumLengthAlias = String(repeating: "a", count: 32)
        let longAlias = String(repeating: "a", count: 33)

        let shortcut = try repository.create(alias: maximumLengthAlias, emoji: "💀")

        #expect(shortcut.alias == maximumLengthAlias)

        #expect(throws: EmojiShortcutValidationError.aliasTooLong) {
            try repository.create(alias: longAlias, emoji: "💀")
        }
    }

    @Test func createRejectsEmptyEmojiValues() throws {
        let repository = try makeRepository()

        #expect(throws: EmojiShortcutValidationError.emptyEmoji) {
            try repository.create(alias: "skull", emoji: "   ")
        }
    }

    @Test func updatePersistsChangesAndRefreshesRuntimeIndex() throws {
        let repository = try makeRepository()
        let shortcut = try repository.create(alias: "skull", emoji: "💀")

        try repository.update(shortcut, alias: "bones", emoji: "🦴")

        #expect(shortcut.alias == "bones")
        #expect(shortcut.emoji == "🦴")
        #expect(repository.runtimeIndex == ["bones": "🦴"])
    }

    @Test func disabledShortcutIsExcludedFromRuntimeIndex() throws {
        let repository = try makeRepository()
        let shortcut = try repository.create(alias: "skull", emoji: "💀")

        try repository.setEnabled(false, for: shortcut)

        #expect(shortcut.isEnabled == false)
        #expect(repository.runtimeIndex.isEmpty)
    }

    @Test func deleteRemovesShortcutFromStoreAndRuntimeIndex() throws {
        let repository = try makeRepository()
        let shortcut = try repository.create(alias: "skull", emoji: "💀")

        try repository.delete(shortcut)

        #expect(repository.shortcuts.isEmpty)
        #expect(repository.runtimeIndex.isEmpty)
    }

    @Test func aNewRepositoryLoadsPersistedShortcutsFromTheSameContainer() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let firstRepository = EmojiShortcutRepository(modelContext: container.mainContext)
        _ = try firstRepository.create(alias: "skull", emoji: "💀")

        let secondRepository = EmojiShortcutRepository(modelContext: container.mainContext)

        #expect(secondRepository.shortcuts.map(\.alias) == ["skull"])
        #expect(secondRepository.runtimeIndex == ["skull": "💀"])
    }

    private func makeRepository() throws -> EmojiShortcutRepository {
        let container = try ModelContainerFactory.makeInMemory()
        return EmojiShortcutRepository(modelContext: container.mainContext)
    }
}
