import SwiftUI

@MainActor class TelemetryVM: ObservableObject {
    @Published var history: [TelemetryPoint] = []
    @Published var currentValue: Double = 0
    @Published var isStreaming: Bool = false
    @Published var showClearDialog = false
    private let telemetryService = TelemetryService()
    private let settingsService = SettingsService()
    private var streamTask: Task<Void, Error>?
    private var settings: AppSettings = .init()
    let maxHistory = 20

    init() {
        settings = settingsService.loadSettings()
        settingsService.addObserver(self)
    }
    deinit { streamTask?.cancel() }

    func start() {
        guard !isStreaming else { return }
        isStreaming = true
        history.removeAll()
        currentValue = 0
        let interval = settings.reducedTelemetryFrequency ? 1.0 : 0.5
        streamTask = Task {
            for await point in telemetryService.startStreaming(interval: interval, maxHistory: maxHistory) {
                await MainActor.run {
                    currentValue = point.value
                    history.append(point)
                    if history.count > maxHistory { history.removeFirst() }
                }
            }
        }
    }
    func pause() {
        isStreaming = false
        streamTask?.cancel()
        streamTask = nil
    }
    func clear() {
        showClearDialog = false
        pause()
        history.removeAll()
        currentValue = 0
    }
    func toggle() {
        if isStreaming { pause() } else { start() }
    }
}

extension TelemetryVM: SettingsObserver {
    nonisolated func settingsDidChange(_ s: AppSettings) {
        Task { @MainActor in settings = s }
    }
}

struct TelemetryView: View {
    @StateObject var vm = TelemetryVM()
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Current Velocity").font(.subheadline).foregroundColor(.secondary)
                    HStack(alignment: .bottom, spacing: 4) {
                        Text(String(format: "%.2f", vm.currentValue)).font(.system(size: 48)).fontWeight(.bold)
                        Text("km/s").font(.title3).foregroundColor(.secondary)
                    }
                }.padding().frame(maxWidth: .infinity).background(Color(.secondarySystemBackground)).cornerRadius(16).accessibilityIdentifier("currentValue")
                VStack(alignment: .leading, spacing: 8) {
                    Text("Velocity History").font(.headline)
                    if vm.history.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.bar.xaxis").font(.system(size: 40)).foregroundColor(.secondary)
                            Text("No data available").font(.subheadline).foregroundColor(.secondary)
                            Text("Start streaming to see data").font(.caption).foregroundColor(.secondary)
                        }.frame(maxWidth: .infinity).frame(height: 200).background(Color(.tertiarySystemBackground)).cornerRadius(12)
                    } else {
                        TelemetryGraphView(points: vm.history, maxVisible: vm.maxHistory)
                    }
                    Text("Showing \(vm.history.count) of \(vm.maxHistory) points").font(.caption).foregroundColor(.secondary)
                }
                HStack(spacing: 16) {
                    Button(action: vm.toggle) { HStack(spacing: 8) { Image(systemName: vm.isStreaming ? "pause.fill" : "play.fill").font(.title2); Text(vm.isStreaming ? "Pause" : "Start").font(.headline) } .frame(maxWidth: .infinity) }
                        .buttonStyle(.borderedProminent).tint(vm.isStreaming ? .red : .blue).accessibilityIdentifier("streamToggleButton")
                    Button(action: { vm.showClearDialog = true }) { HStack(spacing: 8) { Image(systemName: "trash").font(.title2); Text("Clear").font(.headline) } .frame(maxWidth: .infinity) }
                        .buttonStyle(.bordered).tint(.red).disabled(vm.history.isEmpty).accessibilityIdentifier("clearDataButton")
                }.controlSize(.large)
            }.padding().navigationTitle("Telemetry").accessibilityIdentifier("telemetryView")
                .alert("Clear Data?", isPresented: $vm.showClearDialog) {
                    Button("Cancel", role: .cancel) { }
                    Button("Clear", role: .destructive) { vm.clear() }
                } message: { Text("This will remove all telemetry history") }
        }
    }
}
