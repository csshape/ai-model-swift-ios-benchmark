import SwiftUI

/// Shown while the first snapshot is loading.
struct LoadingStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

/// Shown when a load fails. Always offers a retry.
struct ErrorStateView: View {
    let failure: LoadFailure
    let retryIdentifier: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(failure.message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(failure.recoverySuggestion)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: retry) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .frame(minHeight: Theme.minimumHitTarget - 16)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier(retryIdentifier)
        }
        .frame(maxWidth: .infinity)
        .panelBackground()
    }
}

#if DEBUG
struct StateViews_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            LoadingStateView(message: "Acquiring downlink…")
            ErrorStateView(
                failure: LoadFailure(error: MissionServiceError.telemetryLinkDown),
                retryIdentifier: A11y.MissionControl.retryButton,
                retry: {}
            )
        }
        .padding()
        .background(Theme.background(for: .plasma))
        .previewLayout(.sizeThatFits)
    }
}
#endif
