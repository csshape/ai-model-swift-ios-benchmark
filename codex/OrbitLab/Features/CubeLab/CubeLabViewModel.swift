import Foundation

struct CubeRotationConfiguration: Equatable {
    let isAnimationEnabled: Bool
    let speed: Double
    let resetToken: Int
    let nudgeToken: Int
}

@MainActor
final class CubeLabViewModel: ObservableObject {
    @Published private(set) var settings: CubeSettings
    @Published private(set) var isSceneActive = true
    @Published private(set) var isVisible = true
    @Published private(set) var reduceMotionEnabled = false
    @Published private(set) var resetToken = 0
    @Published private(set) var nudgeToken = 0

    private let persist: @MainActor (CubeSettings) -> Void

    init(settings: CubeSettings = .defaults, persist: @escaping @MainActor (CubeSettings) -> Void = { _ in }) {
        self.settings = settings.normalized()
        self.persist = persist
    }

    var rotationButtonTitle: String {
        settings.isRotating ? "Pause Rotation" : "Start Rotation"
    }

    var rotationConfiguration: CubeRotationConfiguration {
        CubeRotationConfiguration(
            isAnimationEnabled: settings.isRotating && isSceneActive && isVisible && !reduceMotionEnabled,
            speed: settings.rotationSpeed,
            resetToken: resetToken,
            nudgeToken: nudgeToken
        )
    }

    func toggleRotation() {
        update(settings: CubeSettings(isRotating: !settings.isRotating, rotationSpeed: settings.rotationSpeed))
    }

    func updateSpeed(_ speed: Double) {
        update(settings: CubeSettings(isRotating: settings.isRotating, rotationSpeed: speed))
    }

    func reset() {
        update(settings: .defaults)
        resetToken += 1
    }

    func nudge() {
        nudgeToken += 1
    }

    func setSceneActive(_ active: Bool) {
        isSceneActive = active
    }

    func setVisible(_ visible: Bool) {
        isVisible = visible
    }

    func setReduceMotionEnabled(_ enabled: Bool) {
        reduceMotionEnabled = enabled
    }

    func applyExternalSettings(_ cubeSettings: CubeSettings) {
        let normalized = cubeSettings.normalized()
        if normalized != settings {
            settings = normalized
        }
    }

    private func update(settings newSettings: CubeSettings) {
        let normalized = newSettings.normalized()
        settings = normalized
        persist(normalized)
    }
}
