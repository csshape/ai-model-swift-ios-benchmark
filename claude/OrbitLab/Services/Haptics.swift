import UIKit

/// The kinds of feedback the app plays.
enum HapticKind {
    case selection
    case impact
}

/// Feedback seam so views never touch `UIFeedbackGenerator` directly and tests stay silent.
protocol HapticsProviding: AnyObject {
    func play(_ kind: HapticKind)
}

/// Production feedback. Stateless, so it is safe to call from anywhere.
final class SystemHaptics: HapticsProviding {
    func play(_ kind: HapticKind) {
        Task { @MainActor in
            switch kind {
            case .selection:
                UISelectionFeedbackGenerator().selectionChanged()
            case .impact:
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
}

/// Used in tests, previews and UI test runs.
final class SilentHaptics: HapticsProviding {
    private(set) var playedKinds: [HapticKind] = []

    func play(_ kind: HapticKind) {
        playedKinds.append(kind)
    }
}
