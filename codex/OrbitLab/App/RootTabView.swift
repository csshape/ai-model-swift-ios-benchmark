import SwiftUI

@MainActor
struct RootTabView: View {
    let dependencies: AppDependencies
    @ObservedObject var settingsModel: AppSettingsViewModel

    var body: some View {
        TabView {
            MissionControlView(service: dependencies.missionService)
                .tabItem {
                    Label("Mission", systemImage: "antenna.radiowaves.left.and.right")
                }
                .accessibilityLabel("Mission Control tab")

            CubeLabView(settingsModel: settingsModel)
                .tabItem {
                    Label("Cube", systemImage: "cube.transparent")
                }
                .accessibilityLabel("Cube Lab tab")

            TelemetryView(service: dependencies.telemetryService, settingsModel: settingsModel)
                .tabItem {
                    Label("Telemetry", systemImage: "waveform.path.ecg")
                }
                .accessibilityLabel("Telemetry tab")

            SettingsView(viewModel: settingsModel, haptics: dependencies.haptics)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .accessibilityLabel("Settings tab")
        }
    }
}
