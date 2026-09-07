import SwiftUI

struct PermissionStatusView: View {
    let status: InputAccessStatus
    let requestAccessibilityAccess: () -> Void

    var body: some View {
        if !status.isGranted {
            VStack(alignment: .leading, spacing: 6) {
                Text("we need some permissions…")
                    .font(.header)

                PermissionStatusButton(requestAccess: requestAccessibilityAccess)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Moji permissions")
        }
    }
}

private struct PermissionStatusButton: View {
    let requestAccess: () -> Void

    var body: some View {
        Button(action: requestAccess) {
            HStack(spacing: 6) {
                Rectangle()
                    .fill(.orange)
                    .frame(width: 15, height: 15)
                    .clipShape(.rect(cornerRadius: 3))
                    .rotationEffect(.radians(1.10))
                    .accessibilityHidden(true)
                Text("accessibility")
                    .font(.label)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Allow accessibility")
        .accessibilityHint("Requests Accessibility access from macOS")
    }
}

// Preview-only examples for permission states.
#Preview("Required") {
    PermissionStatusView(
        status: InputAccessStatus(isAccessibilityGranted: false),
        requestAccessibilityAccess: {}
    )
    .padding()
}

#Preview("Granted") {
    PermissionStatusView(
        status: InputAccessStatus(isAccessibilityGranted: true),
        requestAccessibilityAccess: {}
    )
    .padding()
}
