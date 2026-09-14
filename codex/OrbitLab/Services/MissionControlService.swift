import Foundation

protocol MissionControlServicing {
    func fetchSnapshot() async throws -> MissionSnapshot
}

struct LocalMissionControlService: MissionControlServicing {
    func fetchSnapshot() async throws -> MissionSnapshot {
        await Task.yield()
        return MissionSnapshot.sample
    }
}
