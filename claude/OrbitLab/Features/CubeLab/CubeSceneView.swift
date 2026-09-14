import SceneKit
import SwiftUI

/// Bridges the SceneKit view into SwiftUI and forwards drag gestures to the controller.
struct CubeSceneView: UIViewRepresentable {
    let controller: CubeSceneController

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller)
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling2X
        view.rendersContinuously = false
        view.autoenablesDefaultLighting = false
        view.isAccessibilityElement = true
        view.accessibilityIdentifier = A11y.CubeLab.scene
        view.accessibilityLabel = "Interactive 3D cube"
        view.accessibilityHint = "Drag to rotate the cube."
        view.accessibilityTraits = .allowsDirectInteraction

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        view.addGestureRecognizer(pan)

        controller.attach(view)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.controller = controller
    }

    final class Coordinator: NSObject {
        var controller: CubeSceneController
        private var lastTranslation: CGPoint = .zero

        init(controller: CubeSceneController) {
            self.controller = controller
        }

        @MainActor
        @objc func handlePan(_ recogniser: UIPanGestureRecognizer) {
            guard let view = recogniser.view else { return }
            let translation = recogniser.translation(in: view)
            switch recogniser.state {
            case .began:
                lastTranslation = .zero
            case .changed:
                let delta = CGPoint(x: translation.x - lastTranslation.x, y: translation.y - lastTranslation.y)
                lastTranslation = translation
                controller.rotate(deltaX: delta.x, deltaY: delta.y)
            case .ended, .cancelled, .failed:
                lastTranslation = .zero
            default:
                break
            }
        }
    }
}
