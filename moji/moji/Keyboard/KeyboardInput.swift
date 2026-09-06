enum KeyboardInput: Equatable {
    case character(Character)
    case backspace
    case escape
    case returnKey
    case tab
    case navigation
    case unsupportedModifiers
    case timeout
}
