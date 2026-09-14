import Foundation

/// Accent colours offered in Settings. Raw values are the persistence keys.
enum AccentChoice: String, Codable, Equatable, CaseIterable, Identifiable {
    case aurora
    case plasma
    case solar

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aurora: return "Aurora"
        case .plasma: return "Plasma"
        case .solar: return "Solar"
        }
    }
}

/// User preferences that affect the whole app.
struct AppSettings: Codable, Equatable {
    static let `default` = AppSettings(accent: .aurora, hapticsEnabled: true, usesReducedTelemetryCadence: false)

    var accent: AccentChoice
    var hapticsEnabled: Bool
    var usesReducedTelemetryCadence: Bool

    var telemetryCadence: TelemetryCadence {
        usesReducedTelemetryCadence ? .reduced : .standard
    }

    /// Short line shown in Settings and asserted by the UI tests.
    var summary: String {
        "\(accent.title) · Haptics \(hapticsEnabled ? "on" : "off") · \(telemetryCadence.title) cadence"
    }
}
