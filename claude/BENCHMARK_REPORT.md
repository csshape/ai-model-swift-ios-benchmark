# Benchmark Report

## Result
- Status: COMPLETE
- Start (UTC): 2026-09-14T08:42:25Z
- End (UTC): 2026-09-14T09:06:50Z
- Duration in seconds: 1465
- Model name/version: Claude Opus 5 (1M context), model id `claude-opus-5[1m]`
- CLI/tool version: Claude Code 2.1.270
- Input tokens: RUNNER_REQUIRED
- Output tokens: RUNNER_REQUIRED
- Cached tokens: RUNNER_REQUIRED
- Total tokens: RUNNER_REQUIRED
- Token source: RUNNER_REQUIRED

The model does not have access to its own usage metadata in this session. The token fields
are therefore marked `RUNNER_REQUIRED` and must be filled in by the benchmark operator from
CLI/API metadata. They have not been estimated.

## Implemented
- [x] Four working tabs
- [x] Interactive rotating 3D cube
- [x] Async Mission Control service and states
- [x] Async telemetry stream and graph
- [x] Persistent settings
- [x] Unit test target and the required unit tests
- [x] UI test target and the required UI tests
- [x] README

## Validation

All commands were run from the project folder. Shared destination:
`-destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6'`.

| Check | Command | Result | Duration |
|---|---|---|---|
| Build | `xcodebuild -project OrbitLab.xcodeproj -scheme OrbitLab -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' -derivedDataPath build/DerivedData clean build` | PASS (`** BUILD SUCCEEDED **`, 0 compiler warnings) | 6 s |
| Unit tests | `xcodebuild ... -only-testing:OrbitLabTests test` (included in the combined run below) | PASS — 41/41 | 0.34 s |
| UI tests | `xcodebuild ... -only-testing:OrbitLabUITests test` (included in the combined run below) | PASS — 4/4 | 27.5 s |
| Combined test run | `xcodebuild -project OrbitLab.xcodeproj -scheme OrbitLab -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' -derivedDataPath build/DerivedData -resultBundlePath TestResults.xcresult test` | PASS — 45/45 | 33 s |
| Extra: full suite on a small screen | `xcodebuild ... -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=17.5' test` | PASS — 45/45 | 42 s |
| Diff check | `git diff --check` | NOT APPLICABLE — the folder is not a Git repository (`fatal: not a git repository`) | — |
| Placeholder scan | `grep -rnE "TODO\|FIXME\|fatalError\|XXX\|placeholder" OrbitLab OrbitLabTests OrbitLabUITests` | PASS — the only hit is the word "placeholder" in a doc comment; no TODO/fatalError/empty actions | — |

Environment: Xcode 26.6 (17F113), Swift compiler 6.3.3 in Swift 5 language mode, iOS 26.5
simulator SDK, deployment target iOS 15.0.

## Test results
- Number passed: 45 (41 unit, 4 UI)
- Number failed: 0
- Number skipped: 0
- `.xcresult` location: `TestResults.xcresult` at the root of the project folder
  (the secondary iPhone SE run lives in the session scratchpad and is not part of the delivery).

## Autonomous decisions

- **The project is generated with XcodeGen, but the `.xcodeproj` is committed.**
  Writing `project.pbxproj` by hand is error-prone. `project.yml` describes the project
  declaratively, and the generated `OrbitLab.xcodeproj` sits in the folder, so the project
  builds without XcodeGen installed. Tradeoff: two sources of the project structure have to
  be kept in sync — regeneration is therefore documented in the README. XcodeGen is a
  developer tool, not an app dependency; the app has no third-party dependencies.
- **Swift 5 language mode on the Swift 6.3 compiler.** The plan requires Swift 5.10+.
  Swift 6's strict concurrency would have cost time on annotation noise without making the
  app more correct at this size; instead, all UI state is explicitly `@MainActor`-isolated.
- **MVVM rather than a reducer architecture.** Four screens with no shared cross-feature
  state do not justify a reducer/effect engine. Tradeoff: shared state across features would
  require more structure later.
