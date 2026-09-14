import SwiftUI
import SceneKit

struct SceneKitCubeView: UIViewRepresentable {
    @Binding var rotationSpeed: Double
    @Binding var isRotating: Bool
    @Binding var cameraOrientation: SIMD3<Double>
    var reduceMotion: Bool = false

    class Coordinator: NSObject {
        var parent: SceneKitCubeView
        var rotationNode: SCNNode?
        var cameraOrbitNode: SCNNode?
        var startTime: TimeInterval = 0

        init(parent: SceneKitCubeView) {
            self.parent = parent
            super.init()
        }

        func setup(view: SCNView) {
            startTime = CFAbsoluteTimeGetCurrent()
            view.scene = SCNScene()
            view.autoenablesDefaultLighting = true
            view.allowsCameraControl = false
            view.backgroundColor = .clear

            let camera = SCNCamera()
            camera.zFar = 100
            let cameraNode = SCNNode()
            cameraNode.camera = camera
            cameraNode.position = SCNVector3(
                Float(parent.cameraOrientation.x),
                Float(parent.cameraOrientation.y),
                Float(parent.cameraOrientation.z)
            )

            cameraOrbitNode = SCNNode()
            cameraOrbitNode?.addChildNode(cameraNode)
            view.scene?.rootNode.addChildNode(cameraOrbitNode!)

            let cube = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.05)
            let colors: [UIColor] = [.systemRed, .systemGreen, .systemBlue, .systemOrange, .systemPurple, .systemCyan]
            cube.materials = colors.map { c in
                let m = SCNMaterial()
                m.diffuse.contents = c
                m.lightingModel = .phong
                return m
            }

            let cubeNode = SCNNode(geometry: cube)
            rotationNode = SCNNode()
            rotationNode?.addChildNode(cubeNode)
            view.scene?.rootNode.addChildNode(rotationNode!)

            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            view.addGestureRecognizer(pan)
        }

        @objc func handlePan(_ g: UIPanGestureRecognizer) {
            guard let v = g.view as? SCNView else { return }
            let t = g.translation(in: v)
            cameraOrbitNode?.eulerAngles.y += Float(t.x) * .pi / 180.0
            cameraOrbitNode?.eulerAngles.x += Float(t.y) * .pi / 180.0
            g.setTranslation(.zero, in: v)
        }

        func update() {
            guard let node = rotationNode else { return }
            if parent.isRotating && !parent.reduceMotion {
                let elapsed = CFAbsoluteTimeGetCurrent() - startTime
                let speed = Float(parent.rotationSpeed)
                node.eulerAngles = SCNVector3(
                    Float(elapsed) * speed * 0.3,
                    Float(elapsed) * speed * 0.7,
                    Float(elapsed) * speed * 0.2
                )
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
    func makeUIView(context: Context) -> SCNView {
        let v = SCNView(frame: .zero)
        context.coordinator.setup(view: v)
        return v
    }
    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.update()
        if let cameraNode = context.coordinator.cameraOrbitNode?.childNodes.first {
            cameraNode.position = SCNVector3(
                Float(cameraOrientation.x),
                Float(cameraOrientation.y),
                Float(cameraOrientation.z)
            )
        }
    }
}
