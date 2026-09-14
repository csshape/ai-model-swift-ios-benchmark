import SwiftUI

struct MissionControlView: View {
    @StateObject private var viewModel: MissionControlViewModel

    init(service: MissionControlServicing) {
        _viewModel = StateObject(wrappedValue: MissionControlViewModel(service: service))
    }

    var body: some View {
        NavigationView {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    LoadingMissionView()
                case .content(let snapshot):
                    MissionContentView(snapshot: snapshot)
                        .refreshable {
                            await viewModel.load()
                        }
                case .error(let error):
                    MissionErrorView(error: error) {
                        Task {
                            await viewModel.load()
                        }
                    }
                }
            }
            .navigationTitle("Mission Control")
            .task {
                if viewModel.state.isIdle {
                    await viewModel.load()
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

private struct LoadingMissionView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Synchronizing mission data")
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .screenBackground()
        .accessibilityIdentifier("mission.loading")
    }
}

private struct MissionContentView: View {
    let snapshot: MissionSnapshot

    private let columns = [
        GridItem(.adaptive(minimum: 145), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                MissionStatusHeader(snapshot: snapshot)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(snapshot.metrics) { metric in
                        MetricCardView(metric: metric)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Recent Events")
                        .font(.headline)
                    ForEach(snapshot.events) { event in
                        MissionEventRow(event: event)
                    }
                }
                .orbitCard()
            }
            .padding()
        }
        .screenBackground()
    }
}

private struct MissionStatusHeader: View {
    let snapshot: MissionSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                Text(snapshot.statusTitle)
                    .font(.title2.weight(.semibold))
                    .accessibilityIdentifier("mission.status.title")
            }
            Text(snapshot.statusDetail)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .orbitCard()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("mission.status.header")
    }
}

private struct MetricCardView: View {
    let metric: MissionMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(metric.title, systemImage: metric.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
            Text(metric.value)
                .font(.title3.weight(.bold))
                .minimumScaleFactor(0.8)
            Text(metric.detail)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .orbitCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(metric.title), \(metric.value), \(metric.detail)")
    }
}

private struct MissionEventRow: View {
    let event: MissionEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.title)
                        .font(.subheadline.weight(.semibold))
                    Spacer(minLength: 8)
                    Text(event.severity.label)
                        .font(.caption.weight(.medium))
                        .foregroundColor(iconColor)
                }
                Text(event.detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(event.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var iconName: String {
        switch event.severity {
        case .nominal:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "xmark.octagon.fill"
        }
    }

    private var iconColor: Color {
        switch event.severity {
        case .nominal:
            return .green
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }
}

private struct MissionErrorView: View {
    let error: DisplayError
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(error.message)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(error.recoverySuggestion)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(action: retry) {
                Label("Retry", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("mission.retry.button")
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .screenBackground()
        .accessibilityIdentifier("mission.error")
    }
}

#if DEBUG
private struct PreviewMissionService: MissionControlServicing {
    func fetchSnapshot() async throws -> MissionSnapshot {
        MissionSnapshot.sample
    }
}

struct MissionControlView_Previews: PreviewProvider {
    static var previews: some View {
        MissionControlView(service: PreviewMissionService())
    }
}
#endif
