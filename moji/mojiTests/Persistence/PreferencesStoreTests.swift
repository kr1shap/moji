import Foundation
import Testing
@testable import moji

@MainActor
struct PreferencesStoreTests {
    @Test func isEnabledDefaultsToFalseAndPersistsExplicitChanges() {
        let suiteName = "PreferencesStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let preferences = PreferencesStore(defaults: defaults)
        #expect(preferences.isEnabled == false)

        preferences.isEnabled = true

        let reloadedPreferences = PreferencesStore(defaults: defaults)
        #expect(reloadedPreferences.isEnabled == true)
    }
}
