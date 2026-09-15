import Foundation
import SceneKit

// MARK: - Cube Face Configuration

enum CubeFace: String, CaseIterable, Identifiable, Codable {
    case front
    case back
    case left
    case right
    case top
    case bottom
    
    var id: String { rawValue }
    
    var color: UIColor {
        switch self {
        case .front: return UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0) // Red
        case .back: return UIColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0) // Green
        case .left: return UIColor(red: 0.2, green: 0.2, blue: 0.8, alpha: 1.0) // Blue
        case .right: return UIColor(red: 0.8, green: 0.8, blue: 0.2, alpha: 1.0) // Yellow
        case .top: return UIColor(red: 0.8, green: 0.2, blue: 0.8, alpha: 1.0) // Magenta
        case .bottom: return UIColor(red: 0.2, green: 0.8, blue: 0.8, alpha: 1.0) // Cyan
        }
    }
    
    var label: String {
        rawValue.capitalized
    }
}

// MARK: - Cube Configuration

struct CubeConfig: Codable {
    var rotationSpeed: Float
    var isRotating: Bool
    var currentOrientation: SCNVector4?
    var cameraPosition: SCNVector3?
    
    init(rotationSpeed: Float = 1.0, isRotating: Bool = true, currentOrientation: SCNVector4? = nil, cameraPosition: SCNVector3? = nil) {
        self.rotationSpeed = rotationSpeed
        self.isRotating = isRotating
        self.currentOrientation = currentOrientation
        self.cameraPosition = cameraPosition
    }
    
    static var `default`: CubeConfig {
        CubeConfig()
    }
}

// MARK: - Equatable conformance for SCNVector types

extension SCNVector4: Equatable {
    public static func == (lhs: SCNVector4, rhs: SCNVector4) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z && lhs.w == rhs.w
    }
}

extension SCNVector3: Equatable {
    public static func == (lhs: SCNVector3, rhs: SCNVector3) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }
}

// MARK: - SCNVector4 Codable support

extension SCNVector4: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let array = try container.decode([Float].self)
        guard array.count == 4 else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected 4 values for SCNVector4"
                )
            )
        }
        self.init(array[0], array[1], array[2], array[3])
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode([x, y, z, w])
    }
}

// MARK: - SCNVector3 Codable support

extension SCNVector3: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let array = try container.decode([Float].self)
        guard array.count == 3 else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected 3 values for SCNVector3"
                )
            )
        }
        self.init(array[0], array[1], array[2])
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode([x, y, z])
    }
}