- **`AppContainer` owns `AppSettingsStore` and `CubeLabViewModel`.** Both have to outlive tab
  switches, and "reset all settings" must be able to reach both. The remaining view models
  are owned by their view via `@StateObject`. Tradeoff: the container knows about two
  feature types.
- **The cube's orientation is not persisted** — only `isRotating` and `speed`. The plan
  requires that "the settings" survive; an exact quaternion across launches is state with no
  user value.
- **Reduce Motion alternative:** continuous rotation is turned off and the user instead gets
  a "Step a quarter turn" button plus continued drag interaction. The alternative (a slower
  spin) would still be persistent motion.
- **Touch rotation via a custom `UIPanGestureRecognizer` on a pivot node** instead of
  `allowsCameraControl`. SceneKit's built-in camera control replaces `pointOfView` and makes
  a deterministic reset difficult. The pivot node also composes cleanly with the spin action.
- **The graph is drawn with `Path`.** Swift Charts requires iOS 16; the deployment target is
  iOS 15.
- **Tests never wait on the clock.** `waitUntil` yields cooperatively until a condition holds
  (with an iteration budget, so a broken expectation fails instead of hanging), and the
  telemetry stream is paced by an injected `TelemetryTicker` that returns immediately under
  test. Tradeoff: `TelemetryViewModel.streamTask` is exposed internally so tests can await
  the consuming task.
- **UI tests launch the app with `-orbitlab-ui-tests`**, which selects an in-memory
  `KeyValueStore` and silent haptics. That makes the UI tests independent of ordering and of
  whatever a previous run left behind.
- **No asset catalog.** Accent colors are dynamic `UIColor` providers (correct in light and
  dark), and the cube's six faces are drawn in code from SF Symbols with
  `UIGraphicsImageRenderer`. Tradeoff: the app has no app icon.
- **The app's display name is `OrbitLab-Claude`** following an explicit request from the user
  mid-task. The Xcode project, scheme and Swift module are still called `OrbitLab`, because a
  hyphen is not legal in a Swift module name and a module rename would break
  `@testable import`.

## Errors and iterations

1. **The unit test `test_historyIsTrimmedToTheRetentionLimit` failed** (expected the first
   sample to be `12.0`, got `0.0`).
   *Cause:* the wait condition was `samples.count == historyLimit`, which becomes true as
   soon as the first 60 of 72 samples have arrived — the history stops growing, so the
   condition was not a valid "done" signal.
   *Fix:* it now waits for the **newest** sample to be the last one the source produced.
   *Result:* the test passes, and the assertion that the oldest samples are dropped first is
   now meaningful.

2. **`-only-testing:OrbitLabUITests/ScreenshotCapture` reported "TEST SUCCEEDED" without
   running anything.** *Cause:* the new test file had been placed in the folder, but the
   project had not been regenerated, so the file was not part of the target —
   `-only-testing` matched nothing. *Fix:* `xcodegen generate` before running. *Result:* the
   test ran and produced screenshots. (The temporary screenshot test has since been removed;
   it was a validation tool, not part of the delivery.)

3. **`SystemHaptics` would not compile as written** (main-actor-isolated stored properties
   accessed from a `nonisolated` method). *Cause:* unnecessary state in a type that does not
   need any. *Fix:* the type was made stateless; the generators are created inside a
   `@MainActor` task. *Result:* compiles cleanly, and the seam is still testable via
   `SilentHaptics`.

4. **Visual inspection revealed two cosmetic issues:** the cube was too small in its card,
   and "Reset all settings" inherited the accent color instead of reading as destructive.
   *Fix:* the camera was moved from z=7.5 to z=6.2, and the reset button got `.tint(.red)`.
   *Result:* verified on screenshots in both light and dark mode.

Validation after the fixes: build and the full test suite were run again from a clean build
and pass (45/45), including on iPhone SE (3rd generation) with iOS 17.5.

## Known limitations
- Mission Control serves local sample data. The seam for a network service exists and is
  covered by test doubles, but no networking code ships in the app.
- Only one telemetry channel is surfaced in the UI; `TelemetryChannel` is already an enum, so
  adding more is a data change, not a redesign.
