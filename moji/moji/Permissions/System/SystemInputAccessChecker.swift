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

// Preview-only input access checker; never used for real permission queries.
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
