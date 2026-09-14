import Foundation

struct TelemetryPoint: Codable, Equatable, Identifiable {
    let id: Int
    let timestamp: Date
    let value: Double

    var formattedValue: String {
        value.formatted(.number.precision(.fractionLength(1)))
    }
}
