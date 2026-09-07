@preconcurrency import ApplicationServices

struct SystemInputAccessChecker: InputAccessChecking {
    func status() -> InputAccessStatus {
        InputAccessStatus(isAccessibilityGranted: AXIsProcessTrusted())
    }

    func requestAccessibilityAccess() {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
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

    func requestAccessibilityAccess() {}
}
