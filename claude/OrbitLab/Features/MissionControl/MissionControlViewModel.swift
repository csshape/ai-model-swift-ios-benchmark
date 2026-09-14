import Foundation

/// Drives the Mission Control dashboard through idle → loading → content/failed.
@MainActor
final class MissionControlViewModel: ObservableObject {
    @Published private(set) var state: LoadState<MissionSnapshot> = .idle

    private let service: MissionService

    init(service: MissionService) {
        self.service = service
    }

    /// Called by `.task`. Does nothing if content is already on screen so switching tabs
    /// does not re-trigger a load.
    func loadIfNeeded() async {
        guard state.value == nil else { return }
        await load(showsLoadingState: true)
    }

    /// Pull to refresh. Keeps the current content visible while the new snapshot is fetched.
    func refresh() async {
        await load(showsLoadingState: state.value == nil)
    }

    /// Retry after a failure.
    func retry() async {
        await load(showsLoadingState: true)
    }

    private func load(showsLoadingState: Bool) async {
        if showsLoadingState {
            state = .loading
        }
        do {
            let snapshot = try await service.loadSnapshot()
            state = .content(snapshot)
        } catch is CancellationError {
            // Leaving the screen is not a user facing error.
        } catch {
            state = .failed(LoadFailure(error: error))
        }
    }
}
