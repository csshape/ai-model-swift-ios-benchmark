import Foundation

/// Stable identifiers shared between the app and the UI test target.
///
/// The file is compiled into both targets so a rename can never silently break a UI test.
enum A11y {
    enum Tab {
        static let missionControl = "tab.missionControl"
        static let cubeLab = "tab.cubeLab"
        static let telemetry = "tab.telemetry"
        static let settings = "tab.settings"
    }

    enum MissionControl {
        static let root = "missionControl.root"
        static let statusHeader = "missionControl.statusHeader"
        static let retryButton = "missionControl.retryButton"
        static let eventList = "missionControl.eventList"
    }

    enum CubeLab {
        static let root = "cubeLab.root"
        static let scene = "cubeLab.scene"
        static let playPauseButton = "cubeLab.playPauseButton"
        static let resetButton = "cubeLab.resetButton"
        static let speedSlider = "cubeLab.speedSlider"
        static let statusLabel = "cubeLab.statusLabel"
    }

    enum Telemetry {
        static let root = "telemetry.root"
        static let chart = "telemetry.chart"
        static let currentValue = "telemetry.currentValue"
        static let startPauseButton = "telemetry.startPauseButton"
        static let clearButton = "telemetry.clearButton"
        static let cadenceLabel = "telemetry.cadenceLabel"
    }

    enum Settings {
        static let root = "settings.root"
        static let accentPicker = "settings.accentPicker"
        static let hapticsToggle = "settings.hapticsToggle"
        static let reducedCadenceToggle = "settings.reducedCadenceToggle"
        static let resetButton = "settings.resetButton"
        static let summary = "settings.summary"
    }

    /// Launch argument that makes the app start from a clean, in-memory store.
    static let uiTestLaunchArgument = "-orbitlab-ui-tests"
}

/// Tab bar titles. Shared with the UI test target so a copy change cannot silently
/// break navigation in the tests.
enum TabTitle {
    static let missionControl = "Mission Control"
    static let cubeLab = "Cube Lab"
    static let telemetry = "Telemetry"
    static let settings = "Settings"
}
