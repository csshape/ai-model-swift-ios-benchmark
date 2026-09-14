import SwiftUI

struct TelemetryView: View {
    @ObservedObject private var settingsModel: AppSettingsViewModel
    @StateObject private var viewModel: TelemetryViewModel

    init(service: TelemetryStreaming, settingsModel: AppSettingsViewModel) {
        self.settingsModel = settingsModel
        _viewModel = StateObject(wrappedValue: TelemetryViewModel(service: service))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    CurrentTelemetryView(point: viewModel.current, isRunning: viewModel.isRunning)

                    TelemetryGraphView(points: viewModel.history)
                        .frame(height: 210)
                        .orbitCard()
                        .accessibilityIdentifier("telemetry.graph")

                    HStack(spacing: 12) {
                        Button {
                            viewModel.isRunning ? viewModel.pause() : viewModel.start(reducedFrequency: settingsModel.settings.reducedTelemetryFrequency)
                        } label: {
                            Label(viewModel.isRunning ? "Pause Stream" : "Start Stream", systemImage: viewModel.isRunning ? "pause.fill" : "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .accessibilityIdentifier("telemetry.stream.toggle")

                        Button {
                            viewModel.clear()
                        } label: {
                            Label("Clear", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .accessibilityIdentifier("telemetry.clear.button")
                    }
                    .orbitCard()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("History")
                                .font(.headline)
                            Spacer()
                            Text("\(viewModel.history.count)/\(viewModel.maxHistoryCount)")
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.secondary)
                        }

                        ForEach(viewModel.history.reversed()) { point in
                            HStack {
                                Text("#\(point.id)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(.secondary)
                                    .frame(width: 48, alignment: .leading)
                                Text(point.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(point.formattedValue)
                                    .font(.body.monospacedDigit().weight(.semibold))
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .orbitCard()
                }
                .padding()
            }
            .screenBackground()
            .navigationTitle("Telemetry")
        }
        .navigationViewStyle(.stack)
        .task {
            if !viewModel.isRunning {
                viewModel.start(reducedFrequency: settingsModel.settings.reducedTelemetryFrequency)
            }
        }
        .onDisappear {
            viewModel.pause()
        }
        .onChange(of: settingsModel.settings.reducedTelemetryFrequency) { reduced in
            viewModel.updateReducedFrequency(reduced)
        }
    }
}

private struct CurrentTelemetryView: View {
    let point: TelemetryPoint?
    let isRunning: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: isRunning ? "waveform.path.ecg" : "pause.circle")
                .font(.largeTitle)
                .foregroundColor(isRunning ? .green : .secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Current Signal")
                    .font(.headline)
                Text(point?.formattedValue ?? "--")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold).monospacedDigit())
                    .minimumScaleFactor(0.7)
                    .accessibilityIdentifier("telemetry.current.value")
                Text(isRunning ? "Live deterministic stream" : "Stream paused")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .orbitCard()
        .accessibilityElement(children: .combine)
    }
}

struct TelemetryGraphView: View {
    let points: [TelemetryPoint]

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 10, dy: 14)
            drawGrid(context: &context, rect: rect)

            guard points.count > 1 else {
                drawBaseline(context: &context, rect: rect)
                return
            }

            let values = points.map(\.value)
            guard let minValue = values.min(), let maxValue = values.max() else {
                return
            }

            let range = max(maxValue - minValue, 1)
            var path = Path()

            for (index, point) in points.enumerated() {
                let x = rect.minX + rect.width * CGFloat(index) / CGFloat(points.count - 1)
                let normalized = (point.value - minValue) / range
                let y = rect.maxY - rect.height * CGFloat(normalized)

                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            context.stroke(path, with: .color(.accentColor), lineWidth: 3)
        }
        .accessibilityLabel("Telemetry graph with \(points.count) values")
    }

    private func drawGrid(context: inout GraphicsContext, rect: CGRect) {
        var grid = Path()
        for index in 0...4 {
            let y = rect.minY + rect.height * CGFloat(index) / 4
            grid.move(to: CGPoint(x: rect.minX, y: y))
            grid.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        context.stroke(grid, with: .color(Color.secondary.opacity(0.25)), lineWidth: 1)
    }

    private func drawBaseline(context: inout GraphicsContext, rect: CGRect) {
        var baseline = Path()
        baseline.move(to: CGPoint(x: rect.minX, y: rect.midY))
        baseline.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        context.stroke(baseline, with: .color(Color.secondary.opacity(0.35)), style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
    }
}

#if DEBUG
struct TelemetryView_Previews: PreviewProvider {
    static var previews: some View {
        TelemetryView(
            service: DeterministicTelemetryService(),
            settingsModel: AppSettingsViewModel(store: PreviewSettingsStore())
        )
    }
}
#endif
