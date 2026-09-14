import Foundation

/// Minimal persistence seam. Everything the app stores is a `Codable` value behind a key,
/// which keeps `UserDefaults` out of the feature code and makes storage trivially fakeable.
protocol KeyValueStore: AnyObject {
    func data(forKey key: String) -> Data?
    func setData(_ data: Data?, forKey key: String)
    func removeAll()
}

extension KeyValueStore {
    /// Decodes a stored value, falling back to `defaultValue` when the key is missing or corrupt.
    func value<T: Decodable>(forKey key: String, default defaultValue: T) -> T {
        guard let data = data(forKey: key) else { return defaultValue }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            // A value written by an older build (or hand edited) must never crash the app.
            setData(nil, forKey: key)
            return defaultValue
        }
    }

    func setValue<T: Encodable>(_ value: T, forKey key: String) {
        setData(try? JSONEncoder().encode(value), forKey: key)
    }
}

/// Keys owned by the app. Kept in one place so `removeAll` on a shared suite stays honest.
enum StorageKey {
    static let appSettings = "orbitlab.appSettings"
    static let cubeSettings = "orbitlab.cubeSettings"

    static let all = [appSettings, cubeSettings]
}

/// Production store. Backed by an injected `UserDefaults` suite rather than `.standard`
/// so tests and previews can hand in their own.
final class UserDefaultsKeyValueStore: KeyValueStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func data(forKey key: String) -> Data? {
        defaults.data(forKey: key)
    }

    func setData(_ data: Data?, forKey key: String) {
        if let data = data {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    func removeAll() {
        for key in StorageKey.all {
            defaults.removeObject(forKey: key)
        }
    }
}

/// Used by tests, previews and UI test runs so nothing leaks between launches.
final class InMemoryKeyValueStore: KeyValueStore {
    private var storage: [String: Data]

    init(storage: [String: Data] = [:]) {
        self.storage = storage
    }

    func data(forKey key: String) -> Data? {
        storage[key]
    }

    func setData(_ data: Data?, forKey key: String) {
        storage[key] = data
    }

    func removeAll() {
        storage.removeAll()
    }
}
