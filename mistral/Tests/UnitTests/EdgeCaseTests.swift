import XCTest
import SceneKit
@testable import OrbitLab

final class EdgeCaseTests: XCTestCase {
    
    func testEmptyDashboardMetrics() {
        let emptyDashboard = MissionDashboard(
            status: .nominal,
            metrics: [],
            recentEvents: [],
            lastUpdated: Date()
        )
        let mockService = MockMissionService(behavior: .success, fixedDashboard: emptyDashboard)
        let viewModel = MissionControlViewModel(missionService: mockService)
        viewModel.loadData()
        
        let expectation = XCTestExpectation(description: "Loading completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        XCTWaiter.wait(for: [expectation], timeout: 1.0)
        
        switch viewModel.state {
        case .content(let dashboard):
            XCTAssertEqual(dashboard.metrics.count, 0)
        default:
            XCTFail("Expected content state")
        }
    }
    
    func testEmptyTelemetryHistory() {
        let mockService = MockTelemetryService()
        let viewModel = TelemetryViewModel(telemetryService: mockService, reducedFrequency: false)
        XCTAssertEqual(viewModel.dataPoints.count, 0)
    }
    
    func testServiceWithUnknownError() {
        let mockService = MockMissionService(behavior: .failure(.unknownError))
        let viewModel = MissionControlViewModel(missionService: mockService)
        viewModel.loadData()
        
        let expectation = XCTestExpectation(description: "Error received")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        XCTWaiter.wait(for: [expectation], timeout: 1.0)
        
        switch viewModel.state {
        case .error(let error):
            XCTAssertEqual(error, MissionServiceError.unknownError)
            XCTAssertNotNil(error.errorDescription)
        default:
            XCTFail("Expected error state")
        }
    }
    
    func testCodableWithSpecialCharacters() {
        let event = MissionEvent(
            timestamp: Date(),
            type: .sensorCalibration,
            description: "Test with quotes",
            severity: .info
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(event)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decodedEvent = try decoder.decode(MissionEvent.self, from: data)
            XCTAssertEqual(event.id, decodedEvent.id)
            XCTAssertEqual(event.type, decodedEvent.type)
        } catch {
            XCTFail("Failed to encode/decode event")
        }
    }
    
    func testSCNVectorCodable() {
        let vector4 = SCNVector4(1.0, 2.0, 3.0, 4.0)
        let vector3 = SCNVector3(5.0, 6.0, 7.0)
        
        do {
            let encoder = JSONEncoder()
            let data4 = try encoder.encode(vector4)
            let decoder = JSONDecoder()
            let decoded4 = try decoder.decode(SCNVector4.self, from: data4)
            XCTAssertEqual(vector4.x, decoded4.x)
            XCTAssertEqual(vector4.y, decoded4.y)
            
            let data3 = try encoder.encode(vector3)
            let decoded3 = try decoder.decode(SCNVector3.self, from: data3)
            XCTAssertEqual(vector3.x, decoded3.x)
            XCTAssertEqual(vector3.y, decoded3.y)
        } catch {
            XCTFail("Failed to encode/decode SCNVector")
        }
    }
}
