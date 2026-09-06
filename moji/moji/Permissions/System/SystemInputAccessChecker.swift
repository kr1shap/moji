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

// MARK: Mock input access checker for preview
struct PreviewInputAccessChecker: InputAccessChecking {
    let previewStatus: InputAccessStatus

    init(status: InputAccessStatus) {
        previewStatus = status
    }

    func status() -> InputAccessStatus {
        previewStatus
    }

    func requestListeningAccess() {}

    func requestPostingAccess() {}
}
