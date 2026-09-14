import XCTest
@testable import OrbitLab

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testLoadChangeAndFullReset() {
        let store = InMemorySettingsStore()
        let viewModel = AppSettingsViewModel(store: store)

        XCTAssertEqual(viewModel.settings, .defaults)

        viewModel.updateAccentColor(.solarGold)
        viewModel.updateHapticFeedback(false)
        viewModel.updateReducedTelemetryFrequency(true)

        XCTAssertEqual(viewModel.settings.accentColor, .solarGold)
        XCTAssertFalse(viewModel.settings.hapticFeedbackEnabled)
        XCTAssertTrue(viewModel.settings.reducedTelemetryFrequency)

        viewModel.resetAllSettings()

        XCTAssertEqual(viewModel.settings, .defaults)
        XCTAssertEqual(store.loadSettings(), .defaults)
    }
}
