import SwiftUI

@MainActor class CubeLabVM: ObservableObject {
    @Published var rotationSpeed: Double = CubeSettings.defaultSpeed
    @Published var isRotating: Bool = true
    @Published var cameraOrientation: SIMD3<Double> = CubeSettings.defaultCameraOrientation
    private let cubeService = CubeLabService()
    init() { load() }
    func load() {
        let s = cubeService.loadSettings()
        rotationSpeed = s.rotationSpeed
        isRotating = s.isRotating
        cameraOrientation = s.cameraOrientation
    }
    func save() {
        try? cubeService.saveSettings(CubeSettings(rotationSpeed: rotationSpeed, isRotating: isRotating, cameraOrientation: cameraOrientation))
    }
    func reset() {
        rotationSpeed = CubeSettings.defaultSpeed
        isRotating = true
        cameraOrientation = CubeSettings.defaultCameraOrientation
        save()
    }
    func toggle() {
        isRotating.toggle()
        save()
    }
}

struct CubeLabView: View {
    @StateObject var vm = CubeLabVM()
    @Environment(\ .accessibilityReduceMotion) var reduceMotion
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                SceneKitCubeView(rotationSpeed: $vm.rotationSpeed, isRotating: $vm.isRotating, cameraOrientation: $vm.cameraOrientation, reduceMotion: reduceMotion)
                    .frame(height: 300)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))
                    .cornerRadius(20)
                    .accessibilityIdentifier("cube3DView")
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "speedometer").foregroundColor(.blue)
                            Text("Rotation Speed").font(.headline)
                            Spacer()
                            Text(String(format: "%.1f", vm.rotationSpeed)).font(.subheadline).monospacedDigit()
                        }
                        Slider(value: $vm.rotationSpeed, in: 0.1...2.0, step: 0.1, onEditingChanged: { _ in vm.save() })
                            .accessibilityIdentifier("rotationSpeedSlider")
                    }.padding().background(Color(.tertiarySystemBackground)).cornerRadius(12)
                    HStack(spacing: 20) {
                        Button(action: vm.toggle) { HStack(spacing: 8) { Image(systemName: vm.isRotating ? "pause.fill" : "play.fill").font(.title2); Text(vm.isRotating ? "Pause" : "Start").font(.headline) } .frame(maxWidth: .infinity) }
                            .buttonStyle(.borderedProminent).tint(.blue).accessibilityIdentifier("toggleRotationButton")
                    }.padding(.horizontal)
                }.background(Color(.secondarySystemBackground)).cornerRadius(16)
            }.padding()
            .navigationTitle("Cube Lab")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button(action: vm.reset) { Image(systemName: "arrow.clockwise") } .accessibilityIdentifier("resetCubeButton") } }
            .accessibilityIdentifier("cubeLabView")
            .onDisappear { vm.isRotating = false }
        }
    }
}
