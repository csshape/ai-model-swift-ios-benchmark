import XCTest
@testable import OrbitLab

final class KeyValueStoreTests: XCTestCase {
    func test_roundTripsACodableValue() {
        let store = InMemoryKeyValueStore()
        let settings = AppSettings(accent: .solar, hapticsEnabled: false, usesReducedTelemetryCadence: true)

        store.setValue(settings, forKey: StorageKey.appSettings)

        XCTAssertEqual(store.value(forKey: StorageKey.appSettings, default: AppSettings.default), settings)
    }

    func test_missingKeyReturnsTheSuppliedDefault() {
        let store = InMemoryKeyValueStore()

        XCTAssertEqual(store.value(forKey: StorageKey.appSettings, default: AppSettings.default), AppSettings.default)
    }

    /// Edge case: a payload written by an older build must degrade to defaults, not crash,
    /// and the bad value must be cleared so it cannot keep failing.
    func test_corruptPayloadFallsBackToTheDefaultAndClearsTheKey() {
        let store = InMemoryKeyValueStore()
        store.setData(Data("not json".utf8), forKey: StorageKey.appSettings)

        let loaded: AppSettings = store.value(forKey: StorageKey.appSettings, default: AppSettings.default)

        XCTAssertEqual(loaded, AppSettings.default)
        XCTAssertNil(store.data(forKey: StorageKey.appSettings))
    }

    func test_removeAllClearsEveryKeyTheAppOwns() {
        let defaults = UserDefaults(suiteName: "orbitlab.tests.\(UUID().uuidString)")
        let store = UserDefaultsKeyValueStore(defaults: defaults ?? .standard)

        store.setValue(AppSettings.default, forKey: StorageKey.appSettings)
        store.setValue(CubeSettings.default, forKey: StorageKey.cubeSettings)

        store.removeAll()

        XCTAssertNil(store.data(forKey: StorageKey.appSettings))
        XCTAssertNil(store.data(forKey: StorageKey.cubeSettings))
    }
}
