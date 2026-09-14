import Foundation

@MainActor
final class AppSettingsViewModel: ObservableObject {
    @Published private(set) var settings: AppSettings

    private let store: SettingsStoring

    init(store: SettingsStoring) {
        self.store = store
        settings = store.loadSettings()
    }

    func reload() {
        settings = store.loadSettings()
    }

    func updateAccentColor(_ option: AccentColorOption) {
        update { $0.accentColor = option }
    }

    func updateHapticFeedback(_ enabled: Bool) {
        update { $0.hapticFeedbackEnabled = enabled }
    }

    func updateReducedTelemetryFrequency(_ enabled: Bool) {
        update { $0.reducedTelemetryFrequency = enabled }
    }

    func updateCubeSettings(_ cubeSettings: CubeSettings) {
        update { $0.cube = cubeSettings.normalized() }
    }

    func resetAllSettings() {
        store.reset()
        settings = .defaults
        store.saveSettings(settings)
    }

    private func update(_ mutation: (inout AppSettings) -> Void) {
        var next = settings
        mutation(&next)
        next = next.normalized()
        settings = next
        store.saveSettings(next)
    }
}
