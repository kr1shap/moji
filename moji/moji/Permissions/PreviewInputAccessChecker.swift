import Foundation

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
