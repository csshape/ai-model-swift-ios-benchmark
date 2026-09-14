import Foundation

/// Overall health of the mission, used by the dashboard header.
enum MissionStatus: String, Codable, Equatable, CaseIterable {
    case nominal
    case degraded
    case critical

    var title: String {
        switch self {
        case .nominal: return "All systems nominal"
        case .degraded: return "Degraded performance"
        case .critical: return "Critical attention"
        }
    }

    var symbolName: String {
        switch self {
        case .nominal: return "checkmark.seal.fill"
        case .degraded: return "exclamationmark.triangle.fill"
        case .critical: return "bolt.trianglebadge.exclamationmark.fill"
        }
    }
}

/// Direction of a metric compared to its previous reading.
enum MetricTrend: String, Codable, Equatable {
    case up
    case down
    case flat

    var symbolName: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .flat: return "arrow.right"
        }
    }

    var accessibleDescription: String {
        switch self {
        case .up: return "trending up"
        case .down: return "trending down"
        case .flat: return "unchanged"
        }
    }
}

/// A single headline number on the dashboard.
struct MissionMetric: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let value: Double
    let unit: String
    let trend: MetricTrend
    let symbolName: String

    var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = value < 10 ? 2 : 0
        formatter.minimumFractionDigits = value < 10 ? 2 : 0
        let number = formatter.string(from: NSNumber(value: value)) ?? String(value)
        return unit.isEmpty ? number : "\(number) \(unit)"
    }
}

/// Severity of an entry in the mission log.
enum MissionEventSeverity: String, Codable, Equatable {
    case info
    case warning
    case alert

    var symbolName: String {
        switch self {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.circle"
        case .alert: return "exclamationmark.octagon"
        }
    }
}

/// One entry in the mission log.
struct MissionEvent: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let detail: String
    let timestamp: Date
    let severity: MissionEventSeverity
}

/// Everything the Mission Control dashboard needs for one render pass.
struct MissionSnapshot: Codable, Equatable {
    let status: MissionStatus
    let vehicle: String
    let missionElapsedTime: TimeInterval
    let metrics: [MissionMetric]
    let events: [MissionEvent]
    let capturedAt: Date

    var formattedElapsedTime: String {
        let total = Int(missionElapsedTime.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "T+%02d:%02d:%02d", hours, minutes, seconds)
    }
}
