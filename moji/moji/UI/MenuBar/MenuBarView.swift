import SwiftUI

struct MenuBarView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            PermissionStatusView(
                status: coordinator.inputAccess,
                requestListeningAccess: coordinator.requestListeningAccess,
                requestPostingAccess: coordinator.requestPostingAccess
            )
            .padding(.top, coordinator.inputAccess.missingPermissions.isEmpty ? 0 : 6)

            footer
        }
        .padding(15)
        .frame(width: 360, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Moji menu")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 4) {
            Image("moji")
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text("moji")
                    .font(.appTitle)
                Text("an easier text replacer.")
                    .font(.bodyText)
            }
            .padding(.top, 5)

            Spacer(minLength: 4)
            StatusRow(state: coordinator.runtimeState)
                .padding(.top, 1)
        }
    }

    private var footer: some View {
        HStack(alignment: .bottom, spacing: 4) {
            Text("\(coordinator.repository.shortcuts.count) configured")
                .font(.bodyText)
                .foregroundStyle(.secondary)
            Spacer(minLength: 4)
            MojiActionButton("manage", action: openShortcutManagement)
                .accessibilityIdentifier("manageShortcutsButton")
            MojiActionButton("quit", action: coordinator.terminate)
                .accessibilityIdentifier("quitButton")
        }
        .padding(.top, 10)
    }

    private func openShortcutManagement() {
        openWindow(id: AppWindow.shortcutManagementID)
    }
}

// Preview-only examples for menu-bar states.
#Preview("Disabled") {
    MenuBarView()
        .environment(AppCoordinator.preview())
}

#Preview("Permission Required") {
    MenuBarView()
        .environment(AppCoordinator.preview(runtimeState: .permissionRequired, isEnabled: true))
}

#Preview("Active") {
    MenuBarView()
        .environment(AppCoordinator.preview(
            runtimeState: .active,
            inputAccess: InputAccessStatus(canListen: true, canPost: true),
            isEnabled: true
        ))
}

#Preview("Error") {
    MenuBarView()
        .environment(AppCoordinator.preview(runtimeState: .error("Moji could not start.")))
}
