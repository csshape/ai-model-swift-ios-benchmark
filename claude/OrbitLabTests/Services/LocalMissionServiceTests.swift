import XCTest
@testable import OrbitLab

final class LocalMissionServiceTests: XCTestCase {
    func test_snapshotIsDeterministicForTheSameSeed() async throws {
        let service = LocalMissionService()

        let first = try await service.loadSnapshot()
        let second = try await service.loadSnapshot()

        XCTAssertEqual(first, second)
    }

    func test_snapshotSuppliesEnoughDataForTheDashboard() async throws {
        let snapshot = try await LocalMissionService().loadSnapshot()

        XCTAssertGreaterThanOrEqual(snapshot.metrics.count, 3)
        XCTAssertGreaterThanOrEqual(snapshot.events.count, 3)
        XCTAssertEqual(Set(snapshot.metrics.map(\.id)).count, snapshot.metrics.count)
        XCTAssertEqual(Set(snapshot.events.map(\.id)).count, snapshot.events.count)
        XCTAssertEqual(snapshot.status, .nominal)
    }

    func test_elapsedTimeIsFormattedAsMissionTime() {
        let snapshot = TestFixtures.snapshot

        XCTAssertEqual(snapshot.formattedElapsedTime, "T+01:01:01")
    }

    func test_metricFormattingKeepsSmallValuesReadable() {
        let large = MissionMetric(id: "a", title: "Thrust", value: 84.6, unit: "kN", trend: .up, symbolName: "flame.fill")
        let small = MissionMetric(id: "b", title: "Downlink", value: 2.5, unit: "Gb/s", trend: .down, symbolName: "antenna.radiowaves.left.and.right")

        XCTAssertTrue(large.formattedValue.hasSuffix(" kN"))
        XCTAssertTrue(small.formattedValue.contains("2"))
        XCTAssertTrue(small.formattedValue.hasSuffix(" Gb/s"))
    }
}
