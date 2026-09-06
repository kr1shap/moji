struct ShortcodeStateMachine {
    static let maximumAliasLength = 32

    private var capturedAlias: String?

    mutating func process(
        _ input: KeyboardInput,
        runtimeIndex: [String: String],
        isEnabled: Bool
    ) -> ShortcodeDecision {
        guard isEnabled else {
            return resetIfCapturing()
        }

        return switch input {
        case let .character(character):
            process(character: character, runtimeIndex: runtimeIndex)
        case .backspace:
            processBackspace()
        case .escape, .returnKey, .tab, .navigation, .unsupportedModifiers, .timeout:
            resetIfCapturing()
        }
    }

    mutating func reset() {
        capturedAlias = nil
    }

    private mutating func process(
        character: Character,
        runtimeIndex: [String: String]
    ) -> ShortcodeDecision {
        guard var alias = capturedAlias else {
            if character == ":" {
                capturedAlias = ""
            }
            return .passThrough
        }

        if character == ":" {
            guard !alias.isEmpty else {
                capturedAlias = ""
                return .passThrough
            }

            defer { reset() }
            guard let emoji = runtimeIndex[alias] else {
                return .resetAndPassThrough
            }
            return .replace(emoji: emoji, deletionCount: alias.unicodeScalars.count + 1)
        }

        let normalizedCharacter = String(character).lowercased()
        guard normalizedCharacter.unicodeScalars.allSatisfy(isAllowedAliasScalar) else {
            reset()
            return .resetAndPassThrough
        }

        alias.append(contentsOf: normalizedCharacter)
        guard alias.unicodeScalars.count <= Self.maximumAliasLength else {
            reset()
            return .resetAndPassThrough
        }

        capturedAlias = alias
        return .passThrough
    }

    private mutating func processBackspace() -> ShortcodeDecision {
        guard var alias = capturedAlias else {
            return .passThrough
        }
        guard !alias.isEmpty else {
            reset()
            return .passThrough
        }

        alias.removeLast()
        capturedAlias = alias
        return .passThrough
    }

    private mutating func resetIfCapturing() -> ShortcodeDecision {
        guard capturedAlias != nil else {
            return .passThrough
        }
        reset()
        return .resetAndPassThrough
    }

    private func isAllowedAliasScalar(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 48 ... 57, 65 ... 90, 97 ... 122, 43, 45, 95:
            true
        default:
            false
        }
    }
}
