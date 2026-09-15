import SwiftUI

// MARK: - Main Tab View

/// The main tab view for the OrbitLab app
struct MainTabView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    
    // MARK: - Tab Enum
    
    enum Tab: String, CaseIterable, Identifiable {
        case missionControl
        case cubeLab
        case telemetry
        case settings
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .missionControl: return "Mission Control"
            case .cubeLab: return "Cube Lab"
            case .telemetry: return "Telemetry"
            case .settings: return "Settings"
            }
        }
        
        var systemImage: String {
            switch self {
            case .missionControl: return "globe"
            case .cubeLab: return "cube"
            case .telemetry: return "chart.line.uptrend.xyaxis"
            case .settings: return "gearshape"
            }
        }
    }
    
    // MARK: - State
    
    @State private var selectedTab: Tab = .missionControl
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MissionControlView()
                .tabItem {
                    Label(Tab.missionControl.title, systemImage: Tab.missionControl.systemImage)
                }
                .tag(Tab.missionControl)
                .accessibilityLabel("Mission Control")
                .accessibilityHint("View mission status and metrics")
            
            CubeLabView()
                .tabItem {
                    Label(Tab.cubeLab.title, systemImage: Tab.cubeLab.systemImage)
                }
                .tag(Tab.cubeLab)
                .accessibilityLabel("Cube Lab")
                .accessibilityHint("Interact with a 3D cube")
            
            TelemetryView()
                .tabItem {
                    Label(Tab.telemetry.title, systemImage: Tab.telemetry.systemImage)
                }
                .tag(Tab.telemetry)
                .accessibilityLabel("Telemetry")
                .accessibilityHint("View live telemetry data")
            
            SettingsView()
                .tabItem {
                    Label(Tab.settings.title, systemImage: Tab.settings.systemImage)
                }
                .tag(Tab.settings)
                .accessibilityLabel("Settings")
                .accessibilityHint("Configure app settings")
        }
        .tint(settingsManager.accentColorValue)
        .onAppear {
            // Configure tab bar appearance
            UITabBar.appearance().isTranslucent = true
        }
    }
}

// MARK: - Preview

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(PreviewSettingsManager())
    }
}
