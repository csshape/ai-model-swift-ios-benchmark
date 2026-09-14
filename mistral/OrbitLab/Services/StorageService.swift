import Foundation

protocol StorageServiceProtocol {
    func save<T: Codable>(_ value: T, forKey key: String) throws
    func load<T: Codable>(forKey key: String) throws -> T?
    func remove(forKey key: String) throws
    func clearAll() throws
}

class StorageService: StorageServiceProtocol {
    func save<T: Codable>(_ value: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(value)
        UserDefaults.standard.set(data, forKey: key)
    }
    func load<T: Codable>(forKey key: String) throws -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }
    func remove(forKey key: String) throws {
        UserDefaults.standard.removeObject(forKey: key)
    }
    func clearAll() throws {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
    }
}

class MockStorageService: StorageServiceProtocol {
    var storage: [String: Data] = [:]
    func save<T: Codable>(_ value: T, forKey key: String) throws {
        storage[key] = try JSONEncoder().encode(value)
    }
    func load<T: Codable>(forKey key: String) throws -> T? {
        guard let data = storage[key] else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }
    func remove(forKey key: String) throws { storage.removeValue(forKey: key) }
    func clearAll() throws { storage.removeAll() }
}
