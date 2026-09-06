//
//  AppCoordinator.swift
//  moji
//
import AppKit
import Observation
import SwiftData

@MainActor
@Observable
final class AppCoordinator {
    private(set) var runtimeState: RuntimeState
    let preferences: PreferencesStore
    let repository: EmojiShortcutRepository
    @ObservationIgnored private let modelContainer: ModelContainer

    convenience init(runtimeState: RuntimeState = .disabled) {
        let container = ModelContainerFactory.makePersistent()
        self.init(
            runtimeState: runtimeState,
            modelContainer: container,
            preferences: PreferencesStore()
        )
    }

    init(
        runtimeState: RuntimeState = .disabled,
        modelContainer: ModelContainer,
        preferences: PreferencesStore
    ) {
        self.runtimeState = runtimeState
        self.modelContainer = modelContainer
        self.preferences = preferences
        self.repository = EmojiShortcutRepository(modelContext: modelContainer.mainContext)
    }

    func start() {
        do {
            try repository.refresh()
            runtimeState = .disabled
        } catch {
            runtimeState = .error("Moji could not load saved shortcuts.")
        }
    }

    func stop() {
        runtimeState = .disabled
    }

    func terminate() {
        NSApplication.shared.terminate(nil)
    }

    static func preview(shortcuts: [(alias: String, emoji: String, isEnabled: Bool)] = []) -> AppCoordinator {
        let container: ModelContainer
        do {
            container = try ModelContainerFactory.makeInMemory()
        } catch {
            fatalError("Unable to create preview shortcut store: \(error.localizedDescription)")
        }

        let coordinator = AppCoordinator(
            modelContainer: container,
            preferences: PreferencesStore()
        )
        for shortcut in shortcuts {
            if let createdShortcut = try? coordinator.repository.create(alias: shortcut.alias, emoji: shortcut.emoji), shortcut.isEnabled == false {
                try? coordinator.repository.setEnabled(false, for: createdShortcut)
            }
        }
        return coordinator
    }
}
