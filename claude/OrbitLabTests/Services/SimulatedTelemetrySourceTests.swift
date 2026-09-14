import XCTest
@testable import OrbitLab

final class SimulatedTelemetrySourceTests: XCTestCase {
    func test_streamEmitsDeterministicSamplesAndFinishesWhenTheTickerStops() async {
        let source = SimulatedTelemetrySource(makeTicker: { _ in ImmediateTicker(limit: 5) })

        var received: [TelemetrySample] = []
        for await sample in source.samples(cadence: .standard) {
            received.append(sample)
        }

        XCTAssertEqual(received.count, 5)
        XCTAssertEqual(received.map(\.id), [0, 1, 2, 3, 4])
        XCTAssertEqual(
            received.map(\.value),
            (0..<5).map { SimulatedTelemetrySource.value(at: $0, in: .thrust) }
        )
    }

    func test_generatedValuesStayInsideTheChannelRange() {
        let range = TelemetryChannel.thrust.range
        for index in 0..<500 {
            let value = SimulatedTelemetrySource.value(at: index, in: .thrust)
            XCTAssertTrue(range.contains(value), "Value \(value) at index \(index) escaped \(range)")
        }
    }

    func test_cancellingTheConsumingTaskStopsTheProducer() async {
        let source = SimulatedTelemetrySource(makeTicker: { _ in ImmediateTicker(limit: .max) })

        let task = Task {
            var count = 0
            for await _ in source.samples(cadence: .standard) {
                count += 1
                if count == 3 { break }
            }
            return count
        }

        let count = await task.value
        XCTAssertEqual(count, 3, "Breaking out of the loop must tear the stream down")
    }
}
