import Foundation

@MainActor
final class MissionControlViewModel: ObservableObject {
    @Published private(set) var state: LoadableState<MissionSnapshot> = .idle

    private let service: MissionControlServicing

    init(service: MissionControlServicing) {
        self.service = service
    }

    func load() async {
        state = .loading

        do {
            let snapshot = try await service.fetchSnapshot()
            state = .content(snapshot)
        } catch {
            state = .error(
                DisplayError(
                    message: "Mission data could not be loaded.",
                    recoverySuggestion: "Retry the local service synchronization."
                )
            )
        }
    }
}
