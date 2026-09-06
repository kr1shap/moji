//
//  MenuBarView.swift
//  moji
//
import SwiftUI

struct MenuBarView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Moji", systemImage: "face.smiling")
                .font(.headline)
            StatusRow(state: coordinator.runtimeState)
            Divider()
            PermissionStatusView(
                status: coordinator.inputAccess,
                requestListeningAccess: coordinator.requestListeningAccess,
                requestPostingAccess: coordinator.requestPostingAccess
            )
            Button(
                coordinator.preferences.isEnabled ? "Disable Moji" : "Enable Moji",
                systemImage: coordinator.preferences.isEnabled ? "pause.circle" : "play.circle"
            ) {
                coordinator.setEnabled(!coordinator.preferences.isEnabled)
            }
            .accessibilityIdentifier("enabledButton")
            .accessibilityValue(coordinator.preferences.isEnabled ? "Enabled" : "Disabled")
            if coordinator.runtimeState == .permissionRequired || coordinator.runtimeState.isError {
                Button("Retry", systemImage: "arrow.clockwise", action: coordinator.refreshInputAccess)
                    .accessibilityIdentifier("retryButton")
            }
            Button(
                "Manage Shortcuts",
                systemImage: "list.bullet",
                action: openShortcutManagement
            )
            .accessibilityIdentifier("manageShortcutsButton")
            Text("\(coordinator.repository.shortcuts.count) configured")
                .font(.callout)
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Quit", systemImage: "power", action: coordinator.terminate)
                    .accessibilityIdentifier("quitButton")
            }
        }
        .padding()
        .frame(width: 320)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Moji menu")
    }

    private func openShortcutManagement() {
        openWindow(id: AppWindow.shortcutManagementID)
    }
}

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
