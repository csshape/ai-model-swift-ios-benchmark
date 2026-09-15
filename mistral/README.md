# OrbitLab - iOS Benchmark App

## Overview

OrbitLab is a production-like iOS application demonstrating modern Swift and SwiftUI development, architecture patterns, 3D graphics with SceneKit, structured concurrency, local persistence, comprehensive testing, accessibility support, and robust error handling.

The app features four main tabs:
- **Mission Control**: Dashboard displaying mission status, metrics, and recent events
- **Cube Lab**: Interactive 3D cube with rotation controls and touch interaction
- **Telemetry**: Live data stream visualization with custom graph rendering
- **Settings**: App configuration with persistent storage

## Requirements

- **Xcode**: 26.6 or later
- **iOS Deployment Target**: iOS 15.0+
- **Swift**: 5.10+
- **Dependencies**: None (uses only Apple frameworks)

## Building

The project uses **xcodegen** for project generation. To build:

```bash
# Generate Xcode project
xcodegen generate

# Build for iOS Simulator
xcodebuild -project OrbitLab.xcodeproj -scheme OrbitLab \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro"
```

## Running Tests

### Unit Tests

```bash
xcodebuild test -project OrbitLab.xcodeproj -scheme OrbitLab \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro"
```

### UI Tests

UI tests require a booted simulator. Boot the simulator first:

```bash
xcrun simctl boot "iPhone 17 Pro"
```

Then run tests:

```bash
xcodebuild test -project OrbitLab.xcodeproj -scheme OrbitLab \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro"
```

## Architecture

### Design Pattern

The app uses a **MVVM (Model-View-ViewModel)** pattern with **dependency injection**:

- **Models**: Codable structs representing data (MissionDashboard, TelemetryDataPoint, CubeConfig, etc.)
- **Services**: Protocol-based abstractions for business logic (MissionServiceProtocol, TelemetryServiceProtocol, StorageServiceProtocol)
- **ViewModels**: ObservableObjects managing view state and business logic
- **Views**: SwiftUI views that observe ViewModels and display data

### Key Architectural Decisions

1. **Protocol-Oriented Services**: All services implement protocols, allowing easy mocking for testing and future implementation changes (e.g., swapping local data for network services)

2. **Dependency Injection**: Services are injected into ViewModels, making the app testable and flexible

3. **Unidirectional Data Flow**: Views observe ViewModels, which coordinate with Services. No direct service access from views

4. **Error Handling**: Custom error types with LocalizedError conformance for user-friendly error messages

5. **Persistence**: Abstracted storage layer (StorageServiceProtocol) with UserDefaults implementation

6. **State Management**: ViewModels use @Published properties and explicit state enums for predictable UI updates

## Project Structure

```
OrbitLab/
├── Sources/
│   ├── OrbitLabApp.swift           # App entry point
│   ├── Resources/
│   │   └── Info.plist             # App configuration
│   ├── Models/
│   │   ├── MissionModels.swift     # Mission status, metrics, events
│   │   ├── TelemetryModels.swift   # Telemetry data points
│   │   ├── CubeModels.swift        # Cube face configuration
│   │   └── SettingsModels.swift    # App and cube settings
│   ├── Services/
│   │   ├── MissionService.swift    # Mission data service
│   │   ├── TelemetryService.swift  # Telemetry streaming service
│   │   └── StorageService.swift    # Persistence layer
│   ├── ViewModels/
│   │   ├── MissionControlViewModel.swift
│   │   ├── CubeViewModel.swift
│   │   ├── TelemetryViewModel.swift
│   │   └── SettingsManager.swift
│   └── Views/
│       ├── MainTabView.swift
│       ├── MissionControlView.swift
│       ├── CubeLabView.swift
│       ├── TelemetryView.swift
│       └── SettingsView.swift
├── Tests/
│   ├── UnitTests/
│   │   ├── MissionControlTests.swift
│   │   ├── CubeLabTests.swift
│   │   ├── TelemetryTests.swift
│   │   ├── SettingsTests.swift
│   │   └── EdgeCaseTests.swift
│   └── UITests/
│       └── OrbitLabUITests.swift
├── project.yml                    # xcodegen configuration
├── README.md                      # This file
└── BENCHMARK_REPORT.md            # Benchmark results
```

## Key Features

### Mission Control
- Status header with clear visual indicators
- Reusable metric cards with trend indicators
- List of recent mission events with severity coloring
- Loading, content, and error states with pull-to-refresh
- Asynchronous data loading from configurable service

### Cube Lab
- Genuine 3D cube using SceneKit integrated in SwiftUI
- Automatic smooth rotation with configurable speed
- Pause/resume functionality
- Touch-based rotation (drag to rotate)
- Reset button to restore initial state
- Settings persistence across app launches
- Reduced motion support
- Proper app lifecycle handling

### Telemetry
- Async stream producing data points
- Custom line graph without third-party libraries
- Display of current value and 50 historical values
- Start, pause, and clear functionality
- Proper task cancellation when stopped
- No uncontrolled timers (uses async Task with sleep)

### Settings
- Accent color selection from 4 options
- Haptic feedback toggle
- Reduced telemetry frequency toggle
- Reset all settings with confirmation dialog
- Immediate UI updates when settings change

## Accessibility & UX

- All tabs have SF Symbols and accessibility labels/hints
- Dynamic Type support throughout
- Reduced motion support (disables cube animation)
- Proper hit areas for interactive elements
- Native components and materials

## Known Limitations

1. **UI Tests**: Currently limited due to simulator runner issues in the test environment. Tests compile but may require manual simulator setup to run properly

2. **Cube 3D Rendering**: The SceneKit view uses a basic setup. More advanced lighting and shadows could be added

3. **Telemetry Graph**: Simple line graph implementation. Could be enhanced with more features like zoom, pan, or value highlighting

4. **Localization**: Currently English only. The architecture supports localization but no translations are provided

## Testing Strategy

### Unit Tests
- Mission Control: Loading states, error handling, retry
- Cube Lab: Start/pause, speed change, reset, persistence
- Telemetry: Stream control, history capping, clear
- Settings: Load, change, reset, persistence
- Edge Cases: Empty data, unknown errors, Codable edge cases

### UI Tests
- App launches with four tabs
- Navigation to Cube Lab and pause/resume
- Settings changes visible in UI
- Accessibility elements can be found

## Future Improvements

- Add network service implementation for Mission Control
- Enhance telemetry with real sensor data
- Add more cube interaction modes (pinch to zoom, etc.)
- Implement haptic feedback
- Add more comprehensive logging
- Expand test coverage
- Add CI/CD pipeline
