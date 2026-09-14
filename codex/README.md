# OrbitLab-Codex

OrbitLab-Codex is a small production-style SwiftUI iOS app that demonstrates local async data loading, SceneKit integration, deterministic telemetry streaming, persistent settings, accessibility identifiers, and automated unit/UI testing.

## Requirements

- Xcode 26.6 was used for validation.
- Swift 5 mode with modern concurrency.
- Minimum deployment target: iOS 15.0.
- No third-party dependencies.

## Build

Use an available iOS Simulator destination. The validated simulator was `iPhone 17 Pro` on iOS 26.5:

```sh
xcodebuild build \
  -project OrbitLab.xcodeproj \
  -scheme OrbitLab \
  -destination 'id=249AE3D9-13E6-49F4-9F44-6DCEE4E2AD00' \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO
```

## Test

Run unit tests:

```sh
xcodebuild test \
  -project OrbitLab.xcodeproj \
  -scheme OrbitLab \
  -destination 'id=249AE3D9-13E6-49F4-9F44-6DCEE4E2AD00' \
  -derivedDataPath build/DerivedData \
  -only-testing:OrbitLabTests \
  CODE_SIGNING_ALLOWED=NO
```

Run UI tests:

```sh
xcodebuild test \
  -project OrbitLab.xcodeproj \
  -scheme OrbitLab \
  -destination 'id=249AE3D9-13E6-49F4-9F44-6DCEE4E2AD00' \
  -derivedDataPath build/DerivedData \
  -only-testing:OrbitLabUITests \
  CODE_SIGNING_ALLOWED=NO
```

## What The App Demonstrates

- Mission Control loads deterministic local sample data through an async service abstraction and presents loading, content, error, retry, and pull-to-refresh states.
- Cube Lab embeds a real SceneKit cube in SwiftUI, supports auto-rotation, camera/touch interaction, speed changes, reset, lifecycle pausing, persisted settings, and a Reduce Motion alternative.
- Telemetry consumes an async stream, shows the current value, keeps the latest 20 values, and draws a custom Canvas graph without Swift Charts.
- Settings persists accent color, haptics, telemetry frequency, and cube state through an abstracted storage interface.

## Architecture

The app uses a compact MVVM structure with feature-specific view models and protocol-based services. Shared state is held in `AppSettingsViewModel`, while Mission Control, Cube Lab, and Telemetry own their own screen logic. UI-facing state is isolated to the main actor; async services and stream production stay outside the view layer.

The SceneKit setup is separated into `CubeSceneController`, keeping SceneKit node mutation out of the SwiftUI view model. Tests focus on state transitions and cancellation behavior rather than rendering internals.

## Tradeoffs

- Local deterministic data is used instead of networking to keep the app and tests offline and repeatable.
- The target and scheme remain named `OrbitLab` for simple command-line builds, while the app display name is `OrbitLab-Codex`.
- SwiftUI previews are included for Mission Control, Cube Lab, Telemetry, and Settings under `#if DEBUG`.

## Known Limitations

- SceneKit rendering is validated through build and UI navigation tests, not through pixel-level snapshot tests.
- Telemetry values are synthetic by design and do not represent real spacecraft measurements.
