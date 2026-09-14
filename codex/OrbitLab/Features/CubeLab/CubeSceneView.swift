import SceneKit
import SwiftUI

struct CubeSceneView: UIViewRepresentable {
    let configuration: CubeRotationConfiguration

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SCNView {
        context.coordinator.controller.makeView()
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.controller.apply(configuration, to: uiView)
    }

    static func dismantleUIView(_ uiView: SCNView, coordinator: Coordinator) {
        coordinator.controller.stop(in: uiView)
    }

    final class Coordinator {
        let controller = CubeSceneController()
    }
}

final class CubeSceneController {
    private let rotationActionKey = "orbitlab.cube.rotation"
    private let scene = SCNScene()
    private let cubeNode = SCNNode()
    private let cameraNode = SCNNode()
    private var lastConfiguration: CubeRotationConfiguration?

    init() {
        configureScene()
    }

    func makeView() -> SCNView {
        let view = SCNView(frame: .zero)
        view.scene = scene
        view.pointOfView = cameraNode
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling4X
        view.backgroundColor = .clear
        view.isPlaying = true
        return view
    }

    func apply(_ configuration: CubeRotationConfiguration, to view: SCNView) {
        if let lastConfiguration {
            if configuration.resetToken != lastConfiguration.resetToken {
                resetOrientation(in: view)
            }

            if configuration.nudgeToken != lastConfiguration.nudgeToken {
                nudgeCube()
            }
        }

        if configuration.isAnimationEnabled {
            if lastConfiguration?.isAnimationEnabled != true || lastConfiguration?.speed != configuration.speed {
                startRotation(speed: configuration.speed)
            }
            view.isPlaying = true
        } else {
            cubeNode.removeAction(forKey: rotationActionKey)
            view.isPlaying = false
        }

        lastConfiguration = configuration
    }

    func stop(in view: SCNView) {
        cubeNode.removeAction(forKey: rotationActionKey)
        view.isPlaying = false
    }

    private func configureScene() {
        scene.background.contents = UIColor.clear

        let box = SCNBox(width: 1.65, height: 1.65, length: 1.65, chamferRadius: 0.035)
        box.materials = makeMaterials()
        cubeNode.geometry = box
        scene.rootNode.addChildNode(cubeNode)

        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 420
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)

        let keyLight = SCNLight()
        keyLight.type = .omni
        keyLight.intensity = 650
        let keyNode = SCNNode()
        keyNode.light = keyLight
        keyNode.position = SCNVector3(2.4, 2.8, 3.8)
        scene.rootNode.addChildNode(keyNode)

        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 48
        cameraNode.position = SCNVector3(0, 0, 5.0)
        scene.rootNode.addChildNode(cameraNode)
    }

    private func makeMaterials() -> [SCNMaterial] {
        [
            makeMaterial(title: "NAV", symbol: "location.north.fill", color: UIColor(red: 0.10, green: 0.32, blue: 0.85, alpha: 1)),
            makeMaterial(title: "COM", symbol: "dot.radiowaves.left.and.right", color: UIColor(red: 0.05, green: 0.55, blue: 0.42, alpha: 1)),
            makeMaterial(title: "PWR", symbol: "bolt.fill", color: UIColor(red: 0.88, green: 0.47, blue: 0.10, alpha: 1)),
            makeMaterial(title: "SCI", symbol: "atom", color: UIColor(red: 0.54, green: 0.22, blue: 0.74, alpha: 1)),
            makeMaterial(title: "EVA", symbol: "figure.walk", color: UIColor(red: 0.73, green: 0.11, blue: 0.24, alpha: 1)),
            makeMaterial(title: "OPS", symbol: "gearshape.fill", color: UIColor(red: 0.14, green: 0.48, blue: 0.68, alpha: 1))
        ]
    }

    private func makeMaterial(title: String, symbol: String, color: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = sideImage(title: title, symbol: symbol, color: color)
        material.roughness.contents = 0.48
        material.metalness.contents = 0.08
        return material
    }

    private func sideImage(title: String, symbol: String, color: UIColor) -> UIImage {
        let size = CGSize(width: 320, height: 320)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            UIColor.white.withAlphaComponent(0.18).setStroke()
            let gridPath = UIBezierPath()
            for offset in stride(from: 40, through: 280, by: 40) {
                let position = CGFloat(offset)
                gridPath.move(to: CGPoint(x: position, y: 0))
                gridPath.addLine(to: CGPoint(x: position, y: size.height))
                gridPath.move(to: CGPoint(x: 0, y: position))
                gridPath.addLine(to: CGPoint(x: size.width, y: position))
            }
            gridPath.lineWidth = 2
            gridPath.stroke()

            if let image = UIImage(systemName: symbol) {
                let symbolRect = CGRect(x: 98, y: 70, width: 124, height: 124)
                image.withTintColor(.white, renderingMode: .alwaysOriginal).draw(in: symbolRect)
            }

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 58, weight: .heavy),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraph
            ]
            title.draw(in: CGRect(x: 24, y: 210, width: 272, height: 70), withAttributes: attributes)
        }
    }

    private func startRotation(speed: Double) {
        cubeNode.removeAction(forKey: rotationActionKey)
        let clampedSpeed = CubeSettings.clampedSpeed(speed)
        let duration = max(1.15, 5.0 / clampedSpeed)
        let spin = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: CGFloat.pi / 5, duration: duration)
        spin.timingMode = .linear
        cubeNode.runAction(.repeatForever(spin), forKey: rotationActionKey)
    }

    private func resetOrientation(in view: SCNView) {
        cubeNode.removeAction(forKey: rotationActionKey)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0
        cubeNode.eulerAngles = SCNVector3Zero
        cameraNode.position = SCNVector3(0, 0, 5.0)
        cameraNode.eulerAngles = SCNVector3Zero
        view.pointOfView = cameraNode
        SCNTransaction.commit()
    }

    private func nudgeCube() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0
        cubeNode.eulerAngles = SCNVector3(
            cubeNode.eulerAngles.x,
            cubeNode.eulerAngles.y + Float.pi / 10,
            cubeNode.eulerAngles.z
        )
        SCNTransaction.commit()
    }
}
