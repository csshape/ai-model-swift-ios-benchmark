import SwiftUI

// MARK: - Settings View

/// Displays and manages app settings
struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    
    // MARK: - State
    
    @State private var showResetConfirmation = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // Appearance Section
                Section(header: Text("Appearance")) {
                    Picker("Accent Color", selection: $settingsManager.accentColor) {
                        ForEach(AccentColorOption.allCases) { option in
                            Text(option.displayName)
                                .tag(option)
                        }
                    }
                    .accessibilityLabel("Accent color")
                    .accessibilityHint("Choose the app's accent color")
                }
                
                // Feedback Section
                Section(header: Text("Feedback")) {
                    Toggle("Haptic Feedback", isOn: $settingsManager.hapticFeedbackEnabled)
                        .accessibilityLabel("Haptic feedback")
                        .accessibilityHint("Toggle haptic feedback on/off")
                }
                
                // Telemetry Section
                Section(header: Text("Telemetry")) {
                    Toggle("Reduced Frequency", isOn: $settingsManager.reducedTelemetryFrequency)
                        .accessibilityLabel("Reduced telemetry frequency")
                        .accessibilityHint("Use reduced update frequency for telemetry")
                }
                
                // Cube Settings Section
                Section(header: Text("Cube Settings")) {
                    Stepper(
                        "Rotation Speed: \(String(format: "%.1f", settingsManager.cubeRotationSpeed))",
                        value: Binding(
                            get: { settingsManager.cubeRotationSpeed },
                            set: { newValue in settingsManager.cubeRotationSpeed = newValue }
                        ),
                        in: 0.1...3.0,
                        step: 0.1
                    )
                    .accessibilityLabel("Cube rotation speed")
                    .accessibilityHint("Adjust cube rotation speed from 0.1 to 3.0")
                    
                    Toggle("Auto Rotate Cube", isOn: $settingsManager.cubeIsAutoRotating)
                        .accessibilityLabel("Auto rotate cube")
                        .accessibilityHint("Toggle automatic cube rotation")
                }
                
                // Reset Section
                Section {
                    Button(action: { showResetConfirmation = true }) {
                        HStack {
                            Spacer()
                            Text("Reset All Settings")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                    .accessibilityLabel("Reset all settings")
                    .accessibilityHint("Restore all settings to default values")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            
            // Reset Confirmation
            .confirmationDialog(
                "Reset All Settings",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset All", role: .destructive) {
                    settingsManager.resetAllSettings()
                }
            } message: {
                Text("This will restore all settings to their default values. This action cannot be undone.")
            }
        }
    }
}

// MARK: - Color Picker View

struct ColorPickerView: View {
    @Binding var selectedColor: AccentColorOption
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(AccentColorOption.allCases) { option in
                Button(action: { selectedColor = option }) {
                    Circle()
                        .frame(width: 44, height: 44)
                        .foregroundColor(option.color)
                        .overlay(
                            Circle()
                                .stroke(lineWidth: 3)
                                .foregroundColor(selectedColor == option ? .primary : .clear)
                        )
                }
                .accessibilityLabel(option.displayName)
                .accessibilityHint("Select \(option.displayName) color")
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(PreviewSettingsManager())
    }
}
