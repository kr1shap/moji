enum ShortcodeDecision: Equatable {
    case passThrough
    case resetAndPassThrough
    case replace(emoji: String, deletionCount: Int)
}
