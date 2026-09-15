import Foundation
import SwiftUI
import Combine

// MARK: - Telemetry View Model

/// ViewModel for Telemetry tab
class TelemetryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var dataPoints: [TelemetryDataPoint] = []
    @Published private(set) var currentValue: Double = 0
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isPaused: Bool = false
    @Published var showClearConfirmation = false
    
    // MARK: - Public Properties
    
    let maxHistoryCount = 50
    var reducedFrequency: Bool = false
    
    var interval: TimeInterval {
        reducedFrequency ? 1.0 : 0.5
    }
    
    // MARK: - Private Properties
    
    private let telemetryService: TelemetryServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var streamTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    /// Initialize with a telemetry service
    /// - Parameters:
    ///   - telemetryService: The service to provide telemetry data
    ///   - reducedFrequency: Whether to use reduced frequency
    init(telemetryService: TelemetryServiceProtocol = ProductionTelemetryService(),
         reducedFrequency: Bool = false) {
        self.telemetryService = telemetryService
        self.reducedFrequency = reducedFrequency
        
        setupSubscriptions()
    }
    
    deinit {
        streamTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Starts the telemetry stream
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        isPaused = false
        
        telemetryService.startStream(
            interval: interval,
            maxCount: maxHistoryCount
        )
        
        subscribeToUpdates()
    }
    
    /// Pauses the telemetry stream
    func pause() {
        guard isRunning, !isPaused else { return }
        
        isPaused = true
        telemetryService.pauseStream()
    }
    
    /// Resumes the telemetry stream
    func resume() {
        guard isRunning, isPaused else { return }
        
        isPaused = false
        telemetryService.resumeStream()
    }
    
    /// Stops the telemetry stream
    func stop() {
        guard isRunning else { return }
        
        isRunning = false
        isPaused = false
        
        telemetryService.stopStream()
    }
    
    /// Clears all telemetry data
    func clear() {
        telemetryService.clearData()
    }
    
    /// Toggles the stream (start if stopped, stop if running)
    func toggle() {
        if isRunning {
            stop()
        } else {
            start()
        }
    }
    
    /// Updates the reduced frequency setting
    /// - Parameter reduced: Whether to use reduced frequency
    func setReducedFrequency(_ reduced: Bool) {
        reducedFrequency = reduced
        
        // If running, restart with new interval
        if isRunning {
            stop()
            start()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Subscribe to state changes from the service
        telemetryService.subscribe(to: { [weak self] dataPoint in
            DispatchQueue.main.async {
                self?.handleNewDataPoint(dataPoint)
            }
        })
    }
    
    private func subscribeToUpdates() {
        // The service already notifies via subscription
    }
    
    @MainActor
    private func handleNewDataPoint(_ dataPoint: TelemetryDataPoint) {
        dataPoints.append(dataPoint)
        currentValue = dataPoint.value
        
        if dataPoints.count > maxHistoryCount {
            dataPoints.removeFirst()
        }
    }
}

// MARK: - Preview View Model

final class PreviewTelemetryViewModel: TelemetryViewModel {
    init() {
        super.init(telemetryService: PreviewTelemetryService(), reducedFrequency: false)
    }
}
