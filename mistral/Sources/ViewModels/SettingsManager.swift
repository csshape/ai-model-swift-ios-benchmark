import Foundation
import SwiftUI
import Combine

// MARK: - Settings Manager

/// Manages app-wide settings with persistence
class SettingsManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var accentColor: AccentColorOption {
        didSet {
            saveSettings()
        }
    }
    
    @Published var hapticFeedbackEnabled: Bool {
        didSet {
            saveSettings()
        }
    }
    
    @Published var reducedTelemetryFrequency: Bool {
        didSet {
            saveSettings()
        }
    }
    
    @Published var cubeRotationSpeed: Float {
        didSet {
            saveCubeSettings()
        }
    }
    
    @Published var cubeIsAutoRotating: Bool {
        didSet {
            saveCubeSettings()
        }
    }
    
    // MARK: - Computed Properties
    
    var colorScheme: ColorScheme? {
        // Could be extended to support dark/light mode based on settings
        nil
    }
    
    var accentColorValue: Color {
        accentColor.color
    }
    
    var accentUIColor: UIColor {
        accentColor.uiColor
    }
    
    // MARK: - Private Properties
    
    private let storageService: StorageServiceProtocol
    private let appSettingsKey = StorageKey.appSettings
    private let cubeSettingsKey = StorageKey.cubeSettings
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initialize with a storage service
    /// - Parameter storageService: The storage service to use (defaults to UserDefaults)
    init(storageService: StorageServiceProtocol = UserDefaultsStorageService()) {
        self.storageService = storageService
        
        // Load settings
        do {
            if let appSettings: AppSettings = try storageService.load(forKey: appSettingsKey) {
                self.accentColor = appSettings.accentColor
                self.hapticFeedbackEnabled = appSettings.hapticFeedbackEnabled
                self.reducedTelemetryFrequency = appSettings.reducedTelemetryFrequency
            } else {
                // Use defaults
                let defaultSettings = AppSettings.default
                self.accentColor = defaultSettings.accentColor
                self.hapticFeedbackEnabled = defaultSettings.hapticFeedbackEnabled
                self.reducedTelemetryFrequency = defaultSettings.reducedTelemetryFrequency
            }
            
            if let cubeSettings: CubeSettings = try storageService.load(forKey: cubeSettingsKey) {
                self.cubeRotationSpeed = cubeSettings.rotationSpeed
                self.cubeIsAutoRotating = cubeSettings.isAutoRotating
            } else {
                let defaultCubeSettings = CubeSettings.default
                self.cubeRotationSpeed = defaultCubeSettings.rotationSpeed
                self.cubeIsAutoRotating = defaultCubeSettings.isAutoRotating
            }
        } catch {
            print("Error loading settings: \(error)")
            // Use defaults on error
            let defaultSettings = AppSettings.default
            self.accentColor = defaultSettings.accentColor
            self.hapticFeedbackEnabled = defaultSettings.hapticFeedbackEnabled
            self.reducedTelemetryFrequency = defaultSettings.reducedTelemetryFrequency
            
            let defaultCubeSettings = CubeSettings.default
            self.cubeRotationSpeed = defaultCubeSettings.rotationSpeed
            self.cubeIsAutoRotating = defaultCubeSettings.isAutoRotating
        }
    }
    
    // MARK: - Public Methods
    
    /// Resets all settings to defaults
    func resetAllSettings() {
        let defaultSettings = AppSettings.default
        accentColor = defaultSettings.accentColor
        hapticFeedbackEnabled = defaultSettings.hapticFeedbackEnabled
        reducedTelemetryFrequency = defaultSettings.reducedTelemetryFrequency
        
        let defaultCubeSettings = CubeSettings.default
        cubeRotationSpeed = defaultCubeSettings.rotationSpeed
        cubeIsAutoRotating = defaultCubeSettings.isAutoRotating
        
        // Clear storage
        try? storageService.delete(forKey: appSettingsKey)
        try? storageService.delete(forKey: cubeSettingsKey)
    }
    
    /// Get current app settings as a struct
    func currentAppSettings() -> AppSettings {
        AppSettings(
            accentColor: accentColor,
            hapticFeedbackEnabled: hapticFeedbackEnabled,
            reducedTelemetryFrequency: reducedTelemetryFrequency
        )
    }
    
    /// Get current cube settings as a struct
    func currentCubeSettings() -> CubeSettings {
        CubeSettings(
            rotationSpeed: cubeRotationSpeed,
            isAutoRotating: cubeIsAutoRotating
        )
    }
    
    // MARK: - Private Methods
    
    private func saveSettings() {
        let settings = AppSettings(
            accentColor: accentColor,
            hapticFeedbackEnabled: hapticFeedbackEnabled,
            reducedTelemetryFrequency: reducedTelemetryFrequency
        )
        
        try? storageService.save(settings, forKey: appSettingsKey)
    }
    
    private func saveCubeSettings() {
        let settings = CubeSettings(
            rotationSpeed: cubeRotationSpeed,
            isAutoRotating: cubeIsAutoRotating
        )
        
        try? storageService.save(settings, forKey: cubeSettingsKey)
    }
}

// MARK: - Preview Settings Manager

final class PreviewSettingsManager: SettingsManager {
    init() {
        super.init(storageService: MockStorageService())
        // Use preview-friendly defaults
        self.accentColor = .systemBlue
        self.hapticFeedbackEnabled = true
        self.reducedTelemetryFrequency = false
        self.cubeRotationSpeed = 1.0
        self.cubeIsAutoRotating = true
    }
}
