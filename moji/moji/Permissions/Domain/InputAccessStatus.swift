struct InputAccessStatus: Equatable {
    let isAccessibilityGranted: Bool

    var isGranted: Bool {
        isAccessibilityGranted
    }
}
