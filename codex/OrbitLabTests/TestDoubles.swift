import Foundation
@testable import OrbitLab

final class InMemorySettingsStore: SettingsStoring {
    private var storedSettings: AppSettings?

    init(settings: AppSettings? = nil) {
        storedSettings = settings
    }

    func loadSettings() -> AppSettings {
        storedSettings ?? .defaults
    }

    func saveSettings(_ settings: AppSettings) {
        storedSettings = settings.normalized()
    }

    func reset() {
        storedSettings = nil
    }
}

enum TestError: Error {
    case expected
}

func telemetryPoint(_ id: Int, value: Double? = nil) -> TelemetryPoint {
    TelemetryPoint(
        id: id,
        timestamp: Date(timeIntervalSince1970: 1_789_370_400 + TimeInterval(id)),
        value: value ?? Double(id)
    )
}
