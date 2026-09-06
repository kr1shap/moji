import Carbon.HIToolbox
import CoreGraphics

struct CGEventPoster: EventPoster {
    func postBackspaces(count: Int) throws {
        for _ in 0 ..< count {
            try postKey(CGKeyCode(kVK_Delete), flags: [])
        }
    }

    func postPaste() throws {
        try postKey(CGKeyCode(kVK_ANSI_V), flags: .maskCommand)
    }

    private func postKey(_ keyCode: CGKeyCode, flags: CGEventFlags) throws {
        guard let source = CGEventSource(stateID: .combinedSessionState),
              let downEvent = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let upEvent = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            throw ReplacementError.eventPostingFailed
        }
        source.userData = MojiEventSource.userData
        downEvent.flags = flags
        upEvent.flags = flags
        downEvent.post(tap: .cghidEventTap)
        upEvent.post(tap: .cghidEventTap)
    }
}
