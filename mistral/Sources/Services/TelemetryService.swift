import Foundation

// MARK: - Telemetry Service Protocol

protocol TelemetryServiceProtocol {
    /// Starts the telemetry stream
    /// - Parameter interval: Time interval between data points in seconds
    /// - Parameter maxCount: Maximum number of data points to keep in history
    func startStream(interval: TimeInterval, maxCount: Int)
    
    /// Stops the telemetry stream
    func stopStream()
    
    /// Pauses the telemetry stream
    func pauseStream()
    
    /// Resumes the telemetry stream
    func resumeStream()
    
    /// Clears all telemetry data
    func clearData()
    
    /// Subscribes to telemetry data updates
    /// - Parameter handler: Closure to call when new data is available
    func subscribe(to handler: @escaping (TelemetryDataPoint) -> Void)
    
    /// Unsubscribes from telemetry data updates
    /// - Parameter handler: The handler to remove
    func unsubscribe(from handler: @escaping (TelemetryDataPoint) -> Void)
    
    /// Gets the current telemetry state
    var currentState: TelemetryState { get }
}

// MARK: - Production Implementation

final class ProductionTelemetryService: TelemetryServiceProtocol {
    @Published private(set) var currentState: TelemetryState
    private var streamTask: Task<Void, Never>?
    private var subscribers: [(TelemetryDataPoint) -> Void] = []
    private var isPaused: Bool = false
    private var interval: TimeInterval = 0.5
    private var maxCount: Int = 50
    
    init() {
        self.currentState = TelemetryState()
    }
    
    deinit {
        streamTask?.cancel()
        streamTask = nil
    }
    
    func startStream(interval: TimeInterval, maxCount: Int) {
        stopStream()
        
        self.interval = interval
        self.maxCount = maxCount
        self.currentState.maxHistoryCount = maxCount
        self.isPaused = false
        
        streamTask = Task { [weak self] in
            guard let self = self else { return }
            
            while !Task.isCancelled {
                if !self.isPaused {
                    await self.generateAndEmitDataPoint()
                }
                
                do {
                    try await Task.sleep(nanoseconds: UInt64(self.interval * 1_000_000_000))
                } catch {
                    break
                }
            }
        }
    }
    
    func stopStream() {
        streamTask?.cancel()
        streamTask = nil
        isPaused = false
    }
    
    func pauseStream() {
        isPaused = true
    }
    
    func resumeStream() {
        isPaused = false
    }
    
    func clearData() {
        currentState.clear()
    }
    
    func subscribe(to handler: @escaping (TelemetryDataPoint) -> Void) {
        subscribers.append(handler)
    }
    
    func unsubscribe(from handler: @escaping (TelemetryDataPoint) -> Void) {
        subscribers.removeAll { $0 as AnyObject === handler as AnyObject }
    }
    
    @MainActor
    private func generateAndEmitDataPoint() {
        let now = Date()
        let randomValue = Double.random(in: 0...100)
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        let timeString = formatter.string(from: now)
        
        let label = "Signal at \(timeString)"
        let dataPoint = TelemetryDataPoint(
            timestamp: now,
            value: randomValue,
            label: label
        )
        
        currentState.addDataPoint(dataPoint)
        
        for handler in subscribers {
            handler(dataPoint)
        }
    }
}

// MARK: - Test Double (Mock)

final class MockTelemetryService: TelemetryServiceProtocol {
    @Published private(set) var currentState: TelemetryState
    
    private var isRunning: Bool = false
    private var isPaused: Bool = false
    private var subscribers: [(TelemetryDataPoint) -> Void] = []
    
    var startCount: Int = 0
    var stopCount: Int = 0
    var pauseCount: Int = 0
    var resumeCount: Int = 0
    var clearCount: Int = 0
    
    var lastInterval: TimeInterval?
    var lastMaxCount: Int?
    
    init(initialState: TelemetryState = TelemetryState()) {
        self.currentState = initialState
    }
    
    func startStream(interval: TimeInterval, maxCount: Int) {
        startCount += 1
        lastInterval = interval
        lastMaxCount = maxCount
        isRunning = true
        isPaused = false
        currentState.maxHistoryCount = maxCount
    }
    
    func stopStream() {
        stopCount += 1
        isRunning = false
        isPaused = false
    }
    
    func pauseStream() {
        pauseCount += 1
        isPaused = true
    }
    
    func resumeStream() {
        resumeCount += 1
        isPaused = false
    }
    
    func clearData() {
        clearCount += 1
        currentState.clear()
    }
    
    func subscribe(to handler: @escaping (TelemetryDataPoint) -> Void) {
        subscribers.append(handler)
    }
    
    func unsubscribe(from handler: @escaping (TelemetryDataPoint) -> Void) {
        subscribers.removeAll { $0 as AnyObject === handler as AnyObject }
    }
    
    /// Manually emit a data point (for testing)
    func emitDataPoint(_ point: TelemetryDataPoint) {
        currentState.addDataPoint(point)
        for handler in subscribers {
            handler(point)
        }
    }
    
    /// Reset all counters
    func resetCounters() {
        startCount = 0
        stopCount = 0
        pauseCount = 0
        resumeCount = 0
        clearCount = 0
    }
}

// MARK: - Preview Service

final class PreviewTelemetryService: TelemetryServiceProtocol {
    @Published private(set) var currentState: TelemetryState
    
    private var subscribers: [(TelemetryDataPoint) -> Void] = []
    
    init() {
        let now = Date()
        let calendar = Calendar.current
        
        // Create sample history
        var dataPoints: [TelemetryDataPoint] = []
        for i in 0..<20 {
            let minutesAgo = Double(i * 2)
            let pastDate = calendar.date(byAdding: .minute, value: -Int(minutesAgo), to: now)!
            let value = 50.0 + Double(i) * 2.0
            dataPoints.append(TelemetryDataPoint(
                timestamp: pastDate,
                value: value,
                label: "Sample \(i)"
            ))
        }
        
        self.currentState = TelemetryState(
            dataPoints: dataPoints.reversed(),
            currentValue: 90.0,
            isRunning: false
        )
    }
    
    func startStream(interval: TimeInterval, maxCount: Int) { }
    func stopStream() { }
    func pauseStream() { }
    func resumeStream() { }
    func clearData() { }
    func subscribe(to handler: @escaping (TelemetryDataPoint) -> Void) { }
    func unsubscribe(from handler: @escaping (TelemetryDataPoint) -> Void) { }
}
