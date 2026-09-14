import SwiftUI

struct RootView: View {
    @ObservedObject var container: AppContainer
    @EnvironmentObject private var settingsStore: AppSettingsStore

    var body: some View {
        TabView {
            MissionControlView(service: container.missionService)
                .tabItem {
                    Label(TabTitle.missionControl, systemImage: "gauge.medium")
                }
                .accessibilityIdentifier(A11y.Tab.missionControl)

            CubeLabView(viewModel: container.cubeViewModel, haptics: container.haptics)
                .tabItem {
                    Label(TabTitle.cubeLab, systemImage: "cube.fill")
                }
                .accessibilityIdentifier(A11y.Tab.cubeLab)

            TelemetryView(
                source: container.telemetrySource,
                cadence: settingsStore.settings.telemetryCadence,
                haptics: container.haptics
            )
            .tabItem {
                Label(TabTitle.telemetry, systemImage: "waveform.path.ecg")
            }
            .accessibilityIdentifier(A11y.Tab.telemetry)

            SettingsView(haptics: container.haptics, resetAll: { container.resetAllSettings() })
                .tabItem {
                    Label(TabTitle.settings, systemImage: "gearshape.fill")
                }
                .accessibilityIdentifier(A11y.Tab.settings)
        }
        .tint(settingsStore.settings.accent.color)
    }
}
