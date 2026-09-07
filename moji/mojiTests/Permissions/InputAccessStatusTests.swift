import Testing
@testable import moji

struct InputAccessStatusTests {
    @Test func accessRequiresBothListeningAndPostingPrivileges() {
        #expect(InputAccessStatus(canListen: true, canPost: true).isGranted)
        #expect(!InputAccessStatus(canListen: false, canPost: true).isGranted)
        #expect(!InputAccessStatus(canListen: true, canPost: false).isGranted)
        #expect(!InputAccessStatus(canListen: false, canPost: false).isGranted)
    }

    @Test func missingPermissionsListsOnlyPrivilegesThatNeedUserAction() {
        #expect(
            InputAccessStatus(canListen: false, canPost: false).missingPermissions
                == [.inputMonitoring, .accessibility]
        )
        #expect(
            InputAccessStatus(canListen: false, canPost: true).missingPermissions
                == [.inputMonitoring]
        )
        #expect(
            InputAccessStatus(canListen: true, canPost: false).missingPermissions
                == [.accessibility]
        )
        #expect(InputAccessStatus(canListen: true, canPost: true).missingPermissions.isEmpty)
    }
}
