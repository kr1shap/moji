import SwiftData
import Testing
@testable import moji

@MainActor
struct AppCoordinatorTests {
    @Test func coordinatorRetainsItsModelContainerForLaterRefreshes() throws {
        let coordinator = try makeCoordinator()

        coordinator.start()

        #expect(coordinator.runtimeState == .disabled)
    }

    private func makeCoordinator() throws -> AppCoordinator {
        let container = try ModelContainerFactory.makeInMemory()
        return AppCoordinator(
            modelContainer: container,
            preferences: PreferencesStore(defaults: .standard)
        )
    }
}
