import Foundation

struct MissionEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let missionName: String
    let status: MissionStatus
    let description: String

    enum MissionStatus: String, Codable {
        case pending, inProgress, completed, failed, cancelled
    }

    init(id: UUID = UUID(), timestamp: Date, missionName: String, status: MissionStatus, description: String) {
        self.id = id
        self.timestamp = timestamp
        self.missionName = missionName
        self.status = status
        self.description = description
    }
}

struct MissionMetrics: Codable, Equatable {
    let totalMissions: Int
    let successfulMissions: Int
    let activeMissions: Int
    let averageDuration: TimeInterval
}

struct MissionControlData: Codable, Equatable {
    let metrics: MissionMetrics
    let events: [MissionEvent]
    let lastUpdated: Date
}
