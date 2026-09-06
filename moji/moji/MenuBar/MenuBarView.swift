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
        .environment(AppCoordinator(runtimeState: .permissionRequired))
}

#Preview("Active") {
    MenuBarView()
        .environment(AppCoordinator(runtimeState: .active))
}

#Preview("Error") {
    MenuBarView()
        .environment(AppCoordinator(runtimeState: .error("Moji could not start.")))
}
