import CoreGraphics

struct SystemInputAccessChecker: InputAccessChecking {
    func status() -> InputAccessStatus {
        InputAccessStatus(
            canListen: CGPreflightListenEventAccess(),
            canPost: CGPreflightPostEventAccess()
        )
    }

    func requestListeningAccess() {
        CGRequestListenEventAccess()
    }

    func requestPostingAccess() {
        CGRequestPostEventAccess()
    }
}