- Reduce Motion offers a discrete quarter turn, not a slowed continuous spin.
- No asset catalog and no app icon (deliberate for a benchmark build).
- `TARGETED_DEVICE_FAMILY` includes iPad so that any simulator can be used, but the layout is
  tuned for iPhone.
- Dynamic Type and screen sizes were verified visually on iPhone 16 Pro and iPhone SE
  (3rd generation) at `AccessibilityExtraExtraExtraLarge`, not via automated snapshot
  assertions.

## Changed/created files

**Project and documentation**
- `project.yml` — declarative project definition (targets, scheme, Info.plist, build settings).
- `OrbitLab.xcodeproj/` — generated Xcode project, committed so the build works without XcodeGen.
- `README.md` — what the app demonstrates, requirements, build/test commands, architecture, tradeoffs.
- `BENCHMARK_REPORT.md` — this report.
- `.gitignore` — build output.
- `TestResults.xcresult/` — result bundle from the final combined test run.

**App — composition and navigation**
- `OrbitLab/App/OrbitLabApp.swift` — `@main`, builds the container once.
- `OrbitLab/App/AppContainer.swift` — composition root and `resetAllSettings()`.
- `OrbitLab/App/RootView.swift` — the four tabs and the app-wide accent tint.

**App — models**
- `OrbitLab/Models/LoadState.swift` — idle/loading/content/failed + user-facing `LoadFailure`.
- `OrbitLab/Models/MissionModels.swift` — status, metric, event, snapshot.
- `OrbitLab/Models/TelemetryModels.swift` — sample, channel, cadence.
- `OrbitLab/Models/CubeSettings.swift` — rotation preference, speed and clamping.
- `OrbitLab/Models/AppSettings.swift` — accent, haptics, cadence + summary.

**App — services (protocol + production implementation)**
- `OrbitLab/Services/MissionService.swift` — protocol, error type, `LocalMissionService`,
  deterministic generator.
- `OrbitLab/Services/TelemetrySource.swift` — `TelemetrySource`, `TelemetryTicker`,
  `IntervalTicker`, `SimulatedTelemetrySource`.
- `OrbitLab/Services/KeyValueStore.swift` — protocol, `Codable` helpers, UserDefaults and
  in-memory implementations.
- `OrbitLab/Services/Haptics.swift` — `HapticsProviding`, `SystemHaptics`, `SilentHaptics`.

**App — features**
- `OrbitLab/Features/MissionControl/MissionControlViewModel.swift` — load, refresh, retry.
- `OrbitLab/Features/MissionControl/MissionControlView.swift` — dashboard, states,
  pull-to-refresh, event list.
- `OrbitLab/Features/CubeLab/CubeLabViewModel.swift` — rotation, speed, lifecycle,
  reduce motion, persistence.
- `OrbitLab/Features/CubeLab/CubeSceneController.swift` — the SceneKit graph, spin, reset,
  drag, quarter turn, rendering suspension.
- `OrbitLab/Features/CubeLab/CubeSceneView.swift` — `UIViewRepresentable` + pan gesture.
- `OrbitLab/Features/CubeLab/CubeFace.swift` — the six faces and their code-drawn textures.
- `OrbitLab/Features/CubeLab/CubeLabView.swift` — scene card, controls, reduce-motion card.
- `OrbitLab/Features/Telemetry/TelemetryViewModel.swift` — stream consumption, history limit,
  start/pause/clear, cadence change.
- `OrbitLab/Features/Telemetry/TelemetryChartView.swift` — `Path`-based graph.
- `OrbitLab/Features/Telemetry/TelemetryView.swift` — readout, graph, controls.
- `OrbitLab/Features/Settings/AppSettingsStore.swift` — observable owner of the preferences.
- `OrbitLab/Features/Settings/SettingsView.swift` — accent, toggles, reset with a
  confirmation dialog.

**App — design system and support**
- `OrbitLab/DesignSystem/Theme.swift` — accent colors, background, panel chrome.
- `OrbitLab/DesignSystem/MetricCard.swift` — reusable metric card (+ preview).
- `OrbitLab/DesignSystem/StateViews.swift` — loading and error states (+ preview).
- `OrbitLab/Support/AccessibilityIdentifiers.swift` — identifiers and tab titles, shared with
  the UI test target.
