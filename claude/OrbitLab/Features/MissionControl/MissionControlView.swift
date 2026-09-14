import SwiftUI

struct MissionControlView: View {
    @StateObject private var viewModel: MissionControlViewModel
    @EnvironmentObject private var settingsStore: AppSettingsStore

    init(service: MissionService) {
        _viewModel = StateObject(wrappedValue: MissionControlViewModel(service: service))
    }

    private var accent: AccentChoice { settingsStore.settings.accent }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background(for: accent)
                content
            }
            .navigationTitle("Mission Control")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(.stack)
        .accessibilityIdentifier(A11y.MissionControl.root)
        .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch viewModel.state {
                case .idle, .loading:
                    LoadingStateView(message: "Acquiring mission downlink…")
                        .padding(.top, 40)
                case let .failed(failure):
                    ErrorStateView(failure: failure, retryIdentifier: A11y.MissionControl.retryButton) {
                        Task { await viewModel.retry() }
                    }
                case let .content(snapshot):
                    statusHeader(snapshot)
                    metrics(snapshot)
                    events(snapshot)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .refreshable { await viewModel.refresh() }
    }

    private func statusHeader(_ snapshot: MissionSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: snapshot.status.symbolName)
                    .font(.title2)
                    .foregroundStyle(accent.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(snapshot.status.title)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(snapshot.vehicle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            Text(snapshot.formattedElapsedTime)
                .font(.title.weight(.bold))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .panelBackground()
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier(A11y.MissionControl.statusHeader)
        .accessibilityLabel("Mission status")
        .accessibilityValue("\(snapshot.status.title), \(snapshot.vehicle), elapsed \(snapshot.formattedElapsedTime)")
    }

    private func metrics(_ snapshot: MissionSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key metrics")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(snapshot.metrics) { metric in
                    MetricCard(metric: metric, accent: accent)
                }
            }
        }
    }

    private func events(_ snapshot: MissionSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent events")
                .font(.headline)
            LazyVStack(spacing: 10) {
                ForEach(snapshot.events) { event in
                    MissionEventRow(event: event, accent: accent)
                }
            }
            .accessibilityIdentifier(A11y.MissionControl.eventList)
        }
    }
}

struct MissionEventRow: View {
    let event: MissionEvent
    let accent: AccentChoice

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: event.severity.symbolName)
                .font(.body.weight(.semibold))
                .foregroundStyle(event.severity == .info ? accent.color : Color.orange)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.body.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
                Text(event.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Text(Self.timeFormatter.string(from: event.timestamp))
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .panelBackground()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(event.severity.rawValue) event, \(event.title)")
        .accessibilityValue(event.detail)
    }
}

#if DEBUG
struct MissionControlView_Previews: PreviewProvider {
    static var previews: some View {
        MissionControlView(service: LocalMissionService())
            .environmentObject(AppSettingsStore(store: InMemoryKeyValueStore()))
    }
}
#endif
