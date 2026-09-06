import AppKit

final class PasteboardManager: @unchecked Sendable {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    func writeTemporarily(_ emoji: String) throws -> PasteboardTemporaryWrite {
        let snapshot = PasteboardSnapshot(items: pasteboard.pasteboardItems?.map(copyItem) ?? [])
        guard pasteboard.clearContents() > 0, pasteboard.setString(emoji, forType: .string) else {
            throw ReplacementError.pasteboardWriteFailed
        }
        return PasteboardTemporaryWrite(snapshot: snapshot, changeCount: pasteboard.changeCount)
    }

    func restore(_ temporaryWrite: PasteboardTemporaryWrite) {
        guard pasteboard.changeCount == temporaryWrite.changeCount else { return }
        pasteboard.clearContents()
        pasteboard.writeObjects(temporaryWrite.snapshot.items)
    }

    private func copyItem(_ item: NSPasteboardItem) -> NSPasteboardItem {
        let copy = NSPasteboardItem()
        for type in item.types {
            if let data = item.data(forType: type) {
                copy.setData(data, forType: type)
            }
        }
        return copy
    }
}
