import SwiftUI

struct CubeLabView: View {
    @ObservedObject private var settingsModel: AppSettingsViewModel
    @StateObject private var viewModel: CubeLabViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    init(settingsModel: AppSettingsViewModel) {
        self.settingsModel = settingsModel
        _viewModel = StateObject(
            wrappedValue: CubeLabViewModel(settings: settingsModel.settings.cube) { cubeSettings in
                settingsModel.updateCubeSettings(cubeSettings)
            }
        )
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    CubeSceneView(configuration: viewModel.rotationConfiguration)
                        .frame(minHeight: 320)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .accessibilityLabel("Interactive 3D mission cube")
                        .accessibilityIdentifier("cube.scene")

                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Button {
                                viewModel.toggleRotation()
                            } label: {
                                Label(viewModel.rotationButtonTitle, systemImage: viewModel.settings.isRotating ? "pause.fill" : "play.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .accessibilityIdentifier("cube.rotation.toggle")

                            Button {
                                viewModel.reset()
                            } label: {
                                Label("Reset", systemImage: "arrow.counterclockwise")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .accessibilityIdentifier("cube.reset.button")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Rotation Speed", systemImage: "speedometer")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(viewModel.settings.rotationSpeed.formatted(.number.precision(.fractionLength(1))) + "x")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundColor(.secondary)
                            }

                            Slider(
                                value: Binding(
                                    get: { viewModel.settings.rotationSpeed },
                                    set: { viewModel.updateSpeed($0) }
                                ),
                                in: CubeSettings.allowedSpeedRange
                            )
                            .accessibilityIdentifier("cube.speed.slider")
                        }

                        if reduceMotion {
                            HStack(spacing: 10) {
                                Image(systemName: "figure.roll")
                                    .foregroundColor(.secondary)
                                Text("Reduce Motion is active. Automatic rotation is replaced by manual nudges.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 8)
                                Button {
                                    viewModel.nudge()
                                } label: {
                                    Label("Nudge", systemImage: "rotate.3d")
                                }
                                .buttonStyle(.bordered)
                                .accessibilityIdentifier("cube.nudge.button")
                            }
                        }
                    }
                    .orbitCard()
                }
                .padding()
            }
            .screenBackground()
            .navigationTitle("Cube Lab")
        }
        .navigationViewStyle(.stack)
        .onAppear {
            viewModel.setVisible(true)
            viewModel.setReduceMotionEnabled(reduceMotion)
            viewModel.setSceneActive(scenePhase == .active)
            viewModel.applyExternalSettings(settingsModel.settings.cube)
        }
        .onDisappear {
            viewModel.setVisible(false)
        }
        .onChange(of: scenePhase) { newPhase in
            viewModel.setSceneActive(newPhase == .active)
        }
        .onChange(of: reduceMotion) { newValue in
            viewModel.setReduceMotionEnabled(newValue)
        }
        .onChange(of: settingsModel.settings.cube) { cubeSettings in
            viewModel.applyExternalSettings(cubeSettings)
        }
    }
}

#if DEBUG
struct CubeLabView_Previews: PreviewProvider {
    static var previews: some View {
        CubeLabView(settingsModel: AppSettingsViewModel(store: PreviewSettingsStore()))
    }
}
#endif
