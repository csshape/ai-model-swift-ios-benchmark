import XCTest
@testable import OrbitLab

final class MissionControlTests: XCTestCase {
    
    func testLoadingToContentStateSuccess() {
        let mockService = MockMissionService(behavior: .success)
        let viewModel = MissionControlViewModel(missionService: mockService)
        viewModel.loadData()
        
        let expectation = XCTestExpectation(description: "Loading completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        XCTWaiter.wait(for: [expectation], timeout: 1.0)
        
        switch viewModel.state {
        case .content(let dashboard):
            XCTAssertNotNil(dashboard)
            XCTAssertEqual(mockService.callCount, 1)
        default:
            XCTFail("Expected content state")
        }
    }
    
    func testErrorStateOnServiceFailure() {
        let mockService = MockMissionService(behavior: .failure(.dataUnavailable))
        let viewModel = MissionControlViewModel(missionService: mockService)
        viewModel.loadData()
        
        let expectation = XCTestExpectation(description: "Error received")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        XCTWaiter.wait(for: [expectation], timeout: 1.0)
        
        switch viewModel.state {
        case .error(let error):
            XCTAssertEqual(error, MissionServiceError.dataUnavailable)
        default:
            XCTFail("Expected error state")
        }
    }
    
    func testSampleDataGeneration() {
        let dashboard = SampleMissionData.generateDashboard()
        XCTAssertNotNil(dashboard)
        XCTAssertEqual(dashboard.metrics.count, 3)
    }
}
