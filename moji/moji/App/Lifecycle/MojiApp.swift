//
//  MojiApp.swift
//  moji
//
import SwiftUI
import Combine

@main
struct MojiApp: App {
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        MenuBarExtra("Moji", image: "mojimenuIcon") {
            MenuBarView()
                .environment(coordinator)
                .task { coordinator.start() }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                    coordinator.refreshInputAccess()
                }
        }
        .menuBarExtraStyle(.window)

        Window("Manage Shortcuts", id: AppWindow.shortcutManagementID) {
            ShortcutManagementView()
                .environment(coordinator)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 440, height: 400)
    }
}
