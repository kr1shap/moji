import Foundation

final class ReplacementCoordinator: @unchecked Sendable {
    private let pasteboardManager: PasteboardManager
    private let eventPoster: EventPoster
    private var onFailure: @Sendable () -> Void

    init(
        pasteboardManager: PasteboardManager = PasteboardManager(),
        eventPoster: EventPoster = CGEventPoster(),
        onFailure: @escaping @Sendable () -> Void = {}
    ) {
        self.pasteboardManager = pasteboardManager
        self.eventPoster = eventPoster
        self.onFailure = onFailure
    }

    func setFailureHandler(_ onFailure: @escaping @Sendable () -> Void) {
        self.onFailure = onFailure
    }

    func replace(_ request: ReplacementRequest) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let temporaryWrite = try pasteboardManager.writeTemporarily(request.emoji)
                try eventPoster.postBackspaces(count: request.deletionCount)
                try eventPoster.postPaste()
                try await Task.sleep(for: .milliseconds(150))
                pasteboardManager.restore(temporaryWrite)
            } catch {
                onFailure()
            }
        }
    }
}
