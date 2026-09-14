import Foundation
import SwiftUI

struct AppSettings: Codable, Equatable {
    var accentColor: ColorRepresentation
    var hapticFeedbackEnabled: Bool
    var reducedTelemetryFrequency: Bool

    enum ColorRepresentation: String, Codable, CaseIterable {
        case systemBlue, systemPurple, systemOrange, systemGreen

        var color: Color {
            switch self {
            case .systemBlue: return .blue
            case .systemPurple: return .purple
            case .systemOrange: return .orange
            case .systemGreen: return .green
            }
        }
    }

    init(accentColor: ColorRepresentation = .systemBlue, hapticFeedbackEnabled: Bool = true, reducedTelemetryFrequency: Bool = false) {
        self.accentColor = accentColor
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.reducedTelemetryFrequency = reducedTelemetryFrequency
    }
}
