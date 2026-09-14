import Foundation

protocol CubeLabServiceProtocol {
    func loadSettings() -> CubeSettings
    func saveSettings(_ settings: CubeSettings) throws
    func resetSettings() throws
}

class CubeLabService: CubeLabServiceProtocol {
    private let storage: StorageServiceProtocol
    private let key = "cubeSettings"
    init(storage: StorageServiceProtocol = StorageService()) {
        self.storage = storage
    }
    func loadSettings() -> CubeSettings {
        (try? storage.load(forKey: key)) ?? .init()
    }
    func saveSettings(_ settings: CubeSettings) throws {
        try storage.save(settings, forKey: key)
    }
    func resetSettings() throws {
        try storage.remove(forKey: key)
    }
}

class MockCubeLabService: CubeLabServiceProtocol {
    var saved: CubeSettings?
    func loadSettings() -> CubeSettings { saved ?? .init() }
    func saveSettings(_ settings: CubeSettings) throws { saved = settings }
    func resetSettings() throws { saved = nil }
}