- `OrbitLab/Resources/Info.plist` — generated; sets the display name `OrbitLab-Claude`.

**Tests**
- `OrbitLabTests/Doubles/TestDoubles.swift` — stub service, controlled telemetry source,
  immediate ticker, recording store.
- `OrbitLabTests/Support/AsyncTestSupport.swift` — cooperative `waitUntil` with no waiting.
- `OrbitLabTests/Support/TestFixtures.swift` — fixed domain data.
- `OrbitLabTests/Features/MissionControlViewModelTests.swift` — 5 tests.
- `OrbitLabTests/Features/TelemetryViewModelTests.swift` — 7 tests.
- `OrbitLabTests/Features/CubeLabViewModelTests.swift` — 6 tests.
- `OrbitLabTests/Features/CubeSceneControllerTests.swift` — 5 tests, incl. offscreen rendering.
- `OrbitLabTests/Features/AppSettingsStoreTests.swift` — 7 tests (settings + container).
- `OrbitLabTests/Services/KeyValueStoreTests.swift` — 4 tests.
- `OrbitLabTests/Services/LocalMissionServiceTests.swift` — 4 tests.
- `OrbitLabTests/Services/SimulatedTelemetrySourceTests.swift` — 3 tests.
- `OrbitLabUITests/OrbitLabUITests.swift` — 4 UI tests.

### Coverage of the plan's testing requirements

| Requirement | Test |
|---|---|
| Mission Control: loading → content | `test_loadIfNeeded_movesFromIdleThroughLoadingToContent` |
| Mission Control: error and retry | `test_failedLoad_exposesUserFacingFailure_andRetrySucceeds` |
| Cube Lab: start/pause, speed, reset | `test_togglePlaybackSpeedChangeAndResetDriveTheAnimationState` |
| Cube Lab: persistence | `test_settingsSurviveANewViewModelBackedByTheSameStore` |
| Telemetry: start, values, pause, cancellation | `test_start_receivesSamplesAndPauseCancelsTheStream` |
| Telemetry: history limit | `test_historyIsTrimmedToTheRetentionLimit` |
| Settings: load, change, full reset | `test_loadsShippedDefaultsWhenNothingHasBeenPersisted`, `test_changesArePersistedAndReloadedByAFreshStore`, `test_resetRestoresEveryDefault`, `test_resetAllSettingsClearsBothAppAndCubePreferences` |
| Edge cases | `test_outOfRangePersistedSpeedIsNormalisedOnLoad` (corrupt/stale persisted speed), `test_corruptPayloadFallsBackToTheDefaultAndClearsTheKey` (unreadable payload), `test_cadenceChangeWhilePausedDoesNotStartStreaming`, `test_refreshFailureAfterSuccess_replacesContentWithARetryableError` |
| UI: four tabs | `test_appLaunchesAndShowsAllFourTabs` |
| UI: Cube Lab pause/start | `test_cubeLabPauseAndStartUpdatesTheRotationStatus` |
| UI: a setting observable in the UI | `test_changingTheTelemetryCadenceSettingIsVisibleOnTheTelemetryTab` |
| UI: stable accessibility identifier | `test_missionControlExposesItsStatusHeaderByAccessibilityIdentifier` |

## Brief final assessment

**Strongest:** the seams. Every single dependency — the mission service, the telemetry
source, its pacing, persistence and haptics — is a protocol with both a production type and
a focused test double, and that is why the whole test suite runs in 0.34 seconds without
sleeping, without randomness and without network. The cube is genuine SceneKit geometry, and
that is proven automatically: an offscreen `SCNRenderer` test renders the scene and requires
many distinct colors in the output, so an empty or flat scene would fail. The separation
between `CubeLabViewModel` (pure values) and `CubeSceneController` (the scene graph) makes
lifecycle, reduce motion and persistence testable without a renderer.

**With more time:** snapshot tests for Dynamic Type and screen sizes instead of visual
inspection; an actual network layer behind `MissionService` to prove the seam holds; more
telemetry channels with channel selection in the UI; an app icon and a launch-screen
treatment; and a pass in Swift 6 language mode with full strict concurrency.
