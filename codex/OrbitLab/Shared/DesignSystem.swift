import SwiftUI

struct OrbitCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
    }
}

extension View {
    func orbitCard() -> some View {
        modifier(OrbitCardModifier())
    }
}

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            content
        }
    }
}

extension View {
    func screenBackground() -> some View {
        modifier(ScreenBackground())
    }
}
