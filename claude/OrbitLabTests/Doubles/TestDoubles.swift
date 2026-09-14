import Foundation
@testable import OrbitLab

/// Returns a queued sequence of results. The final response repeats, so a test only has to
/// describe the responses it cares about.
final class StubMissionService: MissionService, @unchecked Sendable {
    enum Response {
        case success(MissionSnapshot)
        case failure(Error)
    }

    private let lock = NSLock()
    private var responses: [Response]
    private var calls = 0

    init(responses: [Response]) {
        precondition(!responses.isEmpty, "A stub needs at least one response")
        self.responses = responses
    }

    convenience init(snapshot: MissionSnapshot) {
        self.init(responses: [.success(snapshot)])
    }

    var callCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return calls
    }

    func loadSnapshot() async throws -> MissionSnapshot {
        lock.lock()
        calls += 1
        let response = responses.count > 1 ? responses.removeFirst() : responses[0]
        lock.unlock()

        switch response {
        case let .success(snapshot): return snapshot
        case let .failure(error): throw error
        }
    }
}

/// A telemetry source the test drives by hand: no timers, no waiting.
final class ControlledTelemetrySource: TelemetrySource, @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: AsyncStream<TelemetrySample>.Continuation?
    private var cadences: [TelemetryCadence] = []
    private var terminations = 0
    private var nextID = 0

    func samples(cadence: TelemetryCadence) -> AsyncStream<TelemetrySample> {
        AsyncStream { continuation in
            lock.lock()
            cadences.append(cadence)
            self.continuation = continuation
            lock.unlock()

            continuation.onTermination = { [weak self] _ in
                guard let self = self else { return }
                self.lock.lock()
                self.terminations += 1
                self.lock.unlock()
            }
        }
    }

    @discardableResult
    func emit(_ value: Double) -> TelemetrySample {
        lock.lock()
        let sample = TelemetrySample(id: nextID, value: value)
        nextID += 1
        let continuation = self.continuation
        lock.unlock()
        continuation?.yield(sample)
        return sample
    }

    func finish() {
        lock.lock()
        let continuation = self.continuation
        lock.unlock()
        continuation?.finish()
    }

    var requestedCadences: [TelemetryCadence] {
        lock.lock()
        defer { lock.unlock() }
        return cadences
    }

    var terminationCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return terminations
    }
}

/// Ticks instantly a fixed number of times and then reports cancellation, which ends the
/// stream without any real delay.
final class ImmediateTicker: TelemetryTicker, @unchecked Sendable {
    private let limit: Int
    private let lock = NSLock()
    private var ticks = 0

    init(limit: Int) {
        self.limit = limit
    }

    func tick() async throws {
        lock.lock()
        defer { lock.unlock() }
        guard ticks < limit else { throw CancellationError() }
        ticks += 1
    }
}

/// Records what was written so persistence can be asserted without `UserDefaults`.
final class RecordingKeyValueStore: KeyValueStore {
    private var storage: [String: Data]
    private(set) var writeCount = 0
    private(set) var removeAllCount = 0

    init(storage: [String: Data] = [:]) {
        self.storage = storage
    }

    func data(forKey key: String) -> Data? {
        storage[key]
    }

    func setData(_ data: Data?, forKey key: String) {
        writeCount += 1
        storage[key] = data
    }

    func removeAll() {
        removeAllCount += 1
        storage.removeAll()
    }

    func seed(_ json: String, forKey key: String) {
        storage[key] = Data(json.utf8)
    }
}
