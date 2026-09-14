import Foundation

/// Consumes the telemetry stream and keeps a bounded history for the chart.
@MainActor
final class TelemetryViewModel: ObservableObject {
    /// How many samples are kept. The chart needs at least 20; 60 gives a readable trace.
    static let historyLimit = 60

    @Published private(set) var samples: [TelemetrySample] = []
    @Published private(set) var isStreaming = false

    let channel: TelemetryChannel

    /// Exposed so tests can await the consuming task instead of sleeping.
    private(set) var streamTask: Task<Void, Never>?

    private let source: TelemetrySource
    private var cadence: TelemetryCadence
    /// Guards against a task from a previous run reporting back after a restart.
    private var generation = 0

    init(source: TelemetrySource, cadence: TelemetryCadence, channel: TelemetryChannel = .thrust) {
        self.source = source
        self.cadence = cadence
        self.channel = channel
    }

    var currentSample: TelemetrySample? { samples.last }

    var isEmpty: Bool { samples.isEmpty }

    var activeCadence: TelemetryCadence { cadence }

    func start() {
        guard !isStreaming else { return }
        isStreaming = true
        generation += 1
        let generation = self.generation
        // The stream is created synchronously so no sample can be produced before it exists.
        let stream = source.samples(cadence: cadence)
        streamTask = Task { [weak self] in
            for await sample in stream {
                guard let self = self, self.generation == generation else { return }
                self.append(sample)
            }
            self?.handleStreamEnded(generation: generation)
        }
    }

    func pause() {
        guard isStreaming else { return }
        isStreaming = false
        streamTask?.cancel()
    }

    func clear() {
        samples.removeAll()
    }

    /// Applies a cadence change from Settings, restarting the stream only when it is running.
    func updateCadence(_ newCadence: TelemetryCadence) {
        guard newCadence != cadence else { return }
        cadence = newCadence
        guard isStreaming else { return }
        pause()
        start()
    }

    private func append(_ sample: TelemetrySample) {
        samples.append(sample)
        if samples.count > Self.historyLimit {
            samples.removeFirst(samples.count - Self.historyLimit)
        }
    }

    private func handleStreamEnded(generation: Int) {
        guard generation == self.generation else { return }
        isStreaming = false
        streamTask = nil
    }
}
