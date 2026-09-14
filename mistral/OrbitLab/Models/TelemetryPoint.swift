import Foundation

struct TelemetryPoint: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let value: Double
    let unit: String

    init(id: UUID = UUID(), timestamp: Date, value: Double, unit: String = "km/s") {
        self.id = id
        self.timestamp = timestamp
        self.value = value
        self.unit = unit
    }
}
