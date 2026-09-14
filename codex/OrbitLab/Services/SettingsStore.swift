import Foundation

protocol SettingsStoring: AnyObject {
    func loadSettings() -> AppSettings
    func saveSettings(_ settings: AppSettings)
    func reset()
}

final class UserDefaultsSettingsStore: SettingsStoring {
    private let defaults: UserDefaults
    private let key = "orbitlab.app-settings.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSettings() -> AppSettings {
        guard
            let data = defaults.data(forKey: key),
            let decoded = try? JSONDecoder().decode(AppSettings.self, from: data)
        else {
            return .defaults
        }

        return decoded.normalized()
    }

    func saveSettings(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings.normalized()) else {
            return
        }
        defaults.set(data, forKey: key)
    }

    func reset() {
        defaults.removeObject(forKey: key)
    }
}

#if DEBUG
final class PreviewSettingsStore: SettingsStoring {
    private var settings: AppSettings

    init(settings: AppSettings = .defaults) {
        self.settings = settings
    }

    func loadSettings() -> AppSettings {
        settings
    }

    func saveSettings(_ settings: AppSettings) {
        self.settings = settings.normalized()
    }

    func reset() {
        settings = .defaults
    }
}
#endif
