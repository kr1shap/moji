//
//  RuntimeState.swift
//  moji
//

enum RuntimeState: Equatable {
    case disabled
    case permissionRequired
    case active
    case error(String)

    var title: String {
        switch self {
        case .disabled: "Disabled"
        case .permissionRequired: "Permission Required"
        case .active: "Active"
        case .error: "Needs Attention"
        }
    }

    var systemImage: String {
        switch self {
        case .disabled: "pause.circle"
        case .permissionRequired: "lock.circle"
        case .active: "checkmark.circle"
        case .error: "exclamationmark.triangle"
        }
    }

    var isError: Bool {
        if case .error = self {
            true
        } else {
            false
        }
    }
}
