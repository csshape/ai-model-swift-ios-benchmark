import XCTest
@testable import OrbitLab

@MainActor
final class TelemetryViewModelTests: XCTestCase {
    func test_start_receivesSamplesAndPauseCancelsTheStream() async {
        let source = ControlledTelemetrySource()
        let viewModel = TelemetryViewModel(source: source, cadence: .standard)

        viewModel.start()
        XCTAssertTrue(viewModel.isStreaming)
        XCTAssertEqual(source.requestedCadences, [.standard])

        source.emit(42)
        source.emit(43)
        await waitUntil({ viewModel.samples.count == 2 }, message: "Samples never arrived")

        XCTAssertEqual(viewModel.samples.map(\.value), [42, 43])
        XCTAssertEqual(viewModel.currentSample?.value, 43)

        let task = viewModel.streamTask
        viewModel.pause()
        XCTAssertFalse(viewModel.isStreaming)

        await task?.value
        XCTAssertEqual(source.terminationCount, 1, "Pausing must cancel the underlying stream")
    }

    func test_startIsIgnoredWhileAlreadyStreaming() async {
        let source = ControlledTelemetrySource()
        let viewModel = TelemetryViewModel(source: source, cadence: .standard)

        viewModel.start()
        viewModel.start()

        XCTAssertEqual(source.requestedCadences.count, 1)

        viewModel.pause()
        await viewModel.streamTask?.value
    }

    func test_historyIsTrimmedToTheRetentionLimit() async {
        let source = ControlledTelemetrySource()
        let viewModel = TelemetryViewModel(source: source, cadence: .standard)
        let overflow = 12

        let total = TelemetryViewModel.historyLimit + overflow

        viewModel.start()
        for index in 0..<total {
            source.emit(Double(index))
        }
        // The history caps out at the limit, so the newest sample is what tells us the
        // view model has drained everything the source produced.
        await waitUntil(
            { viewModel.samples.last?.value == Double(total - 1) },
            message: "The view model never drained the source"
        )

        XCTAssertEqual(viewModel.samples.count, TelemetryViewModel.historyLimit)
        XCTAssertEqual(viewModel.samples.first?.value, Double(overflow), "Oldest samples must be dropped first")
        XCTAssertEqual(viewModel.samples.last?.value, Double(TelemetryViewModel.historyLimit + overflow - 1))
        XCTAssertGreaterThanOrEqual(TelemetryViewModel.historyLimit, 20)

        viewModel.pause()
        await viewModel.streamTask?.value
    }

    func test_clearEmptiesTheHistoryWithoutStoppingTheStream() async {
        let source = ControlledTelemetrySource()
        let viewModel = TelemetryViewModel(source: source, cadence: .standard)

        viewModel.start()
        source.emit(1)
        await waitUntil({ viewModel.samples.count == 1 })

        viewModel.clear()

        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertTrue(viewModel.isStreaming)

        viewModel.pause()
        await viewModel.streamTask?.value
    }

    func test_streamFinishingOnItsOwnStopsTheStreamingState() async {
        let source = ControlledTelemetrySource()
        let viewModel = TelemetryViewModel(source: source, cadence: .standard)

        viewModel.start()
        source.emit(7)
        source.finish()

        await waitUntil({ viewModel.isStreaming == false }, message: "Stream end was not observed")
        XCTAssertEqual(viewModel.samples.map(\.value), [7])
    }

    func test_cadenceChangeRestartsAnActiveStreamWithTheNewCadence() async {
        let source = ControlledTelemetrySource()
        let viewModel = TelemetryViewModel(source: source, cadence: .standard)

        viewModel.start()
        viewModel.updateCadence(.reduced)

        XCTAssertEqual(source.requestedCadences, [.standard, .reduced])
        XCTAssertEqual(viewModel.activeCadence, .reduced)
        XCTAssertTrue(viewModel.isStreaming)

        viewModel.pause()
        await viewModel.streamTask?.value
    }

    /// Edge case: changing cadence while paused must not secretly start the stream.
    func test_cadenceChangeWhilePausedDoesNotStartStreaming() async {
        let source = ControlledTelemetrySource()
        let viewModel = TelemetryViewModel(source: source, cadence: .standard)

        viewModel.updateCadence(.reduced)

        XCTAssertFalse(viewModel.isStreaming)
        XCTAssertTrue(source.requestedCadences.isEmpty)
        XCTAssertEqual(viewModel.activeCadence, .reduced)
    }
}
