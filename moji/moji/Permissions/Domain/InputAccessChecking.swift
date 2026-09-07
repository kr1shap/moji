@MainActor
protocol InputAccessChecking {
    func status() -> InputAccessStatus
    func requestAccessibilityAccess()
}
