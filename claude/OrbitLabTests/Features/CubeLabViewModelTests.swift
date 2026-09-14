import XCTest
@testable import OrbitLab

@MainActor
final class CubeLabViewModelTests: XCTestCase {
    func test_togglePlaybackSpeedChangeAndResetDriveTheAnimationState() {
        let viewModel = CubeLabViewModel(store: InMemoryKeyValueStore())

        XCTAssertTrue(viewModel.isRotating)
        XCTAssertTrue(viewModel.shouldAnimate)
        XCTAssertEqual(viewModel.playbackButtonTitle, "Pause")
        XCTAssertEqual(viewModel.statusDescription, "Rotating")

        viewModel.togglePlayback()
        XCTAssertFalse(viewModel.isRotating)
        XCTAssertFalse(viewModel.shouldAnimate)
        XCTAssertEqual(viewModel.playbackButtonTitle, "Start")
        XCTAssertEqual(viewModel.statusDescription, "Paused")

        viewModel.setSpeed(2.4)
        XCTAssertEqual(viewModel.speed, 2.4, accuracy: 0.0001)

        viewModel.reset()
        XCTAssertEqual(viewModel.speed, CubeSettings.default.speed, accuracy: 0.0001)
        XCTAssertTrue(viewModel.isRotating)
        XCTAssertTrue(viewModel.shouldAnimate)
    }

    func test_speedIsClampedToTheSupportedRange() {
        let viewModel = CubeLabViewModel(store: InMemoryKeyValueStore())

        viewModel.setSpeed(99)
        XCTAssertEqual(viewModel.speed, CubeSettings.speedRange.upperBound, accuracy: 0.0001)

        viewModel.setSpeed(-4)
        XCTAssertEqual(viewModel.speed, CubeSettings.speedRange.lowerBound, accuracy: 0.0001)
    }

    func test_settingsSurviveANewViewModelBackedByTheSameStore() {
        let store = RecordingKeyValueStore()
        let first = CubeLabViewModel(store: store)

        first.togglePlayback()
        first.setSpeed(2.0)

        let second = CubeLabViewModel(store: store)

        XCTAssertFalse(second.isRotating)
        XCTAssertEqual(second.speed, 2.0, accuracy: 0.0001)
        XCTAssertGreaterThan(store.writeCount, 0)
    }

    func test_animationStopsWhenTheSceneIsInactiveButThePreferenceIsKept() {
        let viewModel = CubeLabViewModel(store: InMemoryKeyValueStore())

        viewModel.setSceneActive(false)

        XCTAssertTrue(viewModel.isRotating, "The user's preference must survive backgrounding")
        XCTAssertFalse(viewModel.shouldAnimate)
        XCTAssertEqual(viewModel.statusDescription, "Suspended")

        viewModel.setSceneActive(true)
        XCTAssertTrue(viewModel.shouldAnimate)
    }

    func test_reduceMotionDisablesAutomaticRotation() {
        let viewModel = CubeLabViewModel(store: InMemoryKeyValueStore())

        viewModel.setReducedMotion(true)

        XCTAssertTrue(viewModel.isRotating)
        XCTAssertFalse(viewModel.shouldAnimate)
        XCTAssertEqual(viewModel.statusDescription, "Reduce Motion")
    }

    /// Edge case: a persisted speed from an older build can be outside the current range.
    /// Decoding must not fail and must not hand an unusable value to SceneKit.
    func test_outOfRangePersistedSpeedIsNormalisedOnLoad() {
        let store = RecordingKeyValueStore()
        store.seed(#"{"isRotating":true,"speed":42.5}"#, forKey: StorageKey.cubeSettings)

        let viewModel = CubeLabViewModel(store: store)

        XCTAssertEqual(viewModel.speed, CubeSettings.speedRange.upperBound, accuracy: 0.0001)
        XCTAssertTrue(viewModel.isRotating)
    }
}
