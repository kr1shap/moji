import Foundation
import Observation

@MainActor
@Observable
final class ShortcutManagementViewModel {
    var presentedSheet: ShortcutManagementSheet?
    var isDeleteConfirmationPresented = false
    var isFileImporterPresented = false
    private(set) var isPreparingImport = false
    private(set) var shortcutPendingDeletion: EmojiShortcut?
    private(set) var activeAlert: ShortcutManagementAlert?

    var isAlertPresented: Bool {
        get { activeAlert != nil }
        set {
            if !newValue {
                activeAlert = nil
            }
        }
    }

    func presentAddShortcut() {
        presentedSheet = .editor(.add)
    }

    func presentEditor(for shortcut: EmojiShortcut) {
        presentedSheet = .editor(.edit(shortcut))
    }

    func saveShortcut(alias: String, emoji: String, using coordinator: AppCoordinator) throws {
        guard case let .editor(mode) = presentedSheet else { return }

        switch mode {
        case .add:
            _ = try coordinator.createShortcut(alias: alias, emoji: emoji)
        case let .edit(shortcut):
            try coordinator.updateShortcut(shortcut, alias: alias, emoji: emoji)
        }
    }

    func updateEnabledState(for shortcut: EmojiShortcut, using coordinator: AppCoordinator) {
        do {
            try coordinator.setShortcutEnabled(!shortcut.isEnabled, for: shortcut)
        } catch {
            presentShortcutError(error)
        }
    }

    func confirmDeletion(of shortcut: EmojiShortcut) {
        shortcutPendingDeletion = shortcut
        isDeleteConfirmationPresented = true
    }

    func deletePendingShortcut(using coordinator: AppCoordinator) {
        guard let shortcutPendingDeletion else { return }
        defer { self.shortcutPendingDeletion = nil }

        do {
            try coordinator.deleteShortcut(shortcutPendingDeletion)
        } catch {
            presentShortcutError(error)
        }
    }

    func handleFileSelection(
        _ result: Result<[URL], Error>,
        using coordinator: AppCoordinator
    ) {
        do {
            guard let url = try result.get().first else { return }
            isPreparingImport = true
            Task {
                await prepareImport(from: url, using: coordinator)
            }
        } catch {
            presentFileImportError(error)
        }
    }

    func presentImportResult(_ result: ShortcutImportResult) {
        activeAlert = ShortcutManagementAlert(
            title: "Import Complete",
            message: "Added \(result.addedCount), updated \(result.updatedCount), and skipped \(result.skippedCount)."
        )
    }

    private func prepareImport(from url: URL, using coordinator: AppCoordinator) async {
        defer { isPreparingImport = false }

        do {
            let parsedCSV = try await ShortcutImportFileLoader.loadAndParse(url)
            presentedSheet = .importPreview(coordinator.prepareShortcutImport(parsedCSV))
        } catch {
            presentFileImportError(error)
        }
    }

    private func presentShortcutError(_ error: Error) {
        activeAlert = ShortcutManagementAlert(
            title: "Couldn’t Update Shortcuts",
            message: (error as? LocalizedError)?.errorDescription
                ?? "Moji could not complete that change."
        )
    }

    private func presentFileImportError(_ error: Error) {
        activeAlert = ShortcutManagementAlert(
            title: "Couldn’t Read CSV",
            message: (error as? LocalizedError)?.errorDescription
                ?? "Moji could not read the selected CSV file."
        )
    }
}
