import Foundation

struct CubeSettings: Codable, Equatable {
    var rotationSpeed: Double
    var isRotating: Bool
    var cameraOrientation: SIMD3<Double>

    static let defaultSpeed: Double = 0.5
    static let defaultCameraOrientation: SIMD3<Double> = SIMD3<Double>(0, 0, -5)

    init(rotationSpeed: Double = defaultSpeed, isRotating: Bool = true, cameraOrientation: SIMD3<Double> = defaultCameraOrientation) {
        self.rotationSpeed = rotationSpeed
        self.isRotating = isRotating
        self.cameraOrientation = cameraOrientation
    }
}
