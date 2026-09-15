import Foundation

// MARK: - Storage Service Protocol

protocol StorageServiceProtocol {
    /// Saves data to persistent storage
    /// - Parameters:
    ///   - data: The data to save
    ///   - key: The key to use for storage
    func save<T: Codable>(_ data: T, forKey key: String) throws
    
    /// Loads data from persistent storage
    /// - Parameters:
    ///   - key: The key to load from
    /// - Returns: The loaded data, or nil if not found
    func load<T: Codable>(forKey key: String) throws -> T?
    
    /// Deletes data from persistent storage
    /// - Parameter key: The key to delete
    func delete(forKey key: String) throws
    
    /// Resets all storage (for testing/clearing)
    func reset() throws
}

// MARK: - UserDefaults Storage Implementation

final class UserDefaultsStorageService: StorageServiceProtocol {
    private let userDefaults: UserDefaults
    private let suiteName: String?
    
    /// Initialize with UserDefaults
    /// - Parameters:
    ///   - suiteName: Optional suite name for app groups
    init(suiteName: String? = nil) {
        self.suiteName = suiteName
        self.userDefaults = suiteName.flatMap { UserDefaults(suiteName: $0) } ?? .standard
    }
    
    func save<T: Codable>(_ data: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encodedData = try encoder.encode(data)
        userDefaults.set(encodedData, forKey: key)
    }
    
    func load<T: Codable>(forKey key: String) throws -> T? {
        guard let encodedData = userDefaults.data(forKey: key) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: encodedData)
    }
    
    func delete(forKey key: String) throws {
        userDefaults.removeObject(forKey: key)
    }
    
    func reset() throws {
        if let bundleID = Bundle.main.bundleIdentifier {
            userDefaults.removePersistentDomain(forName: bundleID)
        }
    }
}

// MARK: - File Storage Implementation

final class FileStorageService: StorageServiceProtocol {
    private let directory: URL
    
    init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func save<T: Codable>(_ data: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let encodedData = try encoder.encode(data)
        let fileURL = directory.appendingPathComponent("\(key).json")
        
        try encodedData.write(to: fileURL)
    }
    
    func load<T: Codable>(forKey key: String) throws -> T? {
        let fileURL = directory.appendingPathComponent("\(key).json")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        let encodedData = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(T.self, from: encodedData)
    }
    
    func delete(forKey key: String) throws {
        let fileURL = directory.appendingPathComponent("\(key).json")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
    
    func reset() throws {
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        for file in files where file.pathExtension == "json" {
            try FileManager.default.removeItem(at: file)
        }
    }
}

// MARK: - Mock Storage for Testing

final class MockStorageService: StorageServiceProtocol {
    private var storage: [String: Data] = [:]
    
    var saveCount: Int = 0
    var loadCount: Int = 0
    var deleteCount: Int = 0
    var resetCount: Int = 0
    
    func save<T: Codable>(_ data: T, forKey key: String) throws {
        saveCount += 1
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encodedData = try encoder.encode(data)
        storage[key] = encodedData
    }
    
    func load<T: Codable>(forKey key: String) throws -> T? {
        loadCount += 1
        guard let encodedData = storage[key] else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: encodedData)
    }
    
    func delete(forKey key: String) throws {
        deleteCount += 1
        storage.removeValue(forKey: key)
    }
    
    func reset() throws {
        resetCount += 1
        storage.removeAll()
    }
    
    /// Get the raw storage for inspection
    var rawStorage: [String: Data] { storage }
    
    /// Reset all counters
    func resetCounters() {
        saveCount = 0
        loadCount = 0
        deleteCount = 0
        resetCount = 0
    }
}

// MARK: - Storage Keys

enum StorageKey {
    static let appSettings = "com.orbital.locked.appSettings"
    static let cubeSettings = "com.orbital.locked.cubeSettings"
    static let telemetryState = "com.orbital.locked.telemetryState"
}
