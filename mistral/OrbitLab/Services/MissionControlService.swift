import Foundation

enum MissionControlError: Error, Equatable {
    case networkError, invalidData, serviceUnavailable, unknownError
}

protocol MissionControlServiceProtocol {
    func fetchMissionData() async throws -> MissionControlData
}

class MissionControlService: MissionControlServiceProtocol {
    func fetchMissionData() async throws -> MissionControlData {
        try await Task.sleep(nanoseconds: 500_000_000)
        let calendar = Calendar.current
        let now = Date()
        let events: [MissionEvent] = [
            MissionEvent(timestamp: calendar.date(byAdding: .minute, value: -5, to: now) ?? now, missionName: "Orbit Insertion", status: .completed, description: "Satellite inserted"),
            MissionEvent(timestamp: calendar.date(byAdding: .minute, value: -10, to: now) ?? now, missionName: "System Check", status: .inProgress, description: "Diagnostics running"),
            MissionEvent(timestamp: calendar.date(byAdding: .minute, value: -15, to: now) ?? now, missionName: "Communication Test", status: .pending, description: "Scheduled"),
            MissionEvent(timestamp: calendar.date(byAdding: .minute, value: -20, to: now) ?? now, missionName: "Solar Panel Deploy", status: .completed, description: "Panels deployed"),
            MissionEvent(timestamp: calendar.date(byAdding: .minute, value: -25, to: now) ?? now, missionName: "Trajectory Correction", status: .completed, description: "Adjustment done")
        ]
        let metrics = MissionMetrics(totalMissions: 24, successfulMissions: 22, activeMissions: 1, averageDuration: 3600)
        return MissionControlData(metrics: metrics, events: events, lastUpdated: now)
    }
}

class MockMissionControlService: MissionControlServiceProtocol {
    var shouldFail = false
    var mockData: MissionControlData?
    init(shouldFail: Bool = false, mockData: MissionControlData? = nil) {
        self.shouldFail = shouldFail
        self.mockData = mockData
    }
    func fetchMissionData() async throws -> MissionControlData {
        if shouldFail { throw MissionControlError.networkError }
        if let mockData = mockData { return mockData }
        let metrics = MissionMetrics(totalMissions: 10, successfulMissions: 8, activeMissions: 1, averageDuration: 1800)
        return MissionControlData(metrics: metrics, events: [MissionEvent(timestamp: Date(), missionName: "Test", status: .completed, description: "Test")], lastUpdated: Date())
    }
}
