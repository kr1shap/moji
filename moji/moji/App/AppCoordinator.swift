//
//  AppCoordinator.swift
//  moji
//
import AppKit
import Observation

@MainActor
@Observable
final class AppCoordinator {
    private(set) var runtimeState: RuntimeState

    init(runtimeState: RuntimeState = .disabled) {
        self.runtimeState = runtimeState
    }

    func start() {
        runtimeState = .disabled
    }

    func stop() {
        runtimeState = .disabled
    }

    func terminate() {
        NSApplication.shared.terminate(nil)
    }
}
