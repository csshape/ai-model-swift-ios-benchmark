import Foundation

struct MissionMetric: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let value: String
    let detail: String
    let systemImage: String
}

struct MissionEvent: Codable, Equatable, Identifiable {
    let id: UUID
    let title: String
    let detail: String
    let timestamp: Date
    let severity: Severity

    enum Severity: String, Codable, Equatable {
        case nominal
        case warning
        case critical

        var label: String {
            switch self {
            case .nominal:
                return "Nominal"
            case .warning:
                return "Watch"
            case .critical:
                return "Critical"
            }
        }
    }
}

struct MissionSnapshot: Codable, Equatable {
    let statusTitle: String
    let statusDetail: String
    let metrics: [MissionMetric]
    let events: [MissionEvent]

    static let sample = MissionSnapshot(
        statusTitle: "Nominal Orbit",
        statusDetail: "All local systems are synchronized for the current simulation window.",
        metrics: [
            MissionMetric(
                id: "orbit",
                title: "Orbit",
                value: "405 km",
                detail: "Stable altitude",
                systemImage: "circle.dotted"
            ),
            MissionMetric(
                id: "power",
                title: "Power",
                value: "92%",
                detail: "Solar array yield",
                systemImage: "bolt.fill"
            ),
            MissionMetric(
                id: "signal",
                title: "Signal",
                value: "38 ms",
                detail: "Round-trip latency",
                systemImage: "dot.radiowaves.left.and.right"
            )
        ],
        events: [
            MissionEvent(
                id: UUID(uuidString: "4E7E63A9-5D5A-4D3F-956B-7ED27EACDA11") ?? UUID(),
                title: "Telemetry lock acquired",
                detail: "Ground station channel A verified deterministic stream integrity.",
                timestamp: Date(timeIntervalSince1970: 1_789_370_400),
                severity: .nominal
            ),
            MissionEvent(
                id: UUID(uuidString: "59A729F1-9954-47F7-92EC-B4432CBB7E76") ?? UUID(),
                title: "Attitude trim queued",
                detail: "Cube lab rotation state is ready for manual inspection.",
                timestamp: Date(timeIntervalSince1970: 1_789_370_100),
                severity: .warning
            ),
            MissionEvent(
                id: UUID(uuidString: "7D34C9A6-2C97-4E78-82E8-40B6F3087620") ?? UUID(),
                title: "Persistence checkpoint saved",
                detail: "Settings payload committed to local storage.",
                timestamp: Date(timeIntervalSince1970: 1_789_369_800),
                severity: .nominal
            )
        ]
    )
}
