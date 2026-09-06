//
//  MojiApp.swift
//  moji
//
import SwiftUI

@main
struct MojiApp: App {
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        MenuBarExtra("Moji", systemImage: "face.smiling") {
            MenuBarView()
                .environment(coordinator)
                .task { coordinator.start() }
        }
        .menuBarExtraStyle(.window)

        Window("Manage Shortcuts", id: AppWindow.shortcutManagementID) {
            ShortcutManagementView()
                .environment(coordinator)
        }
        .defaultSize(width: 440, height: 400)
    }
}
