import SceneKit
import UIKit

/// Owns the SceneKit graph for the Cube Lab.
///
/// It knows nothing about SwiftUI or persistence: the view model decides *what* should happen
/// and this type translates that into scene commands, which keeps both sides testable.
@MainActor
final class CubeSceneController: ObservableObject {
    private enum Key {
        static let spin = "orbitlab.spin"
    }

    let scene: SCNScene

    /// Rotated by the user's drag gesture.
    private let pivotNode: SCNNode
    /// Rotated by the automatic spin action.
    private let cubeNode: SCNNode
    private let cameraNode: SCNNode
    private weak var renderView: SCNView?

    private(set) var isAnimating = false
    private(set) var appliedSpeed = CubeSettings.default.speed

    init() {
        scene = SCNScene()

        let box = SCNBox(width: 2.2, height: 2.2, length: 2.2, chamferRadius: 0.14)
        box.materials = CubeFace.allCases.map { face in
            let material = SCNMaterial()
            material.diffuse.contents = CubeFaceImageFactory.makeImage(for: face)
            material.locksAmbientWithDiffuse = true
            return material
        }

        cubeNode = SCNNode(geometry: box)
        cubeNode.name = "cube"

        pivotNode = SCNNode()
        pivotNode.name = "pivot"
        pivotNode.addChildNode(cubeNode)
        scene.rootNode.addChildNode(pivotNode)

        let camera = SCNCamera()
        camera.fieldOfView = 45
        camera.zNear = 0.1
        camera.zFar = 100
        cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 6.2)
        scene.rootNode.addChildNode(cameraNode)

        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .omni
        keyLight.light?.intensity = 900
        keyLight.position = SCNVector3(5, 6, 8)
        scene.rootNode.addChildNode(keyLight)

        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .ambient
        fillLight.light?.intensity = 420
        scene.rootNode.addChildNode(fillLight)
    }

    /// Number of distinct materials on the cube. Used by tests to prove six real faces exist.
    var faceMaterialCount: Int {
        cubeNode.geometry?.materials.count ?? 0
    }

    func attach(_ view: SCNView) {
        renderView = view
        view.scene = scene
        view.isPlaying = isAnimating
    }

    /// Single entry point from the view model.
    func apply(isAnimating: Bool, speed: Double) {
        let clamped = CubeSettings.clampSpeed(speed)
        let speedChanged = abs(clamped - appliedSpeed) > .ulpOfOne
        appliedSpeed = clamped

        if isAnimating {
            if !self.isAnimating || speedChanged {
                startSpin(secondsPerRevolution: CubeSettings(isRotating: true, speed: clamped).secondsPerRevolution)
            }
        } else {
            cubeNode.removeAction(forKey: Key.spin)
        }

        self.isAnimating = isAnimating
        renderView?.isPlaying = isAnimating
    }

    /// Back to a known orientation and the default camera framing.
    func reset() {
        cubeNode.removeAction(forKey: Key.spin)
        cubeNode.removeAllActions()
        cubeNode.transform = SCNMatrix4Identity
        cubeNode.eulerAngles = SCNVector3Zero
        pivotNode.transform = SCNMatrix4Identity
        pivotNode.eulerAngles = SCNVector3Zero
        cameraNode.position = SCNVector3(0, 0, 6.2)
        isAnimating = false
        appliedSpeed = CubeSettings.default.speed
        renderView?.isPlaying = false
    }

    /// Drag interaction. Rotates the pivot so it composes with the running spin action.
    func rotate(deltaX: CGFloat, deltaY: CGFloat) {
        let sensitivity: Float = 0.008
        let yaw = SCNMatrix4MakeRotation(Float(deltaX) * sensitivity, 0, 1, 0)
        let pitch = SCNMatrix4MakeRotation(Float(deltaY) * sensitivity, 1, 0, 0)
        pivotNode.transform = SCNMatrix4Mult(pivotNode.transform, SCNMatrix4Mult(yaw, pitch))
        renderView?.setNeedsDisplay()
    }

    /// Reduce Motion alternative: one discrete quarter turn instead of continuous spin.
    func stepQuarterTurn() {
        let turn = SCNAction.rotateBy(x: 0, y: .pi / 2, z: 0, duration: 0.35)
        turn.timingMode = .easeInEaseOut
        renderView?.isPlaying = true
        pivotNode.runAction(turn) { [weak self] in
            Task { @MainActor in
                guard let self = self, !self.isAnimating else { return }
                self.renderView?.isPlaying = false
            }
        }
    }

    /// Stops all rendering work while the app is not on screen.
    func setRenderingSuspended(_ suspended: Bool) {
        scene.isPaused = suspended
        renderView?.isPlaying = suspended ? false : isAnimating
    }

    private func startSpin(secondsPerRevolution: Double) {
        cubeNode.removeAction(forKey: Key.spin)
        let rotation = SCNAction.rotateBy(
            x: .pi * 2 * 0.35,
            y: .pi * 2,
            z: 0,
            duration: secondsPerRevolution
        )
        cubeNode.runAction(.repeatForever(rotation), forKey: Key.spin)
    }
}
