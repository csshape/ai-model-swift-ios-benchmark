import XCTest
@testable import OrbitLab

@MainActor
final class TelemetryViewModelTests: XCTestCase {
    func testStartReceivesValuesThenPauseCancelsStream() async {
        let service = ManualTelemetryService()
        let viewModel = TelemetryViewModel(service: service)

        viewModel.start(reducedFrequency: false)
        await Task.yield()

        service.yield(telemetryPoint(0, value: 42.5))
        await Task.yield()

        XCTAssertTrue(viewModel.isRunning)
        XCTAssertEqual(viewModel.current?.value, 42.5)
        XCTAssertEqual(viewModel.history.count, 1)

        viewModel.pause()

        for _ in 0..<5 {
            await Task.yield()
        }

        XCTAssertFalse(viewModel.isRunning)
        XCTAssertTrue(service.wasCancelled)
    }

    func testHistoryIsLimitedToMostRecentTwentyValues() async {
        let points = (0..<25).map { telemetryPoint($0) }
        let service = ArrayTelemetryService(points: points)
        let viewModel = TelemetryViewModel(service: service)

        viewModel.start(reducedFrequency: false)
        await viewModel.waitForCurrentStreamToFinish()

        XCTAssertEqual(viewModel.history.count, 20)
        XCTAssertEqual(viewModel.history.first?.id, 5)
        XCTAssertEqual(viewModel.history.last?.id, 24)
        XCTAssertEqual(viewModel.current?.id, 24)
    }
}

private final class ManualTelemetryService: TelemetryStreaming {
    private var continuation: AsyncStream<TelemetryPoint>.Continuation?
    private(set) var wasCancelled = false

    func makeStream(reducedFrequency: Bool) -> AsyncStream<TelemetryPoint> {
        AsyncStream { continuation in
            self.continuation = continuation
            continuation.onTermination = { termination in
                if case .cancelled = termination {
                    self.wasCancelled = true
                }
            }
        }
    }

    func yield(_ point: TelemetryPoint) {
        continuation?.yield(point)
    }
}

private struct ArrayTelemetryService: TelemetryStreaming {
    let points: [TelemetryPoint]

    func makeStream(reducedFrequency: Bool) -> AsyncStream<TelemetryPoint> {
        AsyncStream { continuation in
            points.forEach { continuation.yield($0) }
            continuation.finish()
        }
    }
}
