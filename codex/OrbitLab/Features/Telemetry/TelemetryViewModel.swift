import Foundation

@MainActor
final class TelemetryViewModel: ObservableObject {
    let maxHistoryCount = 20

    @Published private(set) var current: TelemetryPoint?
    @Published private(set) var history: [TelemetryPoint] = []
    @Published private(set) var isRunning = false

    private let service: TelemetryStreaming
    private var reducedFrequency = false
    private var streamTask: Task<Void, Never>?

    init(service: TelemetryStreaming) {
        self.service = service
    }

    deinit {
        streamTask?.cancel()
    }

    func start(reducedFrequency: Bool) {
        self.reducedFrequency = reducedFrequency

        guard streamTask == nil else {
            return
        }

        isRunning = true

        streamTask = Task { [weak self] in
            guard let self else {
                return
            }

            let stream = service.makeStream(reducedFrequency: reducedFrequency)

            for await point in stream {
                if Task.isCancelled {
                    break
                }
                record(point)
            }

            if !Task.isCancelled {
                isRunning = false
                streamTask = nil
            }
        }
    }

    func pause() {
        streamTask?.cancel()
        streamTask = nil
        isRunning = false
    }

    func clear() {
        current = nil
        history.removeAll()
    }

    func updateReducedFrequency(_ reducedFrequency: Bool) {
        guard reducedFrequency != self.reducedFrequency else {
            return
        }

        let shouldRestart = isRunning
        pause()
        self.reducedFrequency = reducedFrequency

        if shouldRestart {
            start(reducedFrequency: reducedFrequency)
        }
    }

    func waitForCurrentStreamToFinish() async {
        let task = streamTask
        await task?.value
    }

    private func record(_ point: TelemetryPoint) {
        current = point
        history.append(point)

        if history.count > maxHistoryCount {
            history.removeFirst(history.count - maxHistoryCount)
        }
    }
}
