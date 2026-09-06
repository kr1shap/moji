import SwiftData

enum ModelContainerFactory {
    static func makePersistent() -> ModelContainer {
        do {
            return try ModelContainer(for: EmojiShortcut.self)
        } catch {
            fatalError("Unable to create Moji's shortcut store: \(error.localizedDescription)")
        }
    }

    // Preview-only factory for an in-memory model container.
    static func makeInMemory() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: EmojiShortcut.self, configurations: configuration)
    }
}
