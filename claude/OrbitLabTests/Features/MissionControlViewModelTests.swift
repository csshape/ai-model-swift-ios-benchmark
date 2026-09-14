import Combine
import XCTest
@testable import OrbitLab

@MainActor
final class MissionControlViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func test_loadIfNeeded_movesFromIdleThroughLoadingToContent() async {
        let snapshot = TestFixtures.snapshot
        let service = StubMissionService(snapshot: snapshot)
        let viewModel = MissionControlViewModel(service: service)

        var observedStates: [LoadState<MissionSnapshot>] = []
        viewModel.$state
            .sink { observedStates.append($0) }
            .store(in: &cancellables)

        await viewModel.loadIfNeeded()

        XCTAssertEqual(observedStates, [.idle, .loading, .content(snapshot)])
        XCTAssertEqual(viewModel.state.value, snapshot)
        XCTAssertEqual(service.callCount, 1)
    }

    func test_loadIfNeeded_doesNotReloadWhenContentIsAlreadyLoaded() async {
        let service = StubMissionService(snapshot: TestFixtures.snapshot)
        let viewModel = MissionControlViewModel(service: service)

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        XCTAssertEqual(service.callCount, 1)
    }

    func test_failedLoad_exposesUserFacingFailure_andRetrySucceeds() async {
        let snapshot = TestFixtures.snapshot
        let service = StubMissionService(responses: [
            .failure(MissionServiceError.telemetryLinkDown),
            .success(snapshot)
        ])
        let viewModel = MissionControlViewModel(service: service)

        await viewModel.loadIfNeeded()

        XCTAssertEqual(viewModel.state.failure?.message, "Lost contact with the mission data link.")
        XCTAssertEqual(viewModel.state.failure?.recoverySuggestion, "Check the relay and try again.")
        XCTAssertNil(viewModel.state.value)

        await viewModel.retry()

        XCTAssertEqual(viewModel.state.value, snapshot)
        XCTAssertNil(viewModel.state.failure)
        XCTAssertEqual(service.callCount, 2)
    }

    func test_refresh_keepsExistingContentVisibleInsteadOfShowingLoadingAgain() async {
        let first = TestFixtures.snapshot
        let second = TestFixtures.snapshot(status: .degraded)
        let service = StubMissionService(responses: [.success(first), .success(second)])
        let viewModel = MissionControlViewModel(service: service)

        await viewModel.loadIfNeeded()

        var statesDuringRefresh: [LoadState<MissionSnapshot>] = []
        viewModel.$state
            .sink { statesDuringRefresh.append($0) }
            .store(in: &cancellables)

        await viewModel.refresh()

        XCTAssertEqual(statesDuringRefresh, [.content(first), .content(second)])
    }

    /// Edge case: a refresh that fails must not wipe the data the user is already reading.
    func test_refreshFailureAfterSuccess_replacesContentWithARetryableError() async {
        let service = StubMissionService(responses: [
            .success(TestFixtures.snapshot),
            .failure(MissionServiceError.telemetryLinkDown)
        ])
        let viewModel = MissionControlViewModel(service: service)

        await viewModel.loadIfNeeded()
        await viewModel.refresh()

        XCTAssertNotNil(viewModel.state.failure)
        XCTAssertFalse(viewModel.state.isLoading)
    }
}
