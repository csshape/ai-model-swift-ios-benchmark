import SwiftUI

@main
@MainActor
struct OrbitLabApp: App {
    private let dependencies: AppDependencies
    @StateObject private var settingsModel: AppSettingsViewModel

    init() {
        let dependencies = AppDependencies.live()
        self.dependencies = dependencies
        _settingsModel = StateObject(wrappedValue: AppSettingsViewModel(store: dependencies.settingsStore))
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(dependencies: dependencies, settingsModel: settingsModel)
                .environmentObject(settingsModel)
                .tint(settingsModel.settings.accentColor.color)
        }
    }
}
