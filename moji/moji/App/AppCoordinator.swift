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
    @ObservationIgnored private let accessChecker: any InputAccessChecking
    @ObservationIgnored private let eventTap: GlobalEventTap
    @ObservationIgnored private let replacementCoordinator: ReplacementCoordinator
    private(set) var inputAccess: InputAccessStatus

    convenience init(runtimeState: RuntimeState = .disabled) {
        let container = ModelContainerFactory.makePersistent()
        self.init(
            runtimeState: runtimeState,
            modelContainer: container,
            preferences: PreferencesStore(),
            accessChecker: SystemInputAccessChecker(),
            eventTap: GlobalEventTap()
        )
    }

    init(
        runtimeState: RuntimeState = .disabled,
        modelContainer: ModelContainer,
        preferences: PreferencesStore,
        accessChecker: any InputAccessChecking = SystemInputAccessChecker(),
        eventTap: GlobalEventTap = GlobalEventTap()
    ) {
        self.runtimeState = runtimeState
        self.modelContainer = modelContainer
        self.preferences = preferences
        self.repository = EmojiShortcutRepository(modelContext: modelContainer.mainContext)
        self.accessChecker = accessChecker
        self.eventTap = eventTap
        self.replacementCoordinator = ReplacementCoordinator()
        self.inputAccess = accessChecker.status()
        eventTap.setReplacementHandler { [replacementCoordinator] request in
            replacementCoordinator.replace(request)
        }
        replacementCoordinator.setFailureHandler { [weak self] in
            Task { @MainActor in
                self?.handleReplacementFailure()
            }
        }
    }

    func start() {
        do {
            try repository.refresh()
            refreshInputAccess()
        } catch {
            eventTap.stop()
            runtimeState = .error("Moji could not load saved shortcuts.")
        }
    }

    func stop() {
        eventTap.stop()
        runtimeState = .disabled
    }

    func refreshInputAccess() {
        inputAccess = accessChecker.status()
        guard preferences.isEnabled else {
            eventTap.stop()
            runtimeState = .disabled
            return
        }
        guard inputAccess.isGranted else {
            eventTap.stop()
            runtimeState = .permissionRequired
            return
        }
        eventTap.updateRuntimeIndex(repository.runtimeIndex)
        eventTap.start()
        runtimeState = .active
    }

    func requestListeningAccess() {
        accessChecker.requestListeningAccess()
    }

    func requestPostingAccess() {
        accessChecker.requestPostingAccess()
    }

    func setEnabled(_ isEnabled: Bool) {
        preferences.isEnabled = isEnabled
        refreshInputAccess()
    }

    @discardableResult
    func createShortcut(alias: String, emoji: String) throws -> EmojiShortcut {
        let shortcut = try repository.create(alias: alias, emoji: emoji)
        publishRuntimeIndex()
        return shortcut
    }

    func updateShortcut(_ shortcut: EmojiShortcut, alias: String, emoji: String) throws {
        try repository.update(shortcut, alias: alias, emoji: emoji)
        publishRuntimeIndex()
    }

    func deleteShortcut(_ shortcut: EmojiShortcut) throws {
        try repository.delete(shortcut)
        publishRuntimeIndex()
    }

    func setShortcutEnabled(_ isEnabled: Bool, for shortcut: EmojiShortcut) throws {
        try repository.setEnabled(isEnabled, for: shortcut)
        publishRuntimeIndex()
    }

    private func handleReplacementFailure() {
        eventTap.stop()
        runtimeState = .error("Moji could not replace the shortcut.")
    }

    private func publishRuntimeIndex() {
        eventTap.updateRuntimeIndex(repository.runtimeIndex)
    }

    func terminate() {
        NSApplication.shared.terminate(nil)
    }

    static func preview(
        runtimeState: RuntimeState = .disabled,
        inputAccess: InputAccessStatus = InputAccessStatus(canListen: false, canPost: false),
        isEnabled: Bool = false,
        shortcuts: [(alias: String, emoji: String, isEnabled: Bool)] = []
    ) -> AppCoordinator {
        let container: ModelContainer
        do {
            container = try ModelContainerFactory.makeInMemory()
        } catch {
            fatalError("Unable to create preview shortcut store: \(error.localizedDescription)")
        }

        let coordinator = AppCoordinator(
            runtimeState: runtimeState,
            modelContainer: container,
            preferences: .preview(isEnabled: isEnabled),
            accessChecker: PreviewInputAccessChecker(status: inputAccess)
        )
        for shortcut in shortcuts {
            if let createdShortcut = try? coordinator.repository.create(alias: shortcut.alias, emoji: shortcut.emoji), shortcut.isEnabled == false {
                try? coordinator.repository.setEnabled(false, for: createdShortcut)
            }
        }
        return coordinator
    }
}
