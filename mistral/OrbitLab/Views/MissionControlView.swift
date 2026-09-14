import SwiftUI

@MainActor class MissionControlVM: ObservableObject {
    enum State { case loading, content(MissionControlData), error(MissionControlError) }
    @Published var state: State = .loading
    @Published var isRefreshing = false
    private let service: MissionControlServiceProtocol
    init(service: MissionControlServiceProtocol = MissionControlService()) {
        self.service = service
        load()
    }
    func load() {
        guard !isRefreshing else { return }
        isRefreshing = true
        state = .loading
        Task {
            do {
                let data = try await service.fetchMissionData()
                await MainActor.run { state = .content(data); isRefreshing = false }
            } catch let e as MissionControlError {
                await MainActor.run { state = .error(e); isRefreshing = false }
            } catch {
                await MainActor.run { state = .error(.unknownError); isRefreshing = false }
            }
        }
    }
    var metrics: MissionMetrics? { if case .content(let d) = state { return d.metrics } else { return nil } }
    var events: [MissionEvent] { if case .content(let d) = state { return d.events } else { return [] } }
    var lastUpdated: Date? { if case .content(let d) = state { return d.lastUpdated } else { return nil } }
    var err: MissionControlError? { if case .error(let e) = state { return e } else { return nil } }
}

struct MissionControlView: View {
    @StateObject var vm = MissionControlVM()
    var body: some View {
        NavigationView {
            ZStack {
                switch vm.state {
                case .loading: ProgressView("Loading...").scaleEffect(1.5)
                case .content(_): content
                case .error(_): errorView
                }
            }
            .navigationTitle("Mission Control")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button(action: vm.load) { Image(systemName: "arrow.clockwise") } } }
            .refreshable { vm.load() }
            .accessibilityIdentifier("missionControlView")
        }
    }
    var content: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill").foregroundColor(.green)
                        Text("All Systems Operational").font(.title2).fontWeight(.semibold)
                        Spacer()
                        if let d = vm.lastUpdated { Text("Updated: \(d.formatted(.relative(presentation: .named)))").font(.caption).foregroundColor(.secondary) }
                    }
                }.padding().background(Color.green.opacity(0.1)).cornerRadius(12).accessibilityIdentifier("statusHeader")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    MetricCardView(title: "Total Missions", value: "\(vm.metrics?.totalMissions ?? 0)", subtitle: "Completed: \(vm.metrics?.successfulMissions ?? 0)", icon: "rocket", color: .blue)
                    MetricCardView(title: "Active Missions", value: "\(vm.metrics?.activeMissions ?? 0)", subtitle: "In Progress", icon: "satellite", color: .green)
                    MetricCardView(title: "Avg Duration", value: "\(Int(vm.metrics?.averageDuration ?? 0)/60)m", subtitle: "Per Mission", icon: "clock", color: .orange)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Events").font(.headline).padding(.horizontal, 4)
                    if vm.events.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text.magnifyingglass").font(.system(size: 40)).foregroundColor(.secondary)
                            Text("No recent events").font(.subheadline).foregroundColor(.secondary)
                        }.frame(maxWidth: .infinity).padding(40).background(Color(.secondarySystemBackground)).cornerRadius(12)
                    } else {
                        ForEach(vm.events) { e in eventRow(e) }
                    }
                }
            }.padding()
        }
    }
    func eventRow(_ e: MissionEvent) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconFor(e.status)).font(.title3).foregroundColor(colorFor(e.status)).frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(e.missionName).font(.subheadline).fontWeight(.medium)
                Text(e.description).font(.caption).foregroundColor(.secondary)
                Text(e.timestamp.formatted(.relative(presentation: .named))).font(.caption).foregroundColor(.blue)
            }
            Spacer()
            Text(textFor(e.status)).font(.caption).fontWeight(.medium).padding(.horizontal, 8).padding(.vertical, 4).background(colorFor(e.status).opacity(0.1)).foregroundColor(colorFor(e.status)).cornerRadius(4)
        }.padding().background(Color(.secondarySystemBackground)).cornerRadius(12)
    }
    var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 60)).foregroundColor(.red)
            Text("Error Loading Data").font(.title).fontWeight(.bold)
            Text(errDesc).font(.body).foregroundColor(.secondary).multilineTextAlignment(.center)
            Button(action: vm.load) { Label("Retry", systemImage: "arrow.clockwise") }.buttonStyle(.borderedProminent).accessibilityIdentifier("retryButton")
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    var errDesc: String {
        switch vm.err {
        case .networkError: return "Unable to connect to the service"
        case .invalidData: return "Invalid data received"
        case .serviceUnavailable: return "Service unavailable"
        case .unknownError, .none: return "An error occurred"
        }
    }
    func iconFor(_ s: MissionEvent.MissionStatus) -> String {
        switch s { case .pending: return "clock"; case .inProgress: return "arrow.2.circlepath"; case .completed: return "checkmark.circle.fill"; case .failed: return "xmark.circle.fill"; case .cancelled: return "slash.circle.fill" }
    }
    func colorFor(_ s: MissionEvent.MissionStatus) -> Color {
        switch s { case .pending: return .orange; case .inProgress: return .blue; case .completed: return .green; case .failed: return .red; case .cancelled: return .gray }
    }
    func textFor(_ s: MissionEvent.MissionStatus) -> String {
        switch s { case .pending: return "Pending"; case .inProgress: return "In Progress"; case .completed: return "Completed"; case .failed: return "Failed"; case .cancelled: return "Cancelled" }
    }
}
