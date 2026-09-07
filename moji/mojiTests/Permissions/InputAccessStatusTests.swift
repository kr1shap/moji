import Testing
@testable import moji

struct InputAccessStatusTests {
    @Test func accessRequiresAccessibilityPermission() {
        #expect(InputAccessStatus(isAccessibilityGranted: true).isGranted)
        #expect(!InputAccessStatus(isAccessibilityGranted: false).isGranted)
    }
}
