//
//  RuntimeStateTests.swift
//  mojiTests
//

import Testing
@testable import moji

struct RuntimeStateTests {
    @Test func disabledStateHasExpectedPresentation() {
        #expect(RuntimeState.disabled.title == "Disabled")
        #expect(RuntimeState.disabled.systemImage == "pause.circle")
    }

    @Test func statesExposeShortMenuLabels() {
        #expect(RuntimeState.disabled.menuLabel == "disabled")
        #expect(RuntimeState.permissionRequired.menuLabel == "permissions")
        #expect(RuntimeState.active.menuLabel == "active")
        #expect(RuntimeState.error("Example").menuLabel == "error")
    }
}
