import SwiftData

enum ModelContainerFactory {
    static func makePersistent() -> ModelContainer {
        do {
            return try ModelContainer(for: EmojiShortcut.self)
        } catch {
            fatalError("Unable to create Moji's shortcut store: \(error.localizedDescription)")
        }
    }

    static func makeInMemory() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: EmojiShortcut.self, configurations: configuration)
    }
}
