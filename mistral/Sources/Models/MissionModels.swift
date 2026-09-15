import Foundation

// MARK: - Mission Status Models

enum MissionStatus: String, Codable, Identifiable {
    case nominal
    case warning
    case critical
    case offline
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .nominal: return "Nominal"
        case .warning: return "Warning"
        case .critical: return "Critical"
        case .offline: return "Offline"
        }
    }
    
    var colorName: String {
        switch self {
        case .nominal: return "green"
        case .warning: return "yellow"
        case .critical: return "red"
        case .offline: return "gray"
        }
    }
}

// MARK: - Metric Models

struct MissionMetric: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var value: String
    var unit: String
    var trend: Trend
    
    init(id: UUID = UUID(), name: String, value: String, unit: String, trend: Trend) {
        self.id = id
        self.name = name
        self.value = value
        self.unit = unit
        self.trend = trend
    }
}

enum Trend: String, Codable {
    case up
    case down
    case stable
}

// MARK: - Mission Event Models

struct MissionEvent: Identifiable, Codable, Equatable {
    let id: UUID
    var timestamp: Date
    var type: EventType
    var description: String
    var severity: EventSeverity
    
    init(id: UUID = UUID(), timestamp: Date, type: EventType, description: String, severity: EventSeverity) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.description = description
        self.severity = severity
    }
}

enum EventType: String, Codable {
    case systemStartup
    case systemShutdown
    case sensorCalibration
    case trajectoryAdjustment
    case communicationEstablished
    case communicationLost
    case powerCycle
}

enum EventSeverity: String, Codable {
    case info
    case warning
    case error
    
    var colorName: String {
        switch self {
        case .info: return "blue"
        case .warning: return "yellow"
        case .error: return "red"
        }
    }
}

// MARK: - Mission Dashboard State

struct MissionDashboard: Codable, Equatable {
    var status: MissionStatus
    var metrics: [MissionMetric]
    var recentEvents: [MissionEvent]
    var lastUpdated: Date
    
    init(status: MissionStatus, metrics: [MissionMetric], recentEvents: [MissionEvent], lastUpdated: Date) {
        self.status = status
        self.metrics = metrics
        self.recentEvents = recentEvents
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Sample Data Generator

struct SampleMissionData {
    static func generateDashboard() -> MissionDashboard {
        let now = Date()
        let calendar = Calendar.current
        
        let status: MissionStatus = Bool.random() ? .nominal : (Bool.random() ? .warning : .nominal)
        
        let metrics = [
            MissionMetric(
                name: "Orbit Altitude",
                value: String(format: "%.1f", Double.random(in: 350...420)),
                unit: "km",
                trend: [.up, .down, .stable].randomElement()!
            ),
            MissionMetric(
                name: "Velocity",
                value: String(format: "%.2f", Double.random(in: 7.5...7.9)),
                unit: "km/s",
                trend: [.up, .down, .stable].randomElement()!
            ),
            MissionMetric(
                name: "Power Level",
                value: String(format: "%.1f", Double.random(in: 85...100)),
                unit: "%",
                trend: [.up, .down, .stable].randomElement()!
            )
        ]
        
        let events: [MissionEvent] = (0..<5).map { index in
            let eventTypes: [EventType] = [.systemStartup, .sensorCalibration, .trajectoryAdjustment, .communicationEstablished]
            let severities: [EventSeverity] = [.info, .warning, .info]
            let minutesAgo = Int.random(in: 1...120)
            let eventTime = calendar.date(byAdding: .minute, value: -minutesAgo, to: now)!
            
            return MissionEvent(
                timestamp: eventTime,
                type: eventTypes.randomElement()!,
                description: "Event description for event at index \(index)",
                severity: severities.randomElement()!
            )
        }.sorted { $0.timestamp > $1.timestamp }
        
        return MissionDashboard(
            status: status,
            metrics: metrics,
            recentEvents: events,
            lastUpdated: now
        )
    }
}
