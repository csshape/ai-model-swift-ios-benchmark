import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settingsStore: AppSettingsStore
    @State private var isConfirmingReset = false

    let haptics: HapticsProviding
    let resetAll: () -> Void

    private var accent: AccentChoice { settingsStore.settings.accent }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background(for: accent)
                ScrollView {
                    VStack(spacing: 20) {
                        appearanceCard
                        behaviourCard
                        resetCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(TabTitle.settings)
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(.stack)
        .accessibilityIdentifier(A11y.Settings.root)
    }

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Appearance", systemImage: "paintpalette")
                .font(.headline)
            Picker("Accent colour", selection: accentBinding) {
                ForEach(AccentChoice.allCases) { choice in
                    Text(choice.title).tag(choice)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier(A11y.Settings.accentPicker)
            .accessibilityLabel("Accent colour")

            Text(settingsStore.settings.summary)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(A11y.Settings.summary)
                .accessibilityLabel("Current settings")
                .accessibilityValue(settingsStore.settings.summary)
        }
        .panelBackground()
    }

    private var behaviourCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Behaviour", systemImage: "slider.horizontal.3")
                .font(.headline)
            Toggle(isOn: hapticsBinding) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Haptic feedback")
                    Text("Play a tap when controls change.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityIdentifier(A11y.Settings.hapticsToggle)

            Divider()

            Toggle(isOn: cadenceBinding) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reduced telemetry rate")
                    Text("Update the telemetry stream once per second instead of four times.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityIdentifier(A11y.Settings.reducedCadenceToggle)
        }
        .tint(accent.color)
        .panelBackground()
    }

    private var resetCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Reset", systemImage: "arrow.uturn.backward")
                .font(.headline)
            Text("Restores the accent colour, haptics, telemetry cadence and the Cube Lab defaults.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(role: .destructive) {
                isConfirmingReset = true
            } label: {
                Label("Reset all settings", systemImage: "trash")
                    .frame(maxWidth: .infinity, minHeight: Theme.minimumHitTarget - 12)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .accessibilityIdentifier(A11y.Settings.resetButton)
        }
        .panelBackground()
        .confirmationDialog(
            "Reset all settings?",
            isPresented: $isConfirmingReset,
            titleVisibility: .visible
        ) {
            Button("Reset everything", role: .destructive) {
                resetAll()
                play()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    private var accentBinding: Binding<AccentChoice> {
        Binding(
            get: { settingsStore.settings.accent },
            set: { newValue in
                settingsStore.settings.accent = newValue
                play()
            }
        )
    }

    private var hapticsBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.settings.hapticsEnabled },
            set: { newValue in
                settingsStore.settings.hapticsEnabled = newValue
                if newValue { haptics.play(.impact) }
            }
        )
    }

    private var cadenceBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.settings.usesReducedTelemetryCadence },
            set: { newValue in
                settingsStore.settings.usesReducedTelemetryCadence = newValue
                play()
            }
        )
    }

    private func play() {
        guard settingsStore.settings.hapticsEnabled else { return }
        haptics.play(.selection)
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(haptics: SilentHaptics(), resetAll: {})
            .environmentObject(AppSettingsStore(store: InMemoryKeyValueStore()))
    }
}
#endif
