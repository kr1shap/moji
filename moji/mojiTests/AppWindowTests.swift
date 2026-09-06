import Testing
@testable import moji

struct AppWindowTests {
    @Test func shortcutManagementUsesAStableWindowIdentifier() {
        #expect(AppWindow.shortcutManagementID == "shortcut-management")
    }
}
