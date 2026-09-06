import Foundation
import Observation

@MainActor
@Observable
final class PreferencesStore {
    private enum Key {
        static let isEnabled = "moji.isEnabled"
    }

    var isEnabled: Bool {
        didSet {
            defaults?.set(isEnabled, forKey: Key.isEnabled)
        }
    }

    @ObservationIgnored private let defaults: UserDefaults?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isEnabled = defaults.object(forKey: Key.isEnabled) as? Bool ?? false
    }

    private init(isEnabled: Bool) {
        self.defaults = nil
        self.isEnabled = isEnabled
    }

    // Preview-only helper for constructing in-memory preference state.
    static func preview(isEnabled: Bool = false) -> PreferencesStore {
        PreferencesStore(isEnabled: isEnabled)
    }
}
