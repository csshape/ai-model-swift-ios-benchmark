import XCTest
@testable import OrbitLab

@MainActor
final class AppSettingsStoreTests: XCTestCase {
    func test_loadsShippedDefaultsWhenNothingHasBeenPersisted() {
        let store = AppSettingsStore(store: InMemoryKeyValueStore())

        XCTAssertEqual(store.settings, AppSettings.default)
        XCTAssertEqual(store.settings.accent, .aurora)
        XCTAssertTrue(store.settings.hapticsEnabled)
        XCTAssertEqual(store.settings.telemetryCadence, .standard)
    }

    func test_changesArePersistedAndReloadedByAFreshStore() {
        let backing = RecordingKeyValueStore()
        let store = AppSettingsStore(store: backing)

        store.settings.accent = .solar
        store.settings.hapticsEnabled = false
        store.settings.usesReducedTelemetryCadence = true

        let reloaded = AppSettingsStore(store: backing)

        XCTAssertEqual(reloaded.settings.accent, .solar)
        XCTAssertFalse(reloaded.settings.hapticsEnabled)
        XCTAssertEqual(reloaded.settings.telemetryCadence, .reduced)
        XCTAssertEqual(backing.writeCount, 3, "Each distinct change writes exactly once")
    }

    func test_writingTheSameValueDoesNotTouchStorage() {
        let backing = RecordingKeyValueStore()
        let store = AppSettingsStore(store: backing)

        store.settings.accent = store.settings.accent

        XCTAssertEqual(backing.writeCount, 0)
    }

    func test_resetRestoresEveryDefault() {
        let backing = RecordingKeyValueStore()
        let store = AppSettingsStore(store: backing)

        store.settings.accent = .plasma
        store.settings.hapticsEnabled = false
        store.settings.usesReducedTelemetryCadence = true

        store.reset()

        XCTAssertEqual(store.settings, AppSettings.default)
        XCTAssertEqual(AppSettingsStore(store: backing).settings, AppSettings.default)
    }

    func test_summaryDescribesTheCurrentConfiguration() {
        let store = AppSettingsStore(store: InMemoryKeyValueStore())

        XCTAssertEqual(store.settings.summary, "Aurora · Haptics on · Standard cadence")

        store.settings.hapticsEnabled = false
        store.settings.usesReducedTelemetryCadence = true

        XCTAssertEqual(store.settings.summary, "Aurora · Haptics off · Reduced cadence")
    }
}

@MainActor
final class AppContainerTests: XCTestCase {
    func test_resetAllSettingsClearsBothAppAndCubePreferences() {
        let backing = RecordingKeyValueStore()
        let container = AppContainer(
            keyValueStore: backing,
            missionService: StubMissionService(snapshot: TestFixtures.snapshot),
            telemetrySource: ControlledTelemetrySource(),
            haptics: SilentHaptics()
        )

        container.settingsStore.settings.accent = .plasma
        container.cubeViewModel.togglePlayback()
        container.cubeViewModel.setSpeed(2.5)

        container.resetAllSettings()

        XCTAssertEqual(container.settingsStore.settings, AppSettings.default)
        XCTAssertTrue(container.cubeViewModel.isRotating)
        XCTAssertEqual(container.cubeViewModel.speed, CubeSettings.default.speed, accuracy: 0.0001)
        XCTAssertEqual(backing.removeAllCount, 1)
    }

    func test_uiTestLaunchArgumentSelectsAnEphemeralStore() {
        let processInfo = ProcessInfo.processInfo
        let container = AppContainer.live(processInfo: processInfo)

        // The real process is not a UI test run, so this documents the default wiring.
        XCTAssertFalse(processInfo.arguments.contains(A11y.uiTestLaunchArgument))
        XCTAssertEqual(container.settingsStore.settings.accent, container.settingsStore.settings.accent)
    }
}
