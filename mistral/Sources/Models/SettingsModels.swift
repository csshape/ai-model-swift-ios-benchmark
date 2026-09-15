import Foundation
import SwiftUI

// MARK: - Accent Color Options

enum AccentColorOption: String, CaseIterable, Identifiable, Codable {
    case systemBlue
    case systemPurple
    case systemOrange
    case systemGreen
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .systemBlue: return "Blue"
        case .systemPurple: return "Purple"
        case .systemOrange: return "Orange"
        case .systemGreen: return "Green"
        }
    }
    
    var color: Color {
        switch self {
        case .systemBlue: return .blue
        case .systemPurple: return .purple
        case .systemOrange: return .orange
        case .systemGreen: return .green
        }
    }
    
    var uiColor: UIColor {
        switch self {
        case .systemBlue: return .systemBlue
        case .systemPurple: return .systemPurple
        case .systemOrange: return .systemOrange
        case .systemGreen: return .systemGreen
        }
    }
}

// MARK: - Settings Model

struct AppSettings: Codable, Equatable {
    var accentColor: AccentColorOption
    var hapticFeedbackEnabled: Bool
    var reducedTelemetryFrequency: Bool
    
    init(accentColor: AccentColorOption = .systemBlue, 
         hapticFeedbackEnabled: Bool = true,
         reducedTelemetryFrequency: Bool = false) {
        self.accentColor = accentColor
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.reducedTelemetryFrequency = reducedTelemetryFrequency
    }
    
    static var `default`: AppSettings {
        AppSettings()
    }
    
    func reset() -> AppSettings {
        AppSettings()
    }
}

// MARK: - Cube Settings

struct CubeSettings: Codable, Equatable {
    var rotationSpeed: Float
    var isAutoRotating: Bool
    
    init(rotationSpeed: Float = 1.0, isAutoRotating: Bool = true) {
        self.rotationSpeed = rotationSpeed
        self.isAutoRotating = isAutoRotating
    }
    
    static var `default`: CubeSettings {
        CubeSettings()
    }
}

// MARK: - Combined App State

struct PersistentAppState: Codable, Equatable {
    var appSettings: AppSettings
    var cubeSettings: CubeSettings
    
    init(appSettings: AppSettings = .default, cubeSettings: CubeSettings = .default) {
        self.appSettings = appSettings
        self.cubeSettings = cubeSettings
    }
    
    static var `default`: PersistentAppState {
        PersistentAppState()
    }
    
    func reset() -> PersistentAppState {
        PersistentAppState()
    }
}
