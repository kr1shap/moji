import SwiftUI

struct PermissionStatusView: View {
    let status: InputAccessStatus
    let requestListeningAccess: () -> Void
    let requestPostingAccess: () -> Void

    var body: some View {
        if !status.missingPermissions.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("we need some permissions…")
                    .font(.header)

                HStack(spacing: 10) {
                    ForEach(status.missingPermissions, id: \.self) { permission in
                        PermissionStatusButton(
                            permission: permission,
                            requestAccess: { requestAccess(for: permission) }
                        )
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Moji permissions")
        }
    }

    private func requestAccess(for permission: InputPermission) {
        switch permission {
        case .inputMonitoring:
            requestListeningAccess()
        case .accessibility:
            requestPostingAccess()
        }
    }
}

private struct PermissionStatusButton: View {
    let permission: InputPermission
    let requestAccess: () -> Void

    var body: some View {
        Button(action: requestAccess) {
            HStack(spacing: 6) {
                Rectangle()
                    .fill(.orange)
                    .frame(width: 17, height: 17)
                    .clipShape(.rect(cornerRadius: 3))
                    .rotationEffect(.radians(1.10))
                    .accessibilityHidden(true)
                Text(permission.title)
                    .font(.label)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Allow \(permission.title)")
        .accessibilityHint("Opens the system permission prompt")
    }
}

// Preview-only examples for permission states.
#Preview("Required") {
    PermissionStatusView(
        status: InputAccessStatus(canListen: false, canPost: false),
        requestListeningAccess: {},
        requestPostingAccess: {}
    )
    .padding()
}

#Preview("Granted") {
    PermissionStatusView(
        status: InputAccessStatus(canListen: true, canPost: true),
        requestListeningAccess: {},
        requestPostingAccess: {}
    )
    .padding()
}
