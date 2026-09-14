import SwiftUI

enum AccentColorOption: String, CaseIterable, Codable, Identifiable {
    case orbitalBlue
    case solarGold
    case auroraGreen

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .orbitalBlue:
            return "Orbital Blue"
        case .solarGold:
            return "Solar Gold"
        case .auroraGreen:
            return "Aurora Green"
        }
    }

    var color: Color {
        switch self {
        case .orbitalBlue:
            return Color(red: 0.12, green: 0.42, blue: 0.92)
        case .solarGold:
            return Color(red: 0.91, green: 0.58, blue: 0.12)
        case .auroraGreen:
            return Color(red: 0.09, green: 0.62, blue: 0.42)
        }
    }
}

struct CubeSettings: Codable, Equatable {
    static let allowedSpeedRange: ClosedRange<Double> = 0.2...2.0
    static let defaults = CubeSettings(isRotating: true, rotationSpeed: 1.0)

    var isRotating: Bool
    var rotationSpeed: Double

    func normalized() -> CubeSettings {
        CubeSettings(isRotating: isRotating, rotationSpeed: Self.clampedSpeed(rotationSpeed))
    }

    static func clampedSpeed(_ speed: Double) -> Double {
        min(max(speed, allowedSpeedRange.lowerBound), allowedSpeedRange.upperBound)
    }
}

struct AppSettings: Codable, Equatable {
    static let defaults = AppSettings(
        accentColor: .orbitalBlue,
        hapticFeedbackEnabled: true,
        reducedTelemetryFrequency: false,
        cube: .defaults
    )

    var accentColor: AccentColorOption
    var hapticFeedbackEnabled: Bool
    var reducedTelemetryFrequency: Bool
    var cube: CubeSettings

    func normalized() -> AppSettings {
        AppSettings(
            accentColor: accentColor,
            hapticFeedbackEnabled: hapticFeedbackEnabled,
            reducedTelemetryFrequency: reducedTelemetryFrequency,
            cube: cube.normalized()
        )
    }
}
