import Foundation
import SwiftUI

// MARK: - Mission Control View State

enum MissionViewState {
    case loading
    case content(MissionDashboard)
    case error(MissionServiceError)
}

// MARK: - Mission Control View Model

/// ViewModel for Mission Control tab
class MissionControlViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var state: MissionViewState = .loading
    @Published var isRefreshing = false
    
    // MARK: - Private Properties
    
    private let missionService: MissionServiceProtocol
    private var refreshTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    /// Initialize with a mission service
    /// - Parameter missionService: The service to fetch mission data
    init(missionService: MissionServiceProtocol = ProductionMissionService()) {
        self.missionService = missionService
        loadData()
    }
    
    // MARK: - Public Methods
    
    /// Loads mission data
    func loadData() {
        refreshTask?.cancel()
        
        if !isRefreshing {
            isRefreshing = true
        }
        
        state = .loading
        
        refreshTask = Task { [weak self] in
            await self?.fetchMissionData()
        }
    }
    
    /// Retries after an error
    func retry() {
        loadData()
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func fetchMissionData() async {
        defer {
            isRefreshing = false
        }
        
        do {
            let dashboard = try await missionService.fetchDashboard()
            state = .content(dashboard)
        } catch let error as MissionServiceError {
            state = .error(error)
        } catch {
            state = .error(.unknownError)
        }
    }
}

// MARK: - Preview View Model

final class PreviewMissionControlViewModel: MissionControlViewModel {
    init() {
        super.init(missionService: PreviewMissionService())
    }
}
