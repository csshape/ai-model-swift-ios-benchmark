import Foundation
import SceneKit
import SwiftUI
import Combine

// MARK: - Cube View Model

/// ViewModel for Cube Lab tab
class CubeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var rotationSpeed: Float = 1.0 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var isAutoRotating: Bool = true {
        didSet {
            saveSettings()
            if isAutoRotating {
                startAutoRotation()
            } else {
                stopAutoRotation()
            }
        }
    }
    
    @Published private(set) var scene: SCNScene?
    @Published private(set) var cubeNode: SCNNode?
    @Published private(set) var cameraNode: SCNNode?
    
    // MARK: - Public Properties
    
    var currentOrientation: SCNVector4?
    var cameraPosition: SCNVector3?
    
    // MARK: - Private Properties
    
    private let storageService: StorageServiceProtocol
    private let settingsManager: SettingsManager?
    private let cubeSettingsKey = StorageKey.cubeSettings
    
    private var rotationTask: Task<Void, Never>?
    private var isRotating = false
    private var lastUpdateTime: TimeInterval = 0
    
    // MARK: - Initialization
    
    /// Initialize with storage and optional settings manager
    /// - Parameters:
    ///   - storageService: The storage service for persistence
    ///   - settingsManager: Optional settings manager to sync with
    init(storageService: StorageServiceProtocol = UserDefaultsStorageService(),
         settingsManager: SettingsManager? = nil) {
        self.storageService = storageService
        self.settingsManager = settingsManager
        
        loadSettings()
        setupScene()
    }
    
    deinit {
        rotationTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Toggles auto rotation
    func toggleAutoRotation() {
        isAutoRotating.toggle()
    }
    
    /// Starts auto rotation
    func startAutoRotation() {
        guard !isRotating else { return }
        isRotating = true
        startRotation()
    }
    
    /// Stops auto rotation
    func stopAutoRotation() {
        guard isRotating else { return }
        isRotating = false
        rotationTask?.cancel()
        rotationTask = nil
    }
    
    /// Resets the cube to initial state
    func reset() {
        stopAutoRotation()
        
        // Reset to initial values
        rotationSpeed = 1.0
        isAutoRotating = true
        
        // Recreate scene
        setupScene()
        
        if isAutoRotating {
            startAutoRotation()
        }
    }
    
    /// Handles touch-based rotation
    /// - Parameter rotation: The rotation to apply (pitch, yaw, roll)
    func applyTouchRotation(pitch: Float, yaw: Float) {
        guard let cubeNode = cubeNode else { return }
        
        let pitchRotation = SCNVector4(1, 0, 0, pitch)
        let yawRotation = SCNVector4(0, 1, 0, yaw)
        
        cubeNode.rotation = SCNVector4Add(cubeNode.rotation, pitchRotation)
        cubeNode.rotation = SCNVector4Add(cubeNode.rotation, yawRotation)
        
        currentOrientation = cubeNode.rotation
    }
    
    /// Handles scene lifecycle events
    func handleSceneActive(_ active: Bool) {
        if active {
            if isAutoRotating && !isRotating {
                startAutoRotation()
            }
        } else {
            stopAutoRotation()
        }
    }
    
    // MARK: - Scene Setup
    
    private func setupScene() {
        let scene = SCNScene()
        
        // Create cube
        let cubeGeometry = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.05)
        
        // Create materials for each face
        let materials = CubeFace.allCases.map { face -> SCNMaterial in
            let material = SCNMaterial()
            material.diffuse.contents = face.color
            material.lightingModel = .constant
            material.isDoubleSided = false
            return material
        }
        
        cubeGeometry.materials = materials
        
        let cubeNode = SCNNode(geometry: cubeGeometry)
        cubeNode.position = SCNVector3(0, 0, 0)
        cubeNode.name = "cube"
        
        // Create camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 3.0)
        cameraNode.name = "camera"
        
        // Add ambient light
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = UIColor.white.withAlphaComponent(0.5)
        scene.rootNode.addChildNode(ambientLightNode)
        
        // Add directional light
        let directionalLightNode = SCNNode()
        directionalLightNode.light = SCNLight()
        directionalLightNode.light?.type = .directional
        directionalLightNode.light?.color = UIColor.white
        directionalLightNode.eulerAngles = SCNVector3(-Float.pi / 4, 0, 0)
        scene.rootNode.addChildNode(directionalLightNode)
        
        // Add nodes to scene
        scene.rootNode.addChildNode(cameraNode)
        scene.rootNode.addChildNode(cubeNode)
        
        self.scene = scene
        self.cubeNode = cubeNode
        self.cameraNode = cameraNode
        self.cameraPosition = cameraNode.position
        
        // Start rotation if auto-rotate is enabled
        if isAutoRotating {
            startAutoRotation()
        }
    }
    
    // MARK: - Rotation Logic
    
    private func startRotation() {
        rotationTask?.cancel()
        
        rotationTask = Task { [weak self] in
            await self?.rotateContinuously()
        }
    }
    
    @MainActor
    private func rotateContinuously() async {
        while !Task.isCancelled {
            let startTime = CACurrentMediaTime()
            
            // Rotate around Y axis
            await rotateCubeBy(angle: Float.pi * 0.01 * rotationSpeed, axis: SCNVector3(0, 1, 0))
            
            // Calculate time for next frame to maintain consistent speed
            let frameTime = CACurrentMediaTime() - startTime
            let targetFrameTime: TimeInterval = 1.0 / 60.0
            let remainingTime = max(0, targetFrameTime - frameTime)
            
            try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
        }
    }
    
    @MainActor
    private func rotateCubeBy(angle: Float, axis: SCNVector3) async {
        guard let cubeNode = cubeNode else { return }
        
        let rotation = SCNVector4(axis.x, axis.y, axis.z, angle)
        cubeNode.rotation = SCNVector4Add(cubeNode.rotation, rotation)
        
        currentOrientation = cubeNode.rotation
    }
    
    // MARK: - Settings Persistence
    
    private func loadSettings() {
        do {
            if let settings: CubeSettings = try storageService.load(forKey: cubeSettingsKey) {
                rotationSpeed = settings.rotationSpeed
                isAutoRotating = settings.isAutoRotating
            }
        } catch {
            print("Error loading cube settings: \(error)")
        }
    }
    
    private func saveSettings() {
        let settings = CubeSettings(
            rotationSpeed: rotationSpeed,
            isAutoRotating: isAutoRotating
        )
        
        do {
            try storageService.save(settings, forKey: cubeSettingsKey)
            
            // Also sync with settings manager if available
            settingsManager?.cubeRotationSpeed = rotationSpeed
            settingsManager?.cubeIsAutoRotating = isAutoRotating
        } catch {
            print("Error saving cube settings: \(error)")
        }
    }
}

// MARK: - SCNVector4 Helper

func SCNVector4Add(_ v1: SCNVector4, _ v2: SCNVector4) -> SCNVector4 {
    return SCNVector4(
        v1.x + v2.x,
        v1.y + v2.y,
        v1.z + v2.z,
        v1.w + v2.w
    )
}

// MARK: - Preview View Model

final class PreviewCubeViewModel: CubeViewModel {
    init() {
        super.init(storageService: MockStorageService(), settingsManager: nil)
    }
}
