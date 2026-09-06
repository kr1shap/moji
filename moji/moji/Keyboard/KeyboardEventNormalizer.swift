import Carbon.HIToolbox
import CoreGraphics

struct KeyboardEventNormalizer {
    func normalize(_ event: CGEvent) -> NormalizedKeyboardEvent {
        let flags = event.flags
        let hasUnsupportedModifiers = flags.contains(.maskCommand) || flags.contains(.maskControl) || flags.contains(.maskAlternate)
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let input = specialInput(for: keyCode) ?? characterInput(from: event) ?? .navigation

        return NormalizedKeyboardEvent(
            input: input,
            isRepeat: event.getIntegerValueField(.keyboardEventAutorepeat) != 0,
            isMojiGenerated: MojiEventSource.isGenerated(event),
            hasUnsupportedModifiers: hasUnsupportedModifiers
        )
    }

    private func specialInput(for keyCode: CGKeyCode) -> KeyboardInput? {
        switch Int(keyCode) {
        case Int(kVK_Delete): .backspace
        case Int(kVK_Escape): .escape
        case Int(kVK_Return), Int(kVK_ANSI_KeypadEnter): .returnKey
        case Int(kVK_Tab): .tab
        case Int(kVK_LeftArrow), Int(kVK_RightArrow), Int(kVK_UpArrow), Int(kVK_DownArrow), Int(kVK_Home), Int(kVK_End), Int(kVK_PageUp), Int(kVK_PageDown): .navigation
        default: nil
        }
    }

    private func characterInput(from event: CGEvent) -> KeyboardInput? {
        var actualLength = 0
        var codeUnits = [UniChar](repeating: 0, count: 4)
        event.keyboardGetUnicodeString(
            maxStringLength: codeUnits.count,
            actualStringLength: &actualLength,
            unicodeString: &codeUnits
        )
        let value = String(utf16CodeUnits: codeUnits, count: actualLength)
        guard value.count == 1, let character = value.first else { return nil }
        return .character(character)
    }
}
