import Foundation

protocol TelemetryServiceProtocol {
    func startStreaming(interval: TimeInterval, maxHistory: Int) -> AsyncStream<TelemetryPoint>
}

class TelemetryService: TelemetryServiceProtocol {
    func startStreaming(interval: TimeInterval, maxHistory: Int) -> AsyncStream<TelemetryPoint> {
        AsyncStream { continuation in
            let start = Date()
            var seq = 0
            let task = Task {
                while !Task.isCancelled {
                    let point = TelemetryPoint(
                        timestamp: Calendar.current.date(byAdding: .second, value: seq, to: start) ?? start,
                        value: 100.0 + 50.0 * sin(Double(seq) * 0.2),
                        unit: "km/s"
                    )
                    continuation.yield(point)
                    seq += 1
                    try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                }
                continuation.finish()
            }
            continuation.onTermination = { @Sendable _ in task.cancel() }
        }
    }
}

class MockTelemetryService: TelemetryServiceProtocol {
    var points: [TelemetryPoint] = []
    var index = 0
    func startStreaming(interval: TimeInterval, maxHistory: Int) -> AsyncStream<TelemetryPoint> {
        AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled && index < points.count {
                    continuation.yield(points[index])
                    index += 1
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                continuation.finish()
            }
            continuation.onTermination = { @Sendable _ in task.cancel() }
        }
    }
}
