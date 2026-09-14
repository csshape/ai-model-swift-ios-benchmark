import SwiftUI

struct TelemetryView: View {
    @StateObject private var viewModel: TelemetryViewModel
    @EnvironmentObject private var settingsStore: AppSettingsStore

    let haptics: HapticsProviding

    init(source: TelemetrySource, cadence: TelemetryCadence, haptics: HapticsProviding) {
        _viewModel = StateObject(wrappedValue: TelemetryViewModel(source: source, cadence: cadence))
        self.haptics = haptics
    }

    private var accent: AccentChoice { settingsStore.settings.accent }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background(for: accent)
                ScrollView {
                    VStack(spacing: 20) {
                        readoutCard
                        chartCard
                        controls
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Telemetry")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
        .accessibilityIdentifier(A11y.Telemetry.root)
        .onChange(of: settingsStore.settings.telemetryCadence) { cadence in
            viewModel.updateCadence(cadence)
        }
        .onDisappear { viewModel.pause() }
    }

    private var readoutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(viewModel.channel.title, systemImage: "waveform.path.ecg")
                    .font(.headline)
                Spacer(minLength: 0)
                Text(settingsStore.settings.telemetryCadence.title)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(accent.color.opacity(0.18), in: Capsule())
                    .accessibilityIdentifier(A11y.Telemetry.cadenceLabel)
                    .accessibilityLabel("Update cadence")
                    .accessibilityValue(settingsStore.settings.telemetryCadence.title)
            }
            Text(currentValueText)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .accessibilityIdentifier(A11y.Telemetry.currentValue)
                .accessibilityLabel("Current \(viewModel.channel.title)")
                .accessibilityValue(currentValueText)
            Text("\(viewModel.samples.count) of \(TelemetryViewModel.historyLimit) samples retained")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .panelBackground()
    }

    private var currentValueText: String {
        guard let sample = viewModel.currentSample else { return "— \(viewModel.channel.unit)" }
        return String(format: "%.1f %@", sample.value, viewModel.channel.unit)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("History")
                .font(.headline)
            TelemetryChartView(samples: viewModel.samples, range: viewModel.channel.range, accent: accent)
                .frame(height: 180)
                .accessibilityIdentifier(A11y.Telemetry.chart)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Telemetry history chart")
                .accessibilityValue(chartAccessibilityValue)
        }
        .panelBackground()
    }

    private var chartAccessibilityValue: String {
        guard let last = viewModel.samples.last else { return "No samples yet" }
        let minimum = viewModel.samples.map(\.value).min() ?? last.value
        let maximum = viewModel.samples.map(\.value).max() ?? last.value
        return String(
            format: "%d samples, latest %.1f, minimum %.1f, maximum %.1f %@",
            viewModel.samples.count, last.value, minimum, maximum, viewModel.channel.unit
        )
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                if viewModel.isStreaming {
                    viewModel.pause()
                } else {
                    viewModel.start()
                }
                playHaptic()
            } label: {
                Label(viewModel.isStreaming ? "Pause" : "Start", systemImage: viewModel.isStreaming ? "pause.fill" : "play.fill")
                    .frame(maxWidth: .infinity, minHeight: Theme.minimumHitTarget - 12)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier(A11y.Telemetry.startPauseButton)
            .accessibilityLabel(viewModel.isStreaming ? "Pause telemetry" : "Start telemetry")

            Button {
                viewModel.clear()
                playHaptic()
            } label: {
                Label("Clear", systemImage: "trash")
                    .frame(maxWidth: .infinity, minHeight: Theme.minimumHitTarget - 12)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isEmpty)
            .accessibilityIdentifier(A11y.Telemetry.clearButton)
            .accessibilityLabel("Clear telemetry history")
        }
        .panelBackground()
    }

    private func playHaptic() {
        guard settingsStore.settings.hapticsEnabled else { return }
        haptics.play(.selection)
    }
}

#if DEBUG
struct TelemetryView_Previews: PreviewProvider {
    static var previews: some View {
        TelemetryView(source: SimulatedTelemetrySource(), cadence: .standard, haptics: SilentHaptics())
            .environmentObject(AppSettingsStore(store: InMemoryKeyValueStore()))
    }
}
#endif
