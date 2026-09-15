import Foundation

// MARK: - Mission Service Protocol

protocol MissionServiceProtocol {
    /// Fetches the current mission dashboard data
    /// - Returns: MissionDashboard containing status, metrics, and events
    func fetchDashboard() async throws -> MissionDashboard
}

// MARK: - Error Types

enum MissionServiceError: Error, LocalizedError {
    case dataUnavailable
    case communicationFailed
    case decodingFailed
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .dataUnavailable:
            return "Mission data is temporarily unavailable"
        case .communicationFailed:
            return "Communication with mission control failed"
        case .decodingFailed:
            return "Failed to process mission data"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .dataUnavailable:
            return "Please try again later"
        case .communicationFailed:
            return "Check your connection and retry"
        case .decodingFailed:
            return "Please report this issue"
        case .unknownError:
            return "Please try again"
        }
    }
}

// MARK: - Production Implementation

final class ProductionMissionService: MissionServiceProtocol {
    private let delay: TimeInterval
    
    /// Initializer with configurable delay for testing
    /// - Parameter delay: Simulated network delay in seconds
    init(delay: TimeInterval = 0.3) {
        self.delay = delay
    }
    
    func fetchDashboard() async throws -> MissionDashboard {
        // Simulate async work
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        // Simulate random failure for testing error handling
        // About 10% chance of failure
        let randomValue = Double.random(in: 0...1)
        if randomValue < 0.1 {
            throw MissionServiceError.dataUnavailable
        }
        
        // Return deterministic sample data
        return SampleMissionData.generateDashboard()
    }
}

// MARK: - Test Double (Mock)

final class MockMissionService: MissionServiceProtocol {
    enum Behavior {
        case success
        case failure(MissionServiceError)
    }
    
    private(set) var behavior: Behavior
    private var fetchCount: Int = 0
    private let fixedDashboard: MissionDashboard?
    
    /// Initialize with desired behavior
    /// - Parameters:
    ///   - behavior: Whether to return success or failure
    ///   - fixedDashboard: Optional fixed dashboard to return (for deterministic testing)
    init(behavior: Behavior = .success, fixedDashboard: MissionDashboard? = nil) {
        self.behavior = behavior
        self.fixedDashboard = fixedDashboard
    }
    
    func fetchDashboard() async throws -> MissionDashboard {
        fetchCount += 1
        
        switch behavior {
        case .success:
            if let fixedDashboard = fixedDashboard {
                return fixedDashboard
            }
            return SampleMissionData.generateDashboard()
        case .failure(let error):
            throw error
        }
    }
    
    /// Returns how many times fetchDashboard has been called
    var callCount: Int { fetchCount }
    
    /// Resets the call count
    func resetCallCount() {
        fetchCount = 0
    }
}

// MARK: - Preview Service

final class PreviewMissionService: MissionServiceProtocol {
    func fetchDashboard() async throws -> MissionDashboard {
        // Return fixed data for previews
        let now = Date()
        let calendar = Calendar.current
        
        let metrics = [
            MissionMetric(name: "Orbit Altitude", value: "385.5", unit: "km", trend: .stable),
            MissionMetric(name: "Velocity", value: "7.68", unit: "km/s", trend: .stable),
            MissionMetric(name: "Power Level", value: "95.2", unit: "%", trend: .up)
        ]
        
        let events: [MissionEvent] = (0..<3).map { index in
            let minutesAgo = index * 10
            let eventTime = calendar.date(byAdding: .minute, value: -minutesAgo, to: now)!
            return MissionEvent(
                timestamp: eventTime,
                type: .systemStartup,
                description: "System initialized",
                severity: .info
            )
        }
        
        return MissionDashboard(
            status: .nominal,
            metrics: metrics,
            recentEvents: events,
            lastUpdated: now
        )
    }
}
