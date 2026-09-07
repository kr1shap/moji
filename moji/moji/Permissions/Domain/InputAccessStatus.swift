struct InputAccessStatus: Equatable {
    let canListen: Bool
    let canPost: Bool

    var isGranted: Bool {
        canListen && canPost
    }

    var missingPermissions: [InputPermission] {
        var permissions: [InputPermission] = []
        if !canListen {
            permissions.append(.inputMonitoring)
        }
        if !canPost {
            permissions.append(.accessibility)
        }
        return permissions
    }
}

enum InputPermission: Hashable {
    case inputMonitoring
    case accessibility

    var title: String {
        switch self {
        case .inputMonitoring: "input monitoring"
        case .accessibility: "accessibility"
        }
    }

}
