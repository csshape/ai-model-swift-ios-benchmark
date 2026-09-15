import SwiftUI
import SceneKit

// MARK: - Cube Lab View

/// Displays an interactive 3D cube with controls
struct CubeLabView: View {
    @StateObject private var viewModel: CubeViewModel
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - State
    
    @State private var isPaused = false
    @State private var showResetConfirmation = false
    @State private var touchStartLocation: CGPoint? = nil
    @State private var previousTouchLocation: CGPoint? = nil
    
    // MARK: - Initialization
    
    init() {
        let storageService = UserDefaultsStorageService()
        // Create viewModel with settings manager's cube settings if available
        let viewModel = CubeViewModel(storageService: storageService)
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 3D Scene View
                sceneView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Controls Overlay
                controlsView
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .navigationTitle("Cube Lab")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.handleSceneActive(scenePhase == .active)
            }
            .onDisappear {
                viewModel.handleSceneActive(false)
            }
            .onChange(of: scenePhase) { newValue in
                viewModel.handleSceneActive(newValue == .active)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var sceneView: some View {
        ZStack {
            if let scene = viewModel.scene {
                SceneKitView(scene: scene, cubeViewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("3D Cube")
                    .accessibilityHint("Interactive 3D cube. Use touch to rotate.")
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onChanged { value in
                                handleDrag(value)
                            }
                    )
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
            }
        }
    }
    
    private var controlsView: some View {
        VStack(spacing: 16) {
            // Pause/Resume and Reset
            HStack(spacing: 16) {
                Button(action: togglePauseResume) {
                    HStack(spacing: 8) {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        Text(isPaused ? "Resume" : "Pause")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(settingsManager.accentColorValue)
                .accessibilityLabel(isPaused ? "Resume rotation" : "Pause rotation")
                
                Button(action: { showResetConfirmation = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Reset")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .accessibilityLabel("Reset cube")
            }
            
            // Speed Control
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "speedometer")
                    Text("Rotation Speed")
                    Text(String(format: "%.1f", viewModel.rotationSpeed))
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                }
                .font(.headline)
                
                Slider(
                    value: $viewModel.rotationSpeed,
                    in: 0.1...3.0,
                    step: 0.1
                )
                .tint(settingsManager.accentColorValue)
                .accessibilityValue("Speed: \(Int(viewModel.rotationSpeed * 10)) out of 30")
                .accessibilityLabel("Rotation speed")
            }
            
            // Auto-rotation Toggle
            Toggle("Auto Rotate", isOn: $viewModel.isAutoRotating)
                .toggleStyle(.switch)
                .tint(settingsManager.accentColorValue)
                .accessibilityLabel("Auto rotate")
                .accessibilityHint("Toggle automatic cube rotation")
            
            Spacer()
        }
        .padding(.top, 8)
        
        // Reset Confirmation
        .confirmationDialog(
            "Reset Cube",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset Cube", role: .destructive) {
                viewModel.reset()
            }
        } message: {
            Text("This will reset the cube to its initial orientation and speed.")
        }
    }
    
    // MARK: - Helper Methods
    
    private func togglePauseResume() {
        withAnimation {
            if isPaused {
                viewModel.startAutoRotation()
            } else {
                viewModel.stopAutoRotation()
            }
            isPaused.toggle()
        }
    }
    
    private func handleDrag(_ value: DragGesture.Value) {
        guard let start = touchStartLocation else {
            touchStartLocation = value.startLocation
            previousTouchLocation = value.startLocation
            return
        }
        
        let current = value.location
        let deltaX = Float(current.x - (previousTouchLocation?.x ?? start.x))
        let deltaY = Float(current.y - (previousTouchLocation?.y ?? start.y))
        
        // Invert Y axis since screen coordinates are inverted
        viewModel.applyTouchRotation(pitch: -deltaY * 0.01, yaw: -deltaX * 0.01)
        
        previousTouchLocation = current
    }
}

// MARK: - SceneKit View

/// A UIViewRepresentable wrapper for SCNView
struct SceneKitView: UIViewRepresentable {
    let scene: SCNScene
    let cubeViewModel: CubeViewModel
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = scene
        scnView.backgroundColor = .clear
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = true
        scnView.isPlaying = true
        
        // Configure for better 3D rendering
        scnView.antialiasingMode = .multisampling4X
        scnView.preferredFramesPerSecond = 60
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.scene = scene
        
        // Handle reduced motion
        if UIAccessibility.isReduceMotionEnabled {
            uiView.isPlaying = false
        } else {
            uiView.isPlaying = true
        }
    }
}

// MARK: - Preview

struct CubeLabView_Previews: PreviewProvider {
    static var previews: some View {
        CubeLabView()
            .environmentObject(PreviewSettingsManager())
    }
}
