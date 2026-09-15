import XCTest
@testable import OrbitLab

final class SettingsTests: XCTestCase {
    
    func testLoadDefaultSettings() {
        let mockStorage = MockStorageService()
        let settingsManager = SettingsManager(storageService: mockStorage)
        XCTAssertEqual(settingsManager.accentColor, .systemBlue)
        XCTAssertTrue(settingsManager.hapticFeedbackEnabled)
        XCTAssertFalse(settingsManager.reducedTelemetryFrequency)
    }
    
    func testChangeAccentColor() {
        let mockStorage = MockStorageService()
        let settingsManager = SettingsManager(storageService: mockStorage)
        settingsManager.accentColor = .systemOrange
        XCTAssertEqual(settingsManager.accentColor, .systemOrange)
    }
    
    func testChangeHapticFeedback() {
        let mockStorage = MockStorageService()
        let settingsManager = SettingsManager(storageService: mockStorage)
        settingsManager.hapticFeedbackEnabled = false
        XCTAssertFalse(settingsManager.hapticFeedbackEnabled)
    }
    
    func testResetAllSettings() {
        let mockStorage = MockStorageService()
        let settingsManager = SettingsManager(storageService: mockStorage)
        settingsManager.accentColor = .systemGreen
        settingsManager.hapticFeedbackEnabled = false
        settingsManager.reducedTelemetryFrequency = true
        settingsManager.resetAllSettings()
        XCTAssertEqual(settingsManager.accentColor, .systemBlue)
        XCTAssertTrue(settingsManager.hapticFeedbackEnabled)
        XCTAssertFalse(settingsManager.reducedTelemetryFrequency)
    }
    
    func testSettingsPersistAfterChange() {
        let mockStorage = MockStorageService()
        let settingsManager = SettingsManager(storageService: mockStorage)
        settingsManager.accentColor = .systemOrange
        let newSettingsManager = SettingsManager(storageService: mockStorage)
        XCTAssertEqual(newSettingsManager.accentColor, .systemOrange)
    }
}
