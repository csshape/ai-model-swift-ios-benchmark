import Foundation

struct AppDependencies {
    let missionService: MissionControlServicing
    let telemetryService: TelemetryStreaming
    let settingsStore: SettingsStoring
    let haptics: HapticPerforming

    @MainActor
    static func live() -> AppDependencies {
        let store = UserDefaultsSettingsStore()

        if ProcessInfo.processInfo.arguments.contains("--reset-settings") {
            store.reset()
        }

        return AppDependencies(
            missionService: LocalMissionControlService(),
            telemetryService: DeterministicTelemetryService(),
            settingsStore: store,
            haptics: UIKitHapticPerformer()
        )
    }
}
