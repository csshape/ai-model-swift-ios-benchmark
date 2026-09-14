import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: AppSettingsViewModel
    let haptics: HapticPerforming

    @State private var showsResetConfirmation = false

    var body: some View {
        NavigationView {
            Form {
                Section("Accent Color") {
                    HStack(spacing: 14) {
                        ForEach(AccentColorOption.allCases) { option in
                            AccentSwatchButton(
                                option: option,
                                isSelected: viewModel.settings.accentColor == option,
                                action: {
                                    performConfiguredHaptic()
                                    viewModel.updateAccentColor(option)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 4)

                    Text("Selected Accent: \(viewModel.settings.accentColor.displayName)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .accessibilityIdentifier("settings.accent.status")
                }

                Section("Telemetry") {
                    Toggle(
                        isOn: Binding(
                            get: { viewModel.settings.reducedTelemetryFrequency },
                            set: { newValue in
                                performConfiguredHaptic()
                                viewModel.updateReducedTelemetryFrequency(newValue)
                            }
                        )
                    ) {
                        Label("Reduced Update Frequency", systemImage: "speedometer")
                    }
                    .accessibilityIdentifier("settings.reducedTelemetry.toggle")
                }

                Section("Feedback") {
                    Toggle(
                        isOn: Binding(
                            get: { viewModel.settings.hapticFeedbackEnabled },
                            set: { newValue in
                                if viewModel.settings.hapticFeedbackEnabled {
                                    haptics.selectionChanged()
                                }
                                viewModel.updateHapticFeedback(newValue)
                            }
                        )
                    ) {
                        Label("Haptic Feedback", systemImage: "hand.tap")
                    }
                    .accessibilityIdentifier("settings.haptics.toggle")

                    Text(viewModel.settings.hapticFeedbackEnabled ? "Haptics Enabled" : "Haptics Disabled")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .accessibilityIdentifier("settings.haptics.status")
                }

                Section {
                    Button(role: .destructive) {
                        showsResetConfirmation = true
                    } label: {
                        Label("Reset Settings", systemImage: "arrow.counterclockwise")
                    }
                    .accessibilityIdentifier("settings.reset.button")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Reset all OrbitLab settings?", isPresented: $showsResetConfirmation) {
                Button("Reset Settings", role: .destructive) {
                    performConfiguredHaptic()
                    viewModel.resetAllSettings()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .navigationViewStyle(.stack)
    }

    private func performConfiguredHaptic() {
        if viewModel.settings.hapticFeedbackEnabled {
            haptics.selectionChanged()
        }
    }
}

private struct AccentSwatchButton: View {
    let option: AccentColorOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(option.color)
                        .frame(width: 34, height: 34)
                    Image(systemName: isSelected ? "checkmark" : "circle")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                }
                Text(option.displayName)
                    .font(.caption2)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.displayName)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityIdentifier("settings.accent.\(option.rawValue)")
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: AppSettingsViewModel(store: PreviewSettingsStore()), haptics: NoOpHapticPerformer())
    }
}
#endif
