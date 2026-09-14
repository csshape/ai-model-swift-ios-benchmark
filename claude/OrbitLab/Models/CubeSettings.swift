import Foundation

/// Persisted state of the Cube Lab.
struct CubeSettings: Codable, Equatable {
    /// Revolutions per second at speed 1.0.
    static let speedRange: ClosedRange<Double> = 0.1...3.0
    static let `default` = CubeSettings(isRotating: true, speed: 1.0)

    var isRotating: Bool
    var speed: Double

    init(isRotating: Bool, speed: Double) {
        self.isRotating = isRotating
        self.speed = CubeSettings.clampSpeed(speed)
    }

    /// Keeps a persisted or user supplied value inside the range the scene can render.
    static func clampSpeed(_ speed: Double) -> Double {
        guard speed.isFinite else { return CubeSettings.default.speed }
        return min(max(speed, speedRange.lowerBound), speedRange.upperBound)
    }

    /// Seconds for one full revolution at the current speed.
    var secondsPerRevolution: Double {
        4.0 / CubeSettings.clampSpeed(speed)
    }
}
