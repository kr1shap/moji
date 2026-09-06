import SwiftUI

struct PermissionStatusView: View {
    let status: InputAccessStatus
    let requestListeningAccess: () -> Void
    let requestPostingAccess: () -> Void

    var body: some View {
        if !status.isGranted {
            VStack(alignment: .leading, spacing: 8) {
                Label("Permissions Required", systemImage: "lock.circle")
                    .font(.headline)
                Text("Moji needs Input Monitoring to observe shortcuts and Accessibility to post replacement input.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                if !status.canListen {
                    Button("Allow Input Monitoring", systemImage: "keyboard", action: requestListeningAccess)
                }
                if !status.canPost {
                    Button("Allow Accessibility", systemImage: "accessibility", action: requestPostingAccess)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Moji permissions")
        }
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
