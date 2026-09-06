//
//  MenuBarView.swift
//  moji
//
import SwiftUI

struct MenuBarView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Moji", systemImage: "face.smiling")
                .font(.headline)
            StatusRow(state: coordinator.runtimeState)
            Divider()
            Text("Shortcut management arrives in the next milestone.")
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
}

#Preview("Disabled") {
    MenuBarView()
        .environment(AppCoordinator())
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
