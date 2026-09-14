import SwiftUI

@MainActor class SettingsVM: ObservableObject {
    @Published var accentColor: AppSettings.ColorRepresentation = .systemBlue
    @Published var hapticFeedbackEnabled: Bool = true
    @Published var reducedTelemetryFrequency: Bool = false
    @Published var showResetConfirm = false
    private let settingsService = SettingsService()
    private var current: AppSettings = .init()
    init() {
        current = settingsService.loadSettings()
        accentColor = current.accentColor
        hapticFeedbackEnabled = current.hapticFeedbackEnabled
        reducedTelemetryFrequency = current.reducedTelemetryFrequency
    }
    func save() {
        current = AppSettings(accentColor: accentColor, hapticFeedbackEnabled: hapticFeedbackEnabled, reducedTelemetryFrequency: reducedTelemetryFrequency)
        try? settingsService.saveSettings(current)
    }
    func reset() {
        current = .init()
        accentColor = .systemBlue
        hapticFeedbackEnabled = true
        reducedTelemetryFrequency = false
        try? settingsService.saveSettings(current)
    }
    var colorOptions: [AppSettings.ColorRepresentation] { AppSettings.ColorRepresentation.allCases }
}

struct SettingsView: View {
    @StateObject var vm = SettingsVM()
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance").font(.headline)) {
                    Picker("Accent Color", selection: $vm.accentColor) {
                        ForEach(vm.colorOptions, id: \.self) { c in
                            Text(c.rawValue.replacingOccurrences(of: "system", with: "").capitalized).tag(c)
                        }
                    }.pickerStyle(.segmented).onChange(of: vm.accentColor) { _ in vm.save() }.accessibilityIdentifier("accentColorPicker")
                    HStack { Text("Preview"); Spacer(); Circle().fill(vm.accentColor.color).frame(width: 30, height: 30).overlay(Circle().stroke(Color.primary, lineWidth: 2)) }
                }
                Section(header: Text("Feedback").font(.headline)) {
                    Toggle("Haptic Feedback", isOn: $vm.hapticFeedbackEnabled).onChange(of: vm.hapticFeedbackEnabled) { _ in vm.save() }.accessibilityIdentifier("hapticFeedbackToggle")
                    Text("Enable haptic feedback for interactions").font(.caption).foregroundColor(.secondary)
                }
                Section(header: Text("Telemetry").font(.headline)) {
                    Toggle("Reduce Update Frequency", isOn: $vm.reducedTelemetryFrequency).onChange(of: vm.reducedTelemetryFrequency) { _ in vm.save() }.accessibilityIdentifier("reduceTelemetryToggle")
                    Text("Reduce telemetry update frequency").font(.caption).foregroundColor(.secondary)
                }
                Section {
                    Button(action: { vm.showResetConfirm = true }) { HStack { Spacer(); Text("Reset All Settings").foregroundColor(.red); Spacer() } }
                        .accessibilityIdentifier("resetSettingsButton")
                }
            }.navigationTitle("Settings").accessibilityIdentifier("settingsView")
                .confirmationDialog("Reset All Settings", isPresented: $vm.showResetConfirm) {
                    Button("Reset All Settings", role: .destructive) { vm.reset() }
                } message: { Text("This will reset all settings to default") }
        }
    }
}
