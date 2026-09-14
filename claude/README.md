# OrbitLab

A small but production-shaped iOS app built to exercise modern Swift and SwiftUI end to end:
async services with real loading/content/error states, an interactive SceneKit cube, a
cancellable telemetry stream with a hand-drawn chart, and persisted settings — all behind
protocols that can be replaced in tests.

The app installs on the home screen as **OrbitLab-Claude**. The Xcode project, scheme and
Swift module are named `OrbitLab` (a hyphen is not a legal Swift module name).

## What it demonstrates

| Tab | What it shows |
|---|---|
| **Mission Control** | An `async` service behind a protocol, `LoadState` driven idle → loading → content/error UI, pull to refresh, retry after failure, reusable metric cards and an event log. |
| **Cube Lab** | A real SceneKit cube with six distinct textured faces, continuous rotation, pause/start, a speed slider, reset, drag-to-rotate, scene-phase aware rendering, Reduce Motion support and settings that survive relaunch. |
| **Telemetry** | A deterministic `AsyncStream` of samples, a bounded history, a chart drawn with `Path` (no third-party charting and no Swift Charts, which needs iOS 16), plus start/pause/clear with correct task cancellation. |
| **Settings** | Accent colour, haptics, telemetry cadence and a confirmed reset of everything, persisted through an abstracted store and applied immediately across the app. |

## Requirements

* Xcode 16 or newer (developed and validated on **Xcode 26.6**, Swift 6.3 compiler in Swift 5 language mode).
* iOS 15.0 deployment target; builds against the iOS 26.5 simulator SDK.
* No third-party dependencies, no network access, no asset catalog — every colour and cube
  face is generated in code from system APIs and SF Symbols.

## Build

The `.xcodeproj` is checked in, so the project opens and builds with no extra tooling:

```bash
open OrbitLab.xcodeproj
```

From the command line:

```bash
xcodebuild \
  -project OrbitLab.xcodeproj \
  -scheme OrbitLab \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' \
  build
```

The project is also described declaratively in `project.yml`. If you change the file layout,
regenerate with [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`xcodegen generate`);
XcodeGen is a developer tool only and is not a dependency of the app.

## Test

Both test targets run from the shared `OrbitLab` scheme:

```bash
# Everything (unit + UI)
xcodebuild -project OrbitLab.xcodeproj -scheme OrbitLab \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' test

# Unit tests only
xcodebuild ... -only-testing:OrbitLabTests test

# UI tests only
xcodebuild ... -only-testing:OrbitLabUITests test
```

No test sleeps, waits on the wall clock, uses randomness or touches the network. Async
expectations are met by cooperatively yielding until a condition holds, and the telemetry
stream is paced by an injected ticker that returns immediately under test.

## Architecture

```
OrbitLab/
  App/          composition root (AppContainer), RootView, @main entry
  Models/       domain + persistence models, LoadState
  Services/     protocols and production implementations (mission, telemetry, storage, haptics)
  Features/     one folder per tab: view model (@MainActor, ObservableObject) + views
  DesignSystem/ theme, reusable cards, loading/error states
  Support/      accessibility identifiers shared with the UI test target
```

**MVVM with a composition root.** `AppContainer` builds every dependency once in
`OrbitLabApp` and hands it down; there are no singletons and no global mutable state. The
container owns the two pieces of state that must outlive a single screen — app settings and
Cube Lab settings — because "reset all settings" has to reach both.

**Everything crossing a boundary is a protocol.** `MissionService`, `TelemetrySource`,
`TelemetryTicker`, `KeyValueStore` and `HapticsProviding` each have a production type and a
test double. Swapping `LocalMissionService` for a networked one is a one-line change in the
container; no feature code moves.

**Main actor isolation is explicit.** Every view model is `@MainActor`, so published state
can only be mutated from the main actor. Work that is not UI work stays off it:
`LocalMissionService` builds its snapshot on the cooperative pool, and
`SimulatedTelemetrySource` produces samples from a detached task.

**SceneKit is kept out of the state layer.** `CubeLabViewModel` holds only values
(`isRotating`, `speed`, scene active, reduce motion) and persists them;
`CubeSceneController` owns the `SCNScene` and translates that state into scene commands. The
view model therefore unit tests without a renderer, and the controller is still covered by an
offscreen `SCNRenderer` test that proves the geometry rasterises.

### Tradeoffs

* **MVVM over a reducer.** For four screens, `ObservableObject` plus intent methods is less
  ceremony than a reducer/effect system and just as testable. A reducer would start paying
  off with shared cross-feature state, which this app does not have.
* **Chart drawn by hand.** Swift Charts requires iOS 16. A `Path` based line plus a gradient
  fill covers what this screen needs without giving up the iOS 15 target.
* **One `KeyValueStore` protocol with `Codable` payloads** rather than typed per-feature
  stores. Two settings structs do not justify more indirection.
* **Cube orientation is not persisted**, only the rotation preference and speed. Restoring an
  exact quaternion across launches adds state without adding anything the user asked for.
* **`streamTask` is exposed on `TelemetryViewModel`** so tests can await the consuming task
  instead of sleeping. A small amount of surface area buys fully deterministic async tests.

## Known limitations

* Mission Control data is local sample data. The seam for a networked service exists and is
  exercised by the test doubles, but no networking code ships.
* Only one telemetry channel is surfaced. `TelemetryChannel` is already an enum, so adding
  more is a data change rather than a redesign.
* Reduce Motion replaces the continuous spin with an on-demand quarter turn; it does not
  offer a slowed-down spin.
* The app ships without an icon or asset catalog, which is deliberate for a benchmark build
  and would obviously change for a real release.
* `TARGETED_DEVICE_FAMILY` includes iPad so any simulator works, but the layout is tuned for
  iPhone.
