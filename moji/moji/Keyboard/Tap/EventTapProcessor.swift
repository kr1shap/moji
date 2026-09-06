struct EventTapProcessor {
    private var stateMachine = ShortcodeStateMachine()
    private(set) var replacementRequest: ReplacementRequest?

    mutating func process(
        _ event: NormalizedKeyboardEvent,
        runtimeIndex: [String: String],
        isEnabled: Bool
    ) -> EventDisposition {
        guard isEnabled else {
            stateMachine.reset()
            return .passThrough
        }
        guard !event.isRepeat, !event.isMojiGenerated else {
            return .passThrough
        }

        let input = event.hasUnsupportedModifiers ? KeyboardInput.unsupportedModifiers : event.input
        switch stateMachine.process(input, runtimeIndex: runtimeIndex, isEnabled: true) {
        case .passThrough, .resetAndPassThrough:
            return .passThrough
        case let .replace(emoji, deletionCount):
            replacementRequest = ReplacementRequest(emoji: emoji, deletionCount: deletionCount)
            return .suppress
        }
    }

    mutating func reset() {
        stateMachine.reset()
        replacementRequest = nil
    }

    mutating func takeReplacementRequest() -> ReplacementRequest? {
        defer { replacementRequest = nil }
        return replacementRequest
    }
}
