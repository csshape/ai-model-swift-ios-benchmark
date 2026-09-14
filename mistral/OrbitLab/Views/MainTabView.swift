import SwiftUI

struct MainTabView: View {
    @State private var selected = 0
    var body: some View {
        TabView(selection: $selected) {
            MissionControlView().tabItem { Label("Mission Control", systemImage: "checkmark.shield") }.tag(0).accessibilityIdentifier("missionControlTab")
            CubeLabView().tabItem { Label("Cube Lab", systemImage: "cube") }.tag(1).accessibilityIdentifier("cubeLabTab")
            TelemetryView().tabItem { Label("Telemetry", systemImage: "chart.line.uptrend.xyaxis") }.tag(2).accessibilityIdentifier("telemetryTab")
            SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }.tag(3).accessibilityIdentifier("settingsTab")
        }
        .tint(.blue)
        .accessibilityIdentifier("mainTabView")
    }
}
