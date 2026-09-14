import Foundation

protocol TelemetryStreaming {
    func makeStream(reducedFrequency: Bool) -> AsyncStream<TelemetryPoint>
}

struct DeterministicTelemetryService: TelemetryStreaming {
    private let baseTimestamp = Date(timeIntervalSince1970: 1_789_370_400)

    func makeStream(reducedFrequency: Bool) -> AsyncStream<TelemetryPoint> {
        let interval: UInt64 = reducedFrequency ? 1_200_000_000 : 450_000_000
        let baseTimestamp = baseTimestamp

        return AsyncStream { continuation in
            let task = Task.detached(priority: .utility) {
                var index = 0

                while !Task.isCancelled {
                    continuation.yield(
                        TelemetryPoint(
                            id: index,
                            timestamp: baseTimestamp.addingTimeInterval(TimeInterval(index)),
                            value: Self.value(for: index)
                        )
                    )
                    index += 1

                    do {
                        try await Task.sleep(nanoseconds: interval)
                    } catch {
                        break
                    }
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    static func value(for index: Int) -> Double {
        52.0 + sin(Double(index) * 0.47) * 16.0 + cos(Double(index) * 0.19) * 6.0
    }
}
