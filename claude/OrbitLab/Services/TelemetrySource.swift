import Foundation

/// Produces telemetry samples as an async sequence.
///
/// The view model never creates timers itself, which is what keeps its tests instant.
protocol TelemetrySource: Sendable {
    func samples(cadence: TelemetryCadence) -> AsyncStream<TelemetrySample>
}

/// The pacing seam of the stream. Production sleeps; tests return immediately.
protocol TelemetryTicker: Sendable {
    /// Suspends until the next sample is due. Throws on cancellation.
    func tick() async throws
}

/// Production ticker.
struct IntervalTicker: TelemetryTicker {
    let nanoseconds: UInt64

    func tick() async throws {
        try await Task.sleep(nanoseconds: nanoseconds)
    }
}

/// Production telemetry: a deterministic waveform paced by an injected ticker.
///
/// Values are a function of the sample index only, so a run is always reproducible.
struct SimulatedTelemetrySource: TelemetrySource {
    private let channel: TelemetryChannel
    private let makeTicker: @Sendable (TelemetryCadence) -> TelemetryTicker

    init(
        channel: TelemetryChannel = .thrust,
        makeTicker: @escaping @Sendable (TelemetryCadence) -> TelemetryTicker = { IntervalTicker(nanoseconds: $0.nanoseconds) }
    ) {
        self.channel = channel
        self.makeTicker = makeTicker
    }

    func samples(cadence: TelemetryCadence) -> AsyncStream<TelemetrySample> {
        let channel = self.channel
        let ticker = makeTicker(cadence)
        return AsyncStream { continuation in
            let task = Task.detached(priority: .utility) {
                var index = 0
                while !Task.isCancelled {
                    do {
                        try await ticker.tick()
                    } catch {
                        break
                    }
                    guard !Task.isCancelled else { break }
                    continuation.yield(TelemetrySample(id: index, value: Self.value(at: index, in: channel), channel: channel))
                    index += 1
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Smooth, bounded, index-driven waveform. No randomness, no wall clock.
    static func value(at index: Int, in channel: TelemetryChannel) -> Double {
        let range = channel.range
        let phase = Double(index)
        let base = sin(phase / 6.0) * 0.32 + sin(phase / 2.3) * 0.1 + sin(phase / 17.0) * 0.08
        let normalised = min(max(0.55 + base, 0.0), 1.0)
        return range.lowerBound + normalised * (range.upperBound - range.lowerBound)
    }
}
