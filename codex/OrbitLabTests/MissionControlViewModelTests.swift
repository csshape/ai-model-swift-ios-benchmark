import XCTest
@testable import OrbitLab

@MainActor
final class MissionControlViewModelTests: XCTestCase {
    func testLoadMovesFromLoadingToContent() async {
        let service = MissionServiceStub(results: [.success(.sample)], yieldsBeforeReturning: true)
        let viewModel = MissionControlViewModel(service: service)

        let task = Task {
            await viewModel.load()
        }

        await Task.yield()

        if case .loading = viewModel.state {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected loading state before the async service completed.")
        }

        await task.value

        if case .content(let snapshot) = viewModel.state {
            XCTAssertEqual(snapshot, MissionSnapshot.sample)
        } else {
            XCTFail("Expected content state after a successful load.")
        }

        XCTAssertEqual(service.callCount, 1)
    }

    func testErrorThenRetryLoadsContent() async {
        let service = MissionServiceStub(results: [.failure(TestError.expected), .success(.sample)])
        let viewModel = MissionControlViewModel(service: service)

        await viewModel.load()

        if case .error(let error) = viewModel.state {
            XCTAssertEqual(error.message, "Mission data could not be loaded.")
        } else {
            XCTFail("Expected error state after service failure.")
        }

        await viewModel.load()

        if case .content(let snapshot) = viewModel.state {
            XCTAssertEqual(snapshot.statusTitle, "Nominal Orbit")
        } else {
            XCTFail("Expected retry to load content.")
        }

        XCTAssertEqual(service.callCount, 2)
    }
}

private final class MissionServiceStub: MissionControlServicing {
    private var results: [Result<MissionSnapshot, Error>]
    private let yieldsBeforeReturning: Bool
    private(set) var callCount = 0

    init(results: [Result<MissionSnapshot, Error>], yieldsBeforeReturning: Bool = false) {
        self.results = results
        self.yieldsBeforeReturning = yieldsBeforeReturning
    }

    func fetchSnapshot() async throws -> MissionSnapshot {
        callCount += 1

        if yieldsBeforeReturning {
            await Task.yield()
        }

        guard !results.isEmpty else {
            throw TestError.expected
        }

        return try results.removeFirst().get()
    }
}
