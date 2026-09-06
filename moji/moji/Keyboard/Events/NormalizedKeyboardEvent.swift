struct NormalizedKeyboardEvent: Equatable {
    let input: KeyboardInput
    let isRepeat: Bool
    let isMojiGenerated: Bool
    let hasUnsupportedModifiers: Bool
}
