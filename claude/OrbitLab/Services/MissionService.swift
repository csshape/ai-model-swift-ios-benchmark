import Foundation

/// Supplies the Mission Control dashboard with a snapshot.
///
/// The dashboard only ever sees this protocol, so swapping the local implementation for a
/// networked one later is a change in `AppContainer` and nothing else.
protocol MissionService: Sendable {
    func loadSnapshot() async throws -> MissionSnapshot
}

enum MissionServiceError: LocalizedError, Equatable {
    case telemetryLinkDown

    var errorDescription: String? {
        switch self {
        case .telemetryLinkDown: return "Lost contact with the mission data link."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .telemetryLinkDown: return "Check the relay and try again."
        }
    }
}

/// Production implementation: deterministic sample data, built off the main actor.
///
/// It is `async` on purpose — the call site is already written for a service that suspends,
/// so no code changes when the data starts coming from a server.
struct LocalMissionService: MissionService {
    /// Fixed epoch so the snapshot is byte-for-byte reproducible in tests and screenshots.
    private let referenceDate: Date
    private let seed: UInt64

    init(referenceDate: Date = Date(timeIntervalSince1970: 1_735_689_600), seed: UInt64 = 0x4F72_6269_7421) {
        self.referenceDate = referenceDate
        self.seed = seed
    }

    func loadSnapshot() async throws -> MissionSnapshot {
        // Hop off whatever actor called us; building the snapshot is pure computation.
        await Task.yield()
        try Task.checkCancellation()
        return Self.makeSnapshot(referenceDate: referenceDate, seed: seed)
    }

    static func makeSnapshot(referenceDate: Date, seed: UInt64) -> MissionSnapshot {
        var generator = SplitMix64(seed: seed)

        let metrics = [
            MissionMetric(
                id: "thrust",
                title: "Main thrust",
                value: 74 + generator.nextUnitDouble() * 20,
                unit: "kN",
                trend: .up,
                symbolName: "flame.fill"
            ),
            MissionMetric(
                id: "power",
                title: "Bus voltage",
                value: 27 + generator.nextUnitDouble() * 4,
                unit: "V",
                trend: .flat,
                symbolName: "bolt.fill"
            ),
            MissionMetric(
                id: "signal",
                title: "Downlink",
                value: 1.5 + generator.nextUnitDouble() * 2,
                unit: "Gb/s",
                trend: .down,
                symbolName: "antenna.radiowaves.left.and.right"
            ),
            MissionMetric(
                id: "crew",
                title: "Cabin oxygen",
                value: 20 + generator.nextUnitDouble() * 2,
                unit: "%",
                trend: .flat,
                symbolName: "lungs.fill"
            )
        ]

        let eventSeeds: [(String, String, MissionEventSeverity, TimeInterval)] = [
            ("Orbit insertion burn complete", "Delta-v within 0.4% of plan.", .info, -120),
            ("Solar array beta angle adjusted", "Array 2 rotated to 18.6 degrees.", .info, -640),
            ("Thermal loop pressure drift", "Loop B trending 3 kPa below nominal.", .warning, -1_480),
            ("Uplink handover to Canberra", "Signal margin 6.2 dB.", .info, -2_260),
            ("Reaction wheel 3 desaturated", "Momentum dumped using RCS.", .warning, -3_105),
            ("Payload bay door cycle", "Doors confirmed latched.", .info, -4_020)
        ]

        let events = eventSeeds.enumerated().map { index, seed in
            MissionEvent(
                id: "event-\(index)",
                title: seed.0,
                detail: seed.1,
                timestamp: referenceDate.addingTimeInterval(seed.3),
                severity: seed.2
            )
        }

        return MissionSnapshot(
            status: .nominal,
            vehicle: "Orbiter OL-1",
            missionElapsedTime: 8_142,
            metrics: metrics,
            events: events,
            capturedAt: referenceDate
        )
    }
}

/// Tiny deterministic generator so sample values look organic without being random per run.
struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// A value in 0..<1.
    mutating func nextUnitDouble() -> Double {
        Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }
}
