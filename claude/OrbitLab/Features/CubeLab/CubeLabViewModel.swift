import Foundation

/// State and persistence for the Cube Lab. Holds no SceneKit objects, so it unit tests
/// without a renderer.
@MainActor
final class CubeLabViewModel: ObservableObject {
    @Published private(set) var settings: CubeSettings
    /// False while the app is backgrounded or inactive.
    @Published private(set) var isSceneActive = true
    /// Mirrors the Reduce Motion accessibility setting.
    @Published private(set) var prefersReducedMotion = false

    private let store: KeyValueStore

    init(store: KeyValueStore) {
        self.store = store
        self.settings = store.value(forKey: StorageKey.cubeSettings, default: CubeSettings.default)
        // A persisted value from an older build could be out of range; normalise on load.
        self.settings = CubeSettings(isRotating: settings.isRotating, speed: settings.speed)
    }

    var speed: Double { settings.speed }
    var isRotating: Bool { settings.isRotating }

    /// Whether the scene should actually be spinning right now.
    var shouldAnimate: Bool {
        settings.isRotating && isSceneActive && !prefersReducedMotion
    }

    var statusDescription: String {
        if prefersReducedMotion { return "Reduce Motion" }
        if !isSceneActive { return "Suspended" }
        return settings.isRotating ? "Rotating" : "Paused"
    }

    var playbackButtonTitle: String {
        settings.isRotating ? "Pause" : "Start"
    }

    func togglePlayback() {
        settings.isRotating.toggle()
        persist()
    }

    func setSpeed(_ speed: Double) {
        let clamped = CubeSettings.clampSpeed(speed)
        guard abs(clamped - settings.speed) > .ulpOfOne else { return }
        settings.speed = clamped
        persist()
    }

    /// Restores orientation defaults. The scene reset itself is performed by the view.
    func reset() {
        settings = CubeSettings.default
        persist()
    }

    func setSceneActive(_ isActive: Bool) {
        isSceneActive = isActive
    }

    func setReducedMotion(_ isEnabled: Bool) {
        prefersReducedMotion = isEnabled
    }

    private func persist() {
        store.setValue(settings, forKey: StorageKey.cubeSettings)
    }
}
