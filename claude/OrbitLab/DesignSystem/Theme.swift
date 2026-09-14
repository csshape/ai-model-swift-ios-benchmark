import SwiftUI
import UIKit

extension AccentChoice {
    /// Accent colours are defined in code rather than in an asset catalog so every value is
    /// visible next to the design it belongs to, and both appearances are explicit.
    var color: Color {
        Color(uiColor: UIColor { traits in
            let isDark = traits.userInterfaceStyle == .dark
            switch self {
            case .aurora:
                return isDark
                    ? UIColor(red: 0.40, green: 0.85, blue: 0.78, alpha: 1)
                    : UIColor(red: 0.02, green: 0.51, blue: 0.48, alpha: 1)
            case .plasma:
                return isDark
                    ? UIColor(red: 0.71, green: 0.55, blue: 1.00, alpha: 1)
                    : UIColor(red: 0.41, green: 0.24, blue: 0.79, alpha: 1)
            case .solar:
                return isDark
                    ? UIColor(red: 1.00, green: 0.71, blue: 0.31, alpha: 1)
                    : UIColor(red: 0.75, green: 0.40, blue: 0.02, alpha: 1)
            }
        })
    }
}

/// Shared visual language for the mission control look.
enum Theme {
    /// Deep space backdrop that still reads as a normal grouped background in light mode.
    static func background(for accent: AccentChoice) -> some View {
        LinearGradient(
            colors: [
                Color(uiColor: UIColor { traits in
                    traits.userInterfaceStyle == .dark
                        ? UIColor(red: 0.04, green: 0.05, blue: 0.10, alpha: 1)
                        : UIColor(red: 0.94, green: 0.95, blue: 0.98, alpha: 1)
                }),
                Color(uiColor: UIColor { traits in
                    traits.userInterfaceStyle == .dark
                        ? UIColor(red: 0.07, green: 0.08, blue: 0.16, alpha: 1)
                        : UIColor(red: 0.89, green: 0.91, blue: 0.96, alpha: 1)
                })
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            RadialGradient(
                colors: [accent.color.opacity(0.22), .clear],
                center: .topTrailing,
                startRadius: 8,
                endRadius: 420
            )
        )
        .ignoresSafeArea()
    }

    static let cornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 16
    /// Apple's minimum comfortable hit target.
    static let minimumHitTarget: CGFloat = 44
}

/// Card chrome used by every panel in the app.
struct PanelBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.cardPadding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}

extension View {
    func panelBackground() -> some View {
        modifier(PanelBackground())
    }
}
