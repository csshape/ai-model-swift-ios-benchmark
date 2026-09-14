import UIKit

@MainActor
protocol HapticPerforming {
    func selectionChanged()
}

struct UIKitHapticPerformer: HapticPerforming {
    func selectionChanged() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

struct NoOpHapticPerformer: HapticPerforming {
    func selectionChanged() {}
}
