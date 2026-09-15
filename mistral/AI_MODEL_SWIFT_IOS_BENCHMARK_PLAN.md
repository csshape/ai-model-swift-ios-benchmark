# Benchmark Plan: AI Models for Swift and iOS

## 1. Role and way of working

You are an autonomous senior iOS developer. Complete the entire task in this folder without asking the user any questions along the way.

If something is unclear, you must:

1. investigate the project and the installed tooling,
2. choose the most reasonable solution,
3. document the choice in `BENCHMARK_REPORT.md`, and
4. carry on with the work.

You may only deliver your final answer once the app is implemented, the relevant automated checks have been run, and the report is written. You must not stop after producing only a plan or a partial prototype.

## 2. Purpose

Build a small but production-like iOS app that demonstrates your abilities in:

- modern Swift and SwiftUI,
- architecture and dependency injection,
- 3D graphics,
- structured concurrency,
- local persistence,
- unit and UI testing,
- accessibility and robust error handling,
- autonomous debugging and validation.

The app must be named **OrbitLab**.

## 3. Technical constraints

- Swift 5.10 or newer.
- SwiftUI.
- Minimum deployment target: iOS 15.0.
- An Xcode project or workspace that can be built from the command line with `xcodebuild`.
- No third-party dependencies.
- Use only public Apple frameworks that exist on iOS 15.
- The app's production code must not require network access to function or to be tested.
- Avoid force unwraps, artificial delays in tests, and global mutable singletons.
- UI-related state must be correctly isolated to the main actor. Long-running work must not be performed on the main actor unnecessarily.
- The code must be organized, readable, and free of dead placeholder functions.

If the folder already contains a project, it must be examined and reused where that makes sense. Existing relevant code must not be destructively overwritten without reason.

## 4. App requirements

The app must have four tabs. Every tab must have SF Symbols, meaningful accessibility labels, and navigation titles.

### Tab 1: Mission Control

Build a visual dashboard with:

- a clear status header,
- at least three reusable metric cards,
- a list of recent mission events,
- a loading, content, and error state,
- pull-to-refresh,
- data from an asynchronous service.

The service must have a real production implementation that delivers local deterministic sample data asynchronously, plus a test double. The architecture must make it possible to later swap the implementation for a network service.

### Tab 2: Cube Lab

Show a genuine interactive 3D cube with six clearly distinct faces, using SceneKit integrated into SwiftUI.

Requirements:

- the cube rotates automatically with smooth animation,
- the user can pause and resume the rotation,
- a slider controls the rotation speed,
- a reset button restores orientation and speed,
- the user can rotate the camera or the cube by touch,
- the app lifecycle is handled so unnecessary animation work stops when the app becomes inactive,
- the settings persist across app launches,
- reduce motion is respected with a reasonable alternative behavior,
- SceneKit objects and SwiftUI state are kept separate in a testable way.

### Tab 3: Telemetry

Build a live but deterministic telemetry experience:

- an asynchronous stream produces data points,
- the screen shows the current value and at least 20 historical values,
- draw a simple graph without third-party libraries and without Swift Charts, since the deployment target is iOS 15,
- the user can start, pause, and clear the data,
- the stream/task is cancelled correctly when it is no longer needed,
- the model must not use an uncontrolled timer that makes unit tests slow or flaky.

### Tab 4: Settings

Provide settings for:

- accent color from at least three choices,
- haptic feedback on/off,
- reduced telemetry update frequency on/off,
- resetting all settings with a confirmation dialog.

Settings must be persisted through an abstracted storage solution and must affect the relevant parts of the app immediately.

## 5. Architecture requirements

- Separate views, state/feature logic, services, and models.
- Dependencies must be replaceable in tests.
- View state must have clear loading/content/error states where relevant.
- Errors must be presented in a user-friendly way and be retryable.
- Codable/domain models must use meaningful types rather than loose dictionaries.
- Briefly explain the most important architectural choices in the project's `README.md`.
- Over-engineering counts against you. The solution must match the size of the app.

You may choose MVVM, a reducer-based architecture, or another well-justified structure.

## 6. Testing requirements

Create a unit test target and a UI test target. All tests must be runnable via `xcodebuild test` on an available iOS Simulator.

There must be at least unit tests for:

1. Mission Control: loading to content.
2. Mission Control: error and retry.
3. Cube Lab: start/pause, speed change, and reset.
4. Cube Lab: persistence of settings.
5. Telemetry: start, receiving values, pause, and cancellation.
6. Telemetry: the history is correctly capped.
7. Settings: load, change, and full reset.
8. At least one edge case that you identify yourself.

There must be at least UI tests for:

1. the app launches and shows the four tabs,
2. navigating to Cube Lab and pausing/resuming the cube,
3. changing a setting that can be observed in the UI,
4. a central accessibility element can be found via a stable accessibility identifier.

Test quality requirements:

- no dependency on test ordering,
- no real waiting, randomness, or network,
- test doubles must be simple and focused,
- test names must describe behavior and expectation.

## 7. Design and quality

