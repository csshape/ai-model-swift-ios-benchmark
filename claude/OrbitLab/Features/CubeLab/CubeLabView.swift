import SwiftUI

struct CubeLabView: View {
    @ObservedObject var viewModel: CubeLabViewModel
    @EnvironmentObject private var settingsStore: AppSettingsStore
    @StateObject private var controller = CubeSceneController()

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let haptics: HapticsProviding

    private var accent: AccentChoice { settingsStore.settings.accent }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background(for: accent)
                ScrollView {
                    VStack(spacing: 20) {
                        sceneCard
                        controls
                        if viewModel.prefersReducedMotion {
                            reduceMotionCard
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Cube Lab")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
        .accessibilityIdentifier(A11y.CubeLab.root)
        .onAppear {
            viewModel.setReducedMotion(reduceMotion)
            syncScene()
        }
        .onChange(of: reduceMotion) { newValue in
            viewModel.setReducedMotion(newValue)
            syncScene()
        }
        .onChange(of: viewModel.shouldAnimate) { _ in syncScene() }
        .onChange(of: viewModel.speed) { _ in syncScene() }
        .onChange(of: scenePhase) { phase in
            let isActive = phase == .active
            viewModel.setSceneActive(isActive)
            controller.setRenderingSuspended(!isActive)
            syncScene()
        }
    }

    private var sceneCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Orbiter hull", systemImage: "cube.transparent")
                    .font(.headline)
                Spacer(minLength: 0)
                Text(viewModel.statusDescription)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(accent.color.opacity(0.18), in: Capsule())
                    .accessibilityIdentifier(A11y.CubeLab.statusLabel)
                    .accessibilityLabel("Cube status")
                    .accessibilityValue(viewModel.statusDescription)
            }
            CubeSceneView(controller: controller)
                .frame(minHeight: 260, idealHeight: 320, maxHeight: 360)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            Text("Drag the cube to look around. Each of the six faces is a different subsystem.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .panelBackground()
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Button {
                    viewModel.togglePlayback()
                    playHaptic()
                } label: {
                    Label(viewModel.playbackButtonTitle, systemImage: viewModel.isRotating ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity, minHeight: Theme.minimumHitTarget - 12)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier(A11y.CubeLab.playPauseButton)
                .accessibilityLabel(viewModel.isRotating ? "Pause rotation" : "Start rotation")

                Button {
                    viewModel.reset()
                    controller.reset()
                    syncScene()
                    playHaptic()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity, minHeight: Theme.minimumHitTarget - 12)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier(A11y.CubeLab.resetButton)
                .accessibilityLabel("Reset orientation and speed")
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Rotation speed")
                        .font(.subheadline)
                    Spacer(minLength: 0)
                    Text(String(format: "%.1f×", viewModel.speed))
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                }
                Slider(
                    value: Binding(
                        get: { viewModel.speed },
                        set: { viewModel.setSpeed($0) }
                    ),
                    in: CubeSettings.speedRange,
                    step: 0.1
                )
                .tint(accent.color)
                .accessibilityIdentifier(A11y.CubeLab.speedSlider)
                .accessibilityLabel("Rotation speed")
                .accessibilityValue(String(format: "%.1f times", viewModel.speed))
            }
        }
        .panelBackground()
    }

    private var reduceMotionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Reduce Motion is on", systemImage: "figure.walk.motion")
                .font(.headline)
            Text("Continuous rotation is disabled. Step the cube a quarter turn at a time instead, or drag it directly.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                controller.stepQuarterTurn()
                playHaptic()
            } label: {
                Label("Step a quarter turn", systemImage: "rotate.right")
                    .frame(maxWidth: .infinity, minHeight: Theme.minimumHitTarget - 12)
            }
            .buttonStyle(.bordered)
        }
        .panelBackground()
    }

    private func syncScene() {
        controller.apply(isAnimating: viewModel.shouldAnimate, speed: viewModel.speed)
    }

    private func playHaptic() {
        guard settingsStore.settings.hapticsEnabled else { return }
        haptics.play(.selection)
    }
}

#if DEBUG
struct CubeLabView_Previews: PreviewProvider {
    static var previews: some View {
        CubeLabView(
            viewModel: CubeLabViewModel(store: InMemoryKeyValueStore()),
            haptics: SilentHaptics()
        )
        .environmentObject(AppSettingsStore(store: InMemoryKeyValueStore()))
    }
}
#endif
