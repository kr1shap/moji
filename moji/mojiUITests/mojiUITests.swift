//
//  mojiUITests.swift
//  mojiUITests
//
//  Created by Krisha Patel on 2026-09-05.
//

import XCTest

final class mojiUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testLaunchesWithoutPrimaryWindow() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertEqual(app.windows.count, 0)
    }

    @MainActor
    func testMenuPanelCanOpenShortcutEditor() throws {
        let app = XCUIApplication()
        app.launch()

        let statusItem = app.menuBars.statusItems["Moji"]
        XCTAssertTrue(statusItem.waitForExistence(timeout: 5))
        statusItem.click()

        let manageButton = app.buttons["manageShortcutsButton"]
        XCTAssertTrue(manageButton.waitForExistence(timeout: 5))
        manageButton.click()

        let addButton = app.buttons["addShortcutButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.click()

        XCTAssertTrue(app.textFields["shortcutAliasField"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["shortcutEmojiField"].exists)
        XCTAssertTrue(app.buttons["saveShortcutButton"].exists)
        XCTAssertTrue(app.buttons["cancelShortcutButton"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