- Create a coherent "space/mission control" look that works in light and dark mode.
- The layout must work on both a small iPhone screen and a larger iPhone.
- Support Dynamic Type without obvious clipping of important text.
- Interactive elements must have appropriate hit areas.
- Use native components, materials, and SF Symbols rather than copied assets.
- Add previews for at least three central views, if the toolchain supports it reliably.

## 8. Documentation

Create a short `README.md` with:

- what the app demonstrates,
- Xcode and iOS requirements,
- how the app is built,
- how all tests are run,
- architecture and significant tradeoffs,
- known limitations.

Also create `BENCHMARK_REPORT.md` following the template in section 10.

## 9. Mandatory validation

Before delivering, you must:

1. record the start time as early as possible,
2. investigate which Xcode versions and simulators are available,
3. build the app with `xcodebuild`,
4. run all unit and UI tests with `xcodebuild test`,
5. fix the errors you can find, and repeat build/tests,
6. run `git diff --check` if the folder is a Git repository,
7. review the final result for placeholders such as `TODO`, `fatalError`, empty actions, and unused mock screens,
8. record the end time and fill in the report.

Use a concrete simulator destination that actually exists in the environment. If the environment technically prevents building or testing, you must still deliver the best possible implementation and document the exact command, output/error, and likely cause. Never write that a test passed if it was not run successfully.

## 10. `BENCHMARK_REPORT.md`

Use exactly this structure:

```markdown
# Benchmark Report

## Result
- Status: COMPLETE | PARTIAL | BLOCKED
- Start (UTC):
- End (UTC):
- Duration in seconds:
- Model name/version:
- CLI/tool version:
- Input tokens:
- Output tokens:
- Cached tokens:
- Total tokens:
- Token source: CLI/API | RUNNER_REQUIRED | UNAVAILABLE

## Implemented
- [ ] Four working tabs
- [ ] Interactive rotating 3D cube
- [ ] Async Mission Control service and states
- [ ] Async telemetry stream and graph
- [ ] Persistent settings
- [ ] Unit test target and the required unit tests
- [ ] UI test target and the required UI tests
- [ ] README

## Validation
| Check | Command | Result | Duration |
|---|---|---|---|
| Build | `...` | PASS/FAIL/NOT RUN | ... |
| Unit tests | `...` | PASS/FAIL/NOT RUN | ... |
| UI tests | `...` | PASS/FAIL/NOT RUN | ... |
| Diff check | `...` | PASS/FAIL/NOT APPLICABLE | ... |

## Test results
- Number passed:
- Number failed:
- Number skipped:
- `.xcresult` location:

## Autonomous decisions
- Decision, rationale, and tradeoff.

## Errors and iterations
- Error, cause, fix, and result.

## Known limitations
- None, or a concrete list.

## Changed/created files
- Relative path and purpose.

## Brief final assessment
- What is strongest in the solution?
- What would you improve with more time?
```

The token fields may only be filled in with actual numbers from CLI/API metadata. If the model does not itself have access to the token measurement, the fields must be set to `RUNNER_REQUIRED`; they must never be estimated or filled in with made-up numbers. Time must be measured from the start of the work to the finished report, not just from the most recent build.

## 11. Final delivery

The final answer to the user must be short and contain:

- status,
- what was built,
- build and test results,
- duration and tokens, or a clear marker that the runner must supply the tokens,
- the path to `BENCHMARK_REPORT.md`,
- any real blockers.

You must not ask the user to perform ordinary development steps that you have access to perform yourself.

## 12. External grading rubric (no self-scoring)

This section is for the benchmark operator. The model must not award itself points.

| Area | Points |
|---|---:|
| The project builds on the specified simulator | 15 |
| All unit tests pass | 10 |
| All UI tests pass | 5 |
| Four complete and coherent tabs | 8 |
| A genuine SceneKit cube, animation, and interaction | 12 |
| Correct lifecycle, reduce motion, and persistence for the cube | 6 |
| Async service, state, and error handling | 8 |
| Telemetry stream, graph, and correct cancellation | 8 |
| Architecture, dependency injection, and code quality | 10 |
| Test quality and relevant edge cases | 8 |
| Accessibility, Dynamic Type, and screen sizes | 5 |
| README and an accurate benchmark report | 3 |
| Autonomous debugging and documented iterations | 2 |
| **Total** | **100** |

### Automatic disqualifications

- No buildable app or no real Xcode project.
- The 3D cube is only a 2D image or a CSS/web view.
- The model claims success for checks that were not run.
- The model waits for an answer from the user instead of making a reasonable, documented decision.
- The majority of the app is placeholders or disconnected demo screens.

### Benchmark operator's record

The operator should start each model in an identical copy of the same empty folder and record the following outside the model:

- exact model and model version,
- CLI version and CLI configuration,
- reasoning/effort setting,
- context window and token budget,
- wall-clock start/end,
- input, output, cached, and total tokens from CLI/API usage metadata,
- number of tool calls and any retries,
- exit status,
- a Git diff or archive of the final result.

Use a fresh simulator, or the same known simulator state, for all runs. Do not give a model extra manual hints unless the run is separately marked as an assisted run.

