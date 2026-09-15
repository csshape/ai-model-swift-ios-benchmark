import XCTest
@testable import OrbitLab

final class TelemetryTests: XCTestCase {
    
    func testStartReceivingValues() {
        let mockService = MockTelemetryService()
        let viewModel = TelemetryViewModel(telemetryService: mockService, reducedFrequency: false)
        viewModel.start()
        XCTAssertTrue(viewModel.isRunning)
        XCTAssertEqual(mockService.startCount, 1)
    }
    
    func testPauseStopsReceiving() {
        let mockService = MockTelemetryService()
        let viewModel = TelemetryViewModel(telemetryService: mockService, reducedFrequency: false)
        viewModel.start()
        viewModel.pause()
        XCTAssertTrue(viewModel.isPaused)
        XCTAssertEqual(mockService.pauseCount, 1)
    }
    
    func testStopCancelsStream() {
        let mockService = MockTelemetryService()
        let viewModel = TelemetryViewModel(telemetryService: mockService, reducedFrequency: false)
        viewModel.start()
        viewModel.stop()
        XCTAssertFalse(viewModel.isRunning)
        XCTAssertEqual(mockService.stopCount, 1)
    }
    
    func testHistoryCappingAt50() {
        let viewModel = TelemetryViewModel(
            telemetryService: MockTelemetryService(),
            reducedFrequency: false
        )
        XCTAssertEqual(viewModel.maxHistoryCount, 50)
    }
    
    func testToggleStartsAndStops() {
        let mockService = MockTelemetryService()
        let viewModel = TelemetryViewModel(telemetryService: mockService, reducedFrequency: false)
        XCTAssertFalse(viewModel.isRunning)
        viewModel.toggle()
        XCTAssertTrue(viewModel.isRunning)
        viewModel.toggle()
        XCTAssertFalse(viewModel.isRunning)
    }
    
    func testClearData() {
        let mockService = MockTelemetryService()
        let viewModel = TelemetryViewModel(telemetryService: mockService, reducedFrequency: false)
        viewModel.clear()
        XCTAssertEqual(mockService.clearCount, 1)
    }
}
