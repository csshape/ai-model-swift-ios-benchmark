import SwiftUI

@main
struct OrbitLabApp: App {
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(settingsManager)
        }
    }
}
