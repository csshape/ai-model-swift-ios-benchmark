import SwiftUI

// MARK: - Telemetry View

/// Displays live telemetry data with a custom graph
struct TelemetryView: View {
    @StateObject private var viewModel: TelemetryViewModel
    @EnvironmentObject var settingsManager: SettingsManager
    
    // MARK: - Initialization
    
    init() {
        let telemetryService = ProductionTelemetryService()
        let viewModel = TelemetryViewModel(
            telemetryService: telemetryService,
            reducedFrequency: false // Default, will be updated via onAppear
        )
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Current Value Display
                currentValueView
                
                // Graph View
                graphView
                    .frame(height: 200)
                
                // History List
                historyView
                    .frame(maxHeight: 150)
                
                // Controls
                controlsView
            }
            .padding()
            .navigationTitle("Telemetry")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Sync with settings manager
                viewModel.setReducedFrequency(settingsManager.reducedTelemetryFrequency)
            }
            .onChange(of: settingsManager.reducedTelemetryFrequency) { newValue in
                viewModel.setReducedFrequency(newValue)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var currentValueView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "waveform")
                Text("Current Value")
            }
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(String(format: "%.1f", viewModel.currentValue))
                .font(.system(size: 48, weight: .bold))
                .monospacedDigit()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current value: \(String(format: "%.1f", viewModel.currentValue))")
    }
    
    private var graphView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack {
                // Grid lines
                Path { path in
                    // Horizontal grid lines
                    for i in 0..<5 {
                        let y = height * CGFloat(i) / 4
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                }
                .stroke(Color(.separator), style: StrokeStyle(lineWidth: 1, dash: [4]))
                
                // Data line
                telemetryLinePath(width: width, height: height)
                    .stroke(settingsManager.accentColorValue, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                
                // Data points
                ForEach(Array(viewModel.dataPoints.enumerated()), id: \.element.id) { index, point in
                    let xPosition = width * CGFloat(index) / CGFloat(max(viewModel.dataPoints.count - 1, 1))
                    let yValue = normalizeValue(point.value, minVal: 0, maxVal: 100)
                    let yPosition = height * (1 - CGFloat(yValue))
                    
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundColor(settingsManager.accentColorValue)
                        .position(x: xPosition, y: yPosition)
                        .accessibilityHidden(true)
                }
            }
            .frame(width: width, height: height)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityLabel("Telemetry graph showing \(viewModel.dataPoints.count) data points")
    }
    
    private var historyView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent History")
                .font(.headline)
            
            if viewModel.dataPoints.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                    Text("No data yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 100)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(viewModel.dataPoints) { point in
                            HStack {
                                Text(String(format: "%.1f", point.value))
                                    .monospacedDigit()
                                    .frame(width: 50, alignment: .leading)
                                
                                Text(point.label)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private var controlsView: some View {
        HStack(spacing: 16) {
            Button(action: viewModel.toggle) {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isRunning ? "stop.fill" : "play.fill")
                    Text(viewModel.isRunning ? "Stop" : "Start")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(viewModel.isRunning ? .red : settingsManager.accentColorValue)
            .disabled(viewModel.isPaused)
            .accessibilityLabel(viewModel.isRunning ? "Stop telemetry" : "Start telemetry")
            
            if viewModel.isRunning {
                Button(action: viewModel.pause) {
                    Image(systemName: "pause.fill")
                }
                .buttonStyle(.bordered)
                .tint(settingsManager.accentColorValue)
                .disabled(viewModel.isPaused)
                .accessibilityLabel("Pause telemetry")
                
                Button(action: viewModel.resume) {
                    Image(systemName: "play.fill")
                }
                .buttonStyle(.bordered)
                .tint(settingsManager.accentColorValue)
                .disabled(!viewModel.isPaused)
                .accessibilityLabel("Resume telemetry")
            }
            
            Button(action: { viewModel.showClearConfirmation = true }) {
                Image(systemName: "trash")
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .confirmationDialog(
                "Clear Data",
                isPresented: $viewModel.showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear Data", role: .destructive) {
                    viewModel.clear()
                }
            } message: {
                Text("This will remove all telemetry history.")
            }
            .accessibilityLabel("Clear data")
        }
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Helper Methods
    
    private func telemetryLinePath(width: CGFloat, height: CGFloat) -> Path {
        var path = Path()
        
        guard !viewModel.dataPoints.isEmpty else {
            return path
        }
        
        let points = viewModel.dataPoints
        
        for (index, point) in points.enumerated() {
            let xPosition = width * CGFloat(index) / CGFloat(max(points.count - 1, 1))
            let yValue = normalizeValue(point.value, minVal: 0, maxVal: 100)
            let yPosition = height * (1 - CGFloat(yValue))
            
            if index == 0 {
                path.move(to: CGPoint(x: xPosition, y: yPosition))
            } else {
                path.addLine(to: CGPoint(x: xPosition, y: yPosition))
            }
        }
        
        return path
    }
    
    private func normalizeValue(_ value: Double, minVal: Double, maxVal: Double) -> Double {
        let clamped = max(minVal, Swift.min(value, maxVal))
        return (clamped - minVal) / (maxVal - minVal)
    }
}

// MARK: - Preview

struct TelemetryView_Previews: PreviewProvider {
    static var previews: some View {
        TelemetryView()
            .environmentObject(PreviewSettingsManager())
    }
}
