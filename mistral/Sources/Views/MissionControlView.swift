import SwiftUI

// MARK: - Mission Control View

/// Displays mission status, metrics, and recent events
struct MissionControlView: View {
    @StateObject private var viewModel = MissionControlViewModel()
    @EnvironmentObject var settingsManager: SettingsManager
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Group {
                switch viewModel.state {
                case .loading:
                    loadingView
                case .content(let dashboard):
                    contentView(dashboard: dashboard)
                case .error(let error):
                    errorView(error: error)
                }
            }
            .navigationTitle("Mission Control")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.loadData) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isRefreshing)
                    .accessibilityLabel("Refresh")
                    .accessibilityHint("Reload mission data")
                }
            }
            .refreshable {
                await refreshData()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
                .tint(settingsManager.accentColorValue)
            
            Text("Loading Mission Data")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Establishing connection with mission control...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading mission data")
    }
    
    private func contentView(dashboard: MissionDashboard) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status Header
                statusHeaderView(status: dashboard.status, lastUpdated: dashboard.lastUpdated)
                
                // Metrics Cards
                metricsGridView(metrics: dashboard.metrics)
                
                // Recent Events
                eventsListView(events: dashboard.recentEvents)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(.systemBackground))
    }
    
    private func statusHeaderView(status: MissionStatus, lastUpdated: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(status.displayName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(colorForStatus(status))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: statusSystemImage(status))
                        .font(.system(size: 32))
                        .foregroundColor(colorForStatus(status))
                    
                    Text("Last Updated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(lastUpdated, style: .relative)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Mission Status: \(status.displayName)")
    }
    
    private func metricsGridView(metrics: [MissionMetric]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mission Metrics")
                .font(.headline)
                .padding(.leading, 4)
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(metrics) { metric in
                    MetricCardView(metric: metric)
                }
            }
        }
    }
    
    private func eventsListView(events: [MissionEvent]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Events")
                    .font(.headline)
                
                Spacer()
                
                Text("\(events.count) events")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if events.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                    
                    Text("No recent events")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(events) { event in
                        EventRowView(event: event)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
            }
        }
    }
    
    private func errorView(error: MissionServiceError) -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                
                Text("Connection Error")
                    .font(.title)
                    .fontWeight(.bold)
                
                if let description = error.errorDescription {
                    Text(description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: viewModel.retry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(settingsManager.accentColorValue)
            .accessibilityLabel("Retry connection")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Helper Methods
    
    private func colorForStatus(_ status: MissionStatus) -> Color {
        switch status {
        case .nominal: return .green
        case .warning: return .yellow
        case .critical: return .red
        case .offline: return .gray
        }
    }
    
    private func statusSystemImage(_ status: MissionStatus) -> String {
        switch status {
        case .nominal: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.circle.fill"
        case .offline: return "circle.dashed"
        }
    }
    
    private func refreshData() async {
        viewModel.loadData()
        // Wait for refresh to complete
        while viewModel.isRefreshing {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }
}

// MARK: - Metric Card View

struct MetricCardView: View {
    let metric: MissionMetric
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(metric.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(metric.value) \(metric.unit)")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: trendSystemImage(metric.trend))
                    .font(.system(size: 20))
                    .foregroundColor(trendColor(metric.trend))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Metric: \(metric.name), Value: \(metric.value) \(metric.unit), \(metric.trend.rawValue.capitalized)")
    }
    
    private func trendSystemImage(_ trend: Trend) -> String {
        switch trend {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .stable: return "minus"
        }
    }
    
    private func trendColor(_ trend: Trend) -> Color {
        switch trend {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        }
    }
}

// MARK: - Event Row View

struct EventRowView: View {
    let event: MissionEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .center, spacing: 4) {
                Image(systemName: eventTypeSystemImage(event.type))
                    .font(.system(size: 16))
                    .foregroundColor(eventSeverityColor(event.severity))
                
                Text(event.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.description)
                    .font(.body)
                    .lineLimit(2)
                
                Text(event.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            severityIndicator(event.severity)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Event: \(event.description), Type: \(event.type.rawValue), Severity: \(event.severity.rawValue)")
    }
    
    private func eventTypeSystemImage(_ type: EventType) -> String {
        switch type {
        case .systemStartup: return "power"
        case .systemShutdown: return "power"
        case .sensorCalibration: return "target"
        case .trajectoryAdjustment: return "location"
        case .communicationEstablished: return "antenna.radiowaves.left.and.right"
        case .communicationLost: return "antenna.radiowaves.left.and.right.slash"
        case .powerCycle: return "arrow.triangle.2.circlepath"
        }
    }
    
    private func eventSeverityColor(_ severity: EventSeverity) -> Color {
        switch severity {
        case .info: return .blue
        case .warning: return .yellow
        case .error: return .red
        }
    }
    
    private func severityIndicator(_ severity: EventSeverity) -> some View {
        Circle()
            .frame(width: 8, height: 8)
            .foregroundColor(eventSeverityColor(severity))
    }
}

// MARK: - Preview

struct MissionControlView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MissionControlView()
                .environmentObject(PreviewSettingsManager())
        }
    }
}
