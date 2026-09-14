import Foundation

/// One measurement produced by the telemetry stream.
struct TelemetrySample: Equatable, Identifiable {
    let id: Int
    let value: Double
    let channel: TelemetryChannel

    init(id: Int, value: Double, channel: TelemetryChannel = .thrust) {
        self.id = id
        self.value = value
        self.channel = channel
    }
}

/// The measured quantity. Only one channel is surfaced in the UI today, but the
/// stream and the view model are already keyed on it so more can be added.
enum TelemetryChannel: String, Equatable, CaseIterable {
    case thrust

    var title: String {
        switch self {
        case .thrust: return "Main engine thrust"
        }
    }

    var unit: String {
        switch self {
        case .thrust: return "kN"
        }
    }

    /// Value range used for scaling the chart, so an empty history still renders sane axes.
    var range: ClosedRange<Double> {
        switch self {
        case .thrust: return 0...120
        }
    }
}

/// How often the telemetry stream emits.
enum TelemetryCadence: String, Equatable, CaseIterable {
    case standard
    case reduced

    var title: String {
        switch self {
        case .standard: return "Standard"
        case .reduced: return "Reduced"
        }
    }

    var nanoseconds: UInt64 {
        switch self {
        case .standard: return 250_000_000
        case .reduced: return 1_000_000_000
        }
    }
}
