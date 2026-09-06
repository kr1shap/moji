import Testing
@testable import moji

struct InputAccessStatusTests {
    @Test func accessRequiresBothListeningAndPostingPrivileges() {
        #expect(InputAccessStatus(canListen: true, canPost: true).isGranted)
        #expect(!InputAccessStatus(canListen: false, canPost: true).isGranted)
        #expect(!InputAccessStatus(canListen: true, canPost: false).isGranted)
        #expect(!InputAccessStatus(canListen: false, canPost: false).isGranted)
    }
}
