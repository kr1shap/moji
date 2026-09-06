protocol InputAccessChecking {
    func status() -> InputAccessStatus
    func requestListeningAccess()
    func requestPostingAccess()
}
