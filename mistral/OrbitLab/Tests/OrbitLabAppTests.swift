import XCTest
@testable import OrbitLab

class OrbitLabAppTests: XCTestCase {

    // MARK: Mission Control
    func testMissionControlServiceFetch() async {
        let s = MissionControlService()
        do {
            let d = try await s.fetchMissionData()
            XCTAssertNotNil(d.metrics)
            XCTAssertNotNil(d.events)
            XCTAssertNotNil(d.lastUpdated)
            XCTAssertGreaterThan(d.metrics.totalMissions, 0)
            XCTAssertGreaterThan(d.events.count, 0)
        } catch {
            XCTFail("Error: \(error)")
        }
    }

    func testMissionControlMockSuccess() async {
        let mock = MockMissionControlService(mockData: MissionControlData(
            metrics: MissionMetrics(totalMissions: 5, successfulMissions: 4, activeMissions: 1, averageDuration: 100),
            events: [MissionEvent(timestamp: Date(), missionName: "Test", status: .completed, description: "Test")],
            lastUpdated: Date()
        ))
        do {
            let d = try await mock.fetchMissionData()
            XCTAssertEqual(d.metrics.totalMissions, 5)
        } catch {
            XCTFail()
        }
    }

    func testMissionControlMockFail() async {
        let mock = MockMissionControlService(shouldFail: true)
        do {
            _ = try await mock.fetchMissionData()
            XCTFail()
        } catch let e as MissionControlError {
            XCTAssertEqual(e, .networkError)
        } catch {
            XCTFail()
        }
    }

    // MARK: Cube Lab
    func testCubeLabServiceSaveLoad() throws {
        let ms = MockStorageService()
        let s = CubeLabService(storage: ms)
        let settings = CubeSettings(rotationSpeed: 1.5, isRotating: false)
        try s.saveSettings(settings)
        let loaded = s.loadSettings()
        XCTAssertEqual(loaded.rotationSpeed, 1.5)
        XCTAssertEqual(loaded.isRotating, false)
    }

    func testCubeLabServiceReset() throws {
        let ms = MockStorageService()
        let s = CubeLabService(storage: ms)
        try s.saveSettings(CubeSettings(rotationSpeed: 2.0))
        try s.resetSettings()
        let loaded = s.loadSettings()
        XCTAssertEqual(loaded.rotationSpeed, CubeSettings.defaultSpeed)
    }

    // MARK: Telemetry
    func testTelemetryStream() async {
        let s = TelemetryService()
        let stream = s.startStreaming(interval: 0.5, maxHistory: 20)
        var count = 0
        for await point in stream {
            XCTAssertEqual(point.unit, "km/s")
            count += 1
            if count >= 2 { break }
        }
    }

    func testTelemetryHistoryLimit() {
        var points: [TelemetryPoint] = []
        for i in 0..<25 {
            points.append(TelemetryPoint(timestamp: Date(), value: Double(i), unit: "km/s"))
        }
        let limited = points.suffix(20)
        XCTAssertEqual(limited.count, 20)
    }

    // MARK: Settings
    func testSettingsServiceSaveLoad() throws {
        let ms = MockStorageService()
        let s = SettingsService(storage: ms)
        let settings = AppSettings(accentColor: .systemPurple, hapticFeedbackEnabled: false)
        try s.saveSettings(settings)
        let loaded = s.loadSettings()
        XCTAssertEqual(loaded.accentColor, .systemPurple)
        XCTAssertEqual(loaded.hapticFeedbackEnabled, false)
    }

    // MARK: Storage
    func testStorageService() throws {
        let ms = MockStorageService()
        try ms.save("test", forKey: "k1")
        let v: String? = try ms.load(forKey: "k1")
        XCTAssertEqual(v, "test")
        try ms.remove(forKey: "k1")
        let v2: String? = try ms.load(forKey: "k1")
        XCTAssertNil(v2)
    }

    // MARK: Models
    func testMissionEventEquatable() {
        let u = UUID()
        let date = Date()
        let e1 = MissionEvent(id: u, timestamp: date, missionName: "A", status: .completed, description: "B")
        let e2 = MissionEvent(id: u, timestamp: date, missionName: "A", status: .completed, description: "B")
        XCTAssertEqual(e1, e2)
    }

    func testCubeSettingsDefault() {
        let s = CubeSettings()
        XCTAssertEqual(s.rotationSpeed, CubeSettings.defaultSpeed)
        XCTAssertEqual(s.isRotating, true)
    }

    // MARK: Edge Cases
    func testEmptyGraph() {
        let points: [TelemetryPoint] = []
        XCTAssertEqual(points.count, 0)
    }

    func testMissionMetricsCodable() throws {
        let m = MissionMetrics(totalMissions: 10, successfulMissions: 8, activeMissions: 2, averageDuration: 3600)
        let data = try JSONEncoder().encode(m)
        let decoded = try JSONDecoder().decode(MissionMetrics.self, from: data)
        XCTAssertEqual(decoded.totalMissions, 10)
    }
}
