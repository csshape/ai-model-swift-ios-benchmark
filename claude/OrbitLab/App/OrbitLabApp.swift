import SwiftUI

@main
struct OrbitLabApp: App {
    @StateObject private var container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
                .environmentObject(container.settingsStore)
        }
    }
}
