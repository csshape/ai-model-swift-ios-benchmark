import Foundation

// MARK: - Telemetry Data Point

struct TelemetryDataPoint: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let value: Double
    let label: String
    
    init(id: UUID = UUID(), timestamp: Date, value: Double, label: String) {
        self.id = id
        self.timestamp = timestamp
        self.value = value
        self.label = label
    }
}

// MARK: - Telemetry Configuration

struct TelemetryConfig: Codable, Equatable {
    var isRunning: Bool
    var updateInterval: TimeInterval
    var maxHistoryCount: Int
    var reducedFrequency: Bool
    
    init(isRunning: Bool = false, updateInterval: TimeInterval = 0.5, maxHistoryCount: Int = 50, reducedFrequency: Bool = false) {
        self.isRunning = isRunning
        self.updateInterval = updateInterval
        self.maxHistoryCount = maxHistoryCount
        self.reducedFrequency = reducedFrequency
    }
    
    static var `default`: TelemetryConfig {
        TelemetryConfig()
    }
}

// MARK: - Telemetry State

final class TelemetryState: ObservableObject, Codable {
    @Published var dataPoints: [TelemetryDataPoint]
    @Published var currentValue: Double
    @Published var isRunning: Bool
    
    var maxHistoryCount: Int = 50
    
    enum CodingKeys: String, CodingKey {
        case dataPoints
        case currentValue
        case isRunning
        case maxHistoryCount
    }
    
    init(dataPoints: [TelemetryDataPoint] = [], currentValue: Double = 0, isRunning: Bool = false, maxHistoryCount: Int = 50) {
        self.dataPoints = dataPoints
        self.currentValue = currentValue
        self.isRunning = isRunning
        self.maxHistoryCount = maxHistoryCount
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dataPoints = try container.decodeIfPresent([TelemetryDataPoint].self, forKey: .dataPoints) ?? []
        currentValue = try container.decodeIfPresent(Double.self, forKey: .currentValue) ?? 0
        isRunning = try container.decodeIfPresent(Bool.self, forKey: .isRunning) ?? false
        maxHistoryCount = try container.decodeIfPresent(Int.self, forKey: .maxHistoryCount) ?? 50
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dataPoints, forKey: .dataPoints)
        try container.encode(currentValue, forKey: .currentValue)
        try container.encode(isRunning, forKey: .isRunning)
        try container.encode(maxHistoryCount, forKey: .maxHistoryCount)
    }
    
    func addDataPoint(_ point: TelemetryDataPoint) {
        dataPoints.append(point)
        currentValue = point.value
        
        if dataPoints.count > maxHistoryCount {
            dataPoints.removeFirst()
        }
    }
    
    func clear() {
        dataPoints.removeAll()
        currentValue = 0
    }
}
