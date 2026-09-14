import Foundation

protocol SettingsServiceProtocol {
    func loadSettings() -> AppSettings
    func saveSettings(_ settings: AppSettings) throws
    func resetSettings() throws
    func addObserver(_ observer: SettingsObserver)
    func removeObserver(_ observer: SettingsObserver)
}

protocol SettingsObserver: AnyObject {
    func settingsDidChange(_ settings: AppSettings)
}

class SettingsService: SettingsServiceProtocol {
    private let storage: StorageServiceProtocol
    private let key = "appSettings"
    private var observers: [WeakObserver] = []
    private var current = AppSettings()

    init(storage: StorageServiceProtocol = StorageService()) {
        self.storage = storage
        current = loadSettings()
    }

    func loadSettings() -> AppSettings {
        (try? storage.load(forKey: key)) ?? .init()
    }
    func saveSettings(_ settings: AppSettings) throws {
        try storage.save(settings, forKey: key)
        current = settings
        notifyObservers()
    }
    func resetSettings() throws {
        try storage.remove(forKey: key)
        current = .init()
        notifyObservers()
    }
    func addObserver(_ observer: SettingsObserver) {
        observers.append(WeakObserver(observer))
        observer.settingsDidChange(current)
    }
    func removeObserver(_ observer: SettingsObserver) {
        observers.removeAll { $0.value === observer }
    }
    func notifyObservers() {
        for obs in observers {
            obs.value?.settingsDidChange(current)
        }
    }
}

private class WeakObserver {
    weak var value: SettingsObserver?
    init(_ observer: SettingsObserver) { value = observer }
}

class MockSettingsService: SettingsServiceProtocol {
    var saved: AppSettings?
    var observers: [SettingsObserver] = []
    func loadSettings() -> AppSettings { saved ?? .init() }
    func saveSettings(_ settings: AppSettings) throws { saved = settings; notifyObservers() }
    func resetSettings() throws { saved = nil; notifyObservers() }
    func addObserver(_ observer: SettingsObserver) { observers.append(observer); observer.settingsDidChange(saved ?? .init()) }
    func removeObserver(_ observer: SettingsObserver) { observers.removeAll { $0 === observer } }
    func notifyObservers() { let s = saved ?? .init(); observers.forEach { $0.settingsDidChange(s) } }
}
