struct InputAccessStatus: Equatable {
    let canListen: Bool
    let canPost: Bool

    var isGranted: Bool {
        canListen && canPost
    }
}
