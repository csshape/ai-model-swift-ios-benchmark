# OrbitLab

A production-like iOS app demonstrating modern Swift, SwiftUI, architecture, 3D graphics, structured concurrency, local persistence, and comprehensive testing.

## What the app demonstrates

- **Modern Swift**: Uses Swift 5.9+ features including `@MainActor`, `async/await`, `AsyncStream`, and structured concurrency
- **SwiftUI**: Full SwiftUI implementation with proper state management
- **Architecture**: MVVM pattern with dependency injection via protocols
- **3D Graphics**: Genuine interactive 3D cube using SceneKit integrated into SwiftUI
- **Asynchronous Services**: Production-ready async services with loading, error, and content states
- **Local Persistence**: UserDefaults-based storage with Codable support
- **Testing**: Comprehensive unit and UI testing infrastructure
- **Accessibility**: Full accessibility support with labels and identifiers

## Xcode and iOS requirements

- **Xcode**: 15.0 or later
- **iOS Deployment Target**: 15.0
- **Swift Version**: 5.9
- **Platform**: iOS (iPhone and iPad)

## App features

### Four Tabs

1. **Mission Control**: Visual dashboard with status header, metric cards, recent mission events, pull-to-refresh, and error handling with retry
2. **Cube Lab**: Interactive 3D cube with automatic rotation, pause/resume, speed control, reset, camera control via touch, persistence, and reduce motion support
3. **Telemetry**: Live deterministic telemetry stream with current value display, history graph (20+ points), start/pause/clear controls, and proper cancellation
4. **Settings**: Accent color selection (4+ options), haptic feedback toggle, reduced telemetry frequency toggle, reset all settings with confirmation

## Architecture

### Pattern: MVVM + Services

```
Views (SwiftUI)
    ↓ (ObservableObject)
ViewModels (@MainActor)
    ↓ (Protocol-based DI)
Services (Business Logic)
    ↓ (Storage, Network, etc.)
Models (Codable, Domain Types)
```

### Key architectural choices:

1. **Separation of Concerns**: Views handle UI only, ViewModels handle state, Services handle business logic
2. **Dependency Injection**: All services are protocol-based with mock implementations for testing
3. **State Isolation**: UI state is isolated to `@MainActor`, long-running work happens off-main-thread
4. **Error Handling**: Structured error types with user-friendly messages and retry capability
5. **Testability**: All dependencies are injectable, enabling comprehensive unit testing

### Tradeoffs:

- **MVVM**: Slightly more boilerplate but excellent for testability
- **Protocol-oriented DI**: More code but enables mocking for tests
- **@MainActor on ViewModels**: Ensures UI safety but requires careful async handling

## How the app is built

### Using xcodebuild (Command Line)

```bash
cd OrbitLab
xcodebuild -scheme OrbitLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### Using Xcode

1. Open `OrbitLab.xcodeproj` in Xcode
2. Select the `OrbitLab` scheme
3. Choose a simulator (iPhone 17 Pro)
4. Press Cmd+R

### Project Generation

Generated using xcodegen from `project.yml` specification.

## How all tests are run

```bash
xcodebuild test -scheme OrbitLab -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**Note**: Test targets currently require manual PBXproj editing for proper execution.

## Testing

### Unit Tests
- Mission Control: loading, error, retry
- Cube Lab: start/pause, speed change, reset, persistence
- Telemetry: start, receiving values, pause, cancellation, history capping
- Settings: load, change, full reset
- Edge cases: empty graph

### UI Tests
- App launches with four tabs
- Cube Lab navigation and interaction
- Settings changes observable in UI
- Accessibility elements found via identifiers

## Known limitations

1. Test bundle configuration requires manual PBXproj editing
2. xcodegen has limitations with test target types

## Architecture details

### Models
- AppSettings, CubeSettings, MissionEvent, TelemetryPoint - all Codable and Equatable

### Services (Protocol-based with mocks)
- MissionControlServiceProtocol, CubeLabServiceProtocol, TelemetryServiceProtocol, SettingsServiceProtocol, StorageServiceProtocol

### ViewModels (@MainActor, ObservableObject)
- MissionControlVM, CubeLabVM, TelemetryVM, SettingsVM

### Views (SwiftUI)
- MainTabView, MissionControlView, SceneKitCubeView, CubeLabView, TelemetryView, TelemetryGraphView, SettingsView, MetricCardView
