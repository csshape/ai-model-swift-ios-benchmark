import Foundation

/// Observable owner of the app wide preferences.
///
/// It is both the feature state for the Settings tab and the source the other tabs read,
/// which is why it lives in the container rather than in a single view.
@MainActor
final class AppSettingsStore: ObservableObject {
    @Published var settings: AppSettings {
        didSet {
            guard settings != oldValue else { return }
            persist()
        }
    }

    private let store: KeyValueStore

    init(store: KeyValueStore) {
        self.store = store
        self.settings = store.value(forKey: StorageKey.appSettings, default: AppSettings.default)
    }

    /// Restores the shipped defaults and clears the persisted copy.
    func reset() {
        settings = AppSettings.default
    }

    private func persist() {
        store.setValue(settings, forKey: StorageKey.appSettings)
    }
}
