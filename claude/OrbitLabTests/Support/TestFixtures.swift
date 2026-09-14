import Foundation
@testable import OrbitLab

enum TestFixtures {
    static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    static var snapshot: MissionSnapshot { snapshot(status: .nominal) }

    static func snapshot(status: MissionStatus) -> MissionSnapshot {
        MissionSnapshot(
            status: status,
            vehicle: "Test Orbiter",
            missionElapsedTime: 3_661,
            metrics: [
                MissionMetric(id: "a", title: "Thrust", value: 80, unit: "kN", trend: .up, symbolName: "flame.fill"),
                MissionMetric(id: "b", title: "Voltage", value: 28, unit: "V", trend: .flat, symbolName: "bolt.fill"),
                MissionMetric(id: "c", title: "Downlink", value: 2.5, unit: "Gb/s", trend: .down, symbolName: "antenna.radiowaves.left.and.right")
            ],
            events: [
                MissionEvent(id: "e1", title: "Burn complete", detail: "Nominal", timestamp: referenceDate, severity: .info)
            ],
            capturedAt: referenceDate
        )
    }
}
