import Foundation

/// Composition root. Everything the app depends on is created here and handed down,
/// which is what keeps the features free of singletons.
@MainActor
final class AppContainer: ObservableObject {
    let missionService: MissionService
    let telemetrySource: TelemetrySource
    let haptics: HapticsProviding
    let settingsStore: AppSettingsStore
    /// Owned by the container because the Cube Lab state must survive tab switches and
    /// because "reset all settings" has to reach it.
    let cubeViewModel: CubeLabViewModel

    private let keyValueStore: KeyValueStore

    init(
        keyValueStore: KeyValueStore,
        missionService: MissionService = LocalMissionService(),
        telemetrySource: TelemetrySource = SimulatedTelemetrySource(),
        haptics: HapticsProviding = SystemHaptics()
    ) {
        self.keyValueStore = keyValueStore
        self.missionService = missionService
        self.telemetrySource = telemetrySource
        self.haptics = haptics
        self.settingsStore = AppSettingsStore(store: keyValueStore)
        self.cubeViewModel = CubeLabViewModel(store: keyValueStore)
    }

    /// Wiring for a real launch. UI test runs get a clean in-memory store and silent
    /// haptics so a run can never depend on what a previous run left behind.
    static func live(processInfo: ProcessInfo = .processInfo) -> AppContainer {
        if processInfo.arguments.contains(A11y.uiTestLaunchArgument) {
            return AppContainer(keyValueStore: InMemoryKeyValueStore(), haptics: SilentHaptics())
        }
        return AppContainer(keyValueStore: UserDefaultsKeyValueStore())
    }

    func resetAllSettings() {
        keyValueStore.removeAll()
        settingsStore.reset()
        cubeViewModel.reset()
    }
}
