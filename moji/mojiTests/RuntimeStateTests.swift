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
}
