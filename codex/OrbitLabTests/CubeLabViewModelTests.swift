import XCTest
@testable import OrbitLab

@MainActor
final class CubeLabViewModelTests: XCTestCase {
    func testStartPauseSpeedChangeAndResetUpdateRotationState() {
        var persistedSettings: [CubeSettings] = []
        let viewModel = CubeLabViewModel(settings: .defaults) { settings in
            persistedSettings.append(settings)
        }

        XCTAssertTrue(viewModel.rotationConfiguration.isAnimationEnabled)

        viewModel.toggleRotation()
        XCTAssertFalse(viewModel.settings.isRotating)
        XCTAssertFalse(viewModel.rotationConfiguration.isAnimationEnabled)

        viewModel.toggleRotation()
        viewModel.updateSpeed(1.7)
        XCTAssertTrue(viewModel.settings.isRotating)
        XCTAssertEqual(viewModel.settings.rotationSpeed, 1.7, accuracy: 0.001)

        viewModel.reset()
        XCTAssertEqual(viewModel.settings, .defaults)
        XCTAssertEqual(viewModel.resetToken, 1)
        XCTAssertEqual(persistedSettings.last, .defaults)
    }

    func testCubeSettingsPersistThroughSettingsStore() {
        let store = InMemorySettingsStore()
        let settingsViewModel = AppSettingsViewModel(store: store)
        settingsViewModel.updateCubeSettings(CubeSettings(isRotating: false, rotationSpeed: 1.6))

        let reloadedViewModel = AppSettingsViewModel(store: store)

        XCTAssertEqual(reloadedViewModel.settings.cube, CubeSettings(isRotating: false, rotationSpeed: 1.6))
    }

    func testSpeedIsClampedWhenInputIsOutsideSupportedRange() {
        let viewModel = CubeLabViewModel(settings: .defaults)

        viewModel.updateSpeed(8.0)
        XCTAssertEqual(viewModel.settings.rotationSpeed, CubeSettings.allowedSpeedRange.upperBound)

        viewModel.updateSpeed(-3.0)
        XCTAssertEqual(viewModel.settings.rotationSpeed, CubeSettings.allowedSpeedRange.lowerBound)
    }
}
