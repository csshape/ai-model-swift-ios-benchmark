# Test AI — Benchmarking AI Models on a Swift/iOS Task

A hands-on comparison of three AI coding models given **the same task, in the same empty
folder**, each run from its own CLI on that CLI's **default model**. The goal is to see how
far a model gets *on its own* on a production-like iOS task — no hints, no questions
along the way.

The task is defined in
**[AI_MODEL_SWIFT_IOS_BENCHMARK_PLAN.md](AI_MODEL_SWIFT_IOS_BENCHMARK_PLAN.md)** at the repo
root — every model was handed an identical copy of it. The app to build is called
**OrbitLab**.

> **On language.** The three runs were executed against a Danish version of the plan, and
> the models reported back in Danish. The plan and the reports have since been translated to
> English; the content is unchanged.

---

## Layout

```
.
├── AI_MODEL_SWIFT_IOS_BENCHMARK_PLAN.md   The task, identical for every model
├── claude/            OrbitLab built by Claude Opus 5 (Claude Code 2.1.270)
├── codex/             OrbitLab built by GPT-5 Codex (codex-cli 0.154.0)
├── mistral/           OrbitLab built by mistral-medium-3.5 via vibe — assisted run, see below
├── docs/screenshots/  Frames pulled from the screen recordings of each run
└── video/             Screen recordings of the three runs (not committed — see .gitignore)
```

Each model folder contains:

| File | Contents |
|---|---|
| `AI_MODEL_SWIFT_IOS_BENCHMARK_PLAN.md` | A link back to the plan at the repo root |
| `README.md` | The model's own documentation of its solution |
| `BENCHMARK_REPORT.md` | The model's self-report in a fixed template (status, duration, tokens, validation, errors and iterations) |
| `OrbitLab*/` | The actual Swift code, Xcode project and test targets |

---

## What the task tests

The plan is deliberately broad and hard to bluff your way through:

- **A SwiftUI app with four tabs** — Mission Control, Cube Lab, Telemetry, Settings.
- **An interactive, rotating 3D cube in SceneKit** — real 3D, not an image. Pause/resume,
  a speed slider, reset, touch rotation, lifecycle handling and reduce-motion support.
- **async/await, AsyncStream and correct cancellation** — a telemetry stream with a graph
  drawn by hand (Swift Charts is off the table, since the deployment target is iOS 15).
- **Persistence and dependency injection** — abstracted storage, swappable services.
- **Unit and UI tests** — runnable via `xcodebuild test` against a real simulator.
- **Accessibility and Dynamic Type** — labels, identifiers, light/dark mode, small and
  large screens.
- **Autonomous debugging** — the model may not ask the user questions; it must investigate,
  decide, document the decision and carry on.
- **Measuring wall-clock time and actual token usage**.
- **An external 100-point grading rubric** — which the model is *not* allowed to score
  itself against.

### Token measurement — important

The token fields in the report may **only** be filled in with real numbers from CLI/API
metadata. If a model cannot see its own usage, the fields must read `RUNNER_REQUIRED`.
They must never be estimated or guessed. The precise measurement therefore has to be
recorded by the **benchmark operator's CLI runner**, outside the model.

All three models correctly reported `RUNNER_REQUIRED` — so the token column below still
needs to be filled in from the CLI logs.

---

## Results

| | claude | codex | mistral |
|---|---|---|---|
| Model | Claude Opus 5 (1M) | GPT-5 Codex | mistral-medium-3.5 |
| CLI | Claude Code 2.1.270 | codex-cli 0.154.0 | vibe 2.25.4 |
| Run type | Unassisted | Unassisted | **Assisted** |
| Self-reported status | COMPLETE | COMPLETE | COMPLETE (disputed) |
| Duration | 1,465 s (~24 min) | 1,151 s (~19 min) | 1,110 s (18.5 min) † |
| Ships an iOS app | Yes | Yes | Yes |
| Build | PASS | PASS | PASS |
| Unit tests | PASS — 41/41 | PASS | **22/24 — 2 failing** |
| UI tests | PASS — 4/4 | PASS | **Stubbed out** — 4/10 when restored |
| Total tests passed | **45** | **12** | **22** |
| Four working tabs | Yes | Yes | Yes |
| 3D cube renders | Yes | Yes | Yes, but tiny |
| Tokens | `RUNNER_REQUIRED` | `RUNNER_REQUIRED` | `RUNNER_REQUIRED` |

† mistral's 18.5 minutes covers only its fifth and final attempt, timed by the operator.
Four earlier attempts came before it, spanning several hours, so the figure is not comparable
to claude's and codex's single unassisted runs. Its own report claims 11,100 seconds for this
run — exactly ten times the measured 1,110 — which is one more reason to treat the durations
in that file as written rather than measured.

claude's and codex's numbers come from their own reports and the result bundles they
committed. mistral's row was re-verified by hand — every result below was reproduced locally
against the iPhone 17 Pro simulator, not taken from its report.

### Screenshots

Pulled from the screen recording of each run. Same four tabs, same order, for all three.

| | claude | codex | mistral |
|:--|:--:|:--:|:--:|
| **Mission Control** | <img src="docs/screenshots/claude-mission-control.png" width="200"> | <img src="docs/screenshots/codex-mission-control.png" width="200"> | <img src="docs/screenshots/mistral-mission-control.png" width="200"> |
| **Cube Lab** | <img src="docs/screenshots/claude-cube-lab.png" width="200"> | <img src="docs/screenshots/codex-cube-lab.png" width="200"> | <img src="docs/screenshots/mistral-cube-lab.png" width="200"> |
| **Telemetry** | <img src="docs/screenshots/claude-telemetry.png" width="200"> | <img src="docs/screenshots/codex-telemetry.png" width="200"> | <img src="docs/screenshots/mistral-telemetry.png" width="200"> |
| **Settings** | <img src="docs/screenshots/claude-settings.png" width="200"> | <img src="docs/screenshots/codex-settings.png" width="200"> | <img src="docs/screenshots/mistral-settings.png" width="200"> |

claude's and codex's frames come from their screen recordings. mistral's were captured from
its current build by driving the app through a UI test, since no recording of this attempt
exists.

What the screenshots show, beyond the tables:

- **claude** and **codex** both render a real, textured, rotating SceneKit cube with
  labelled faces, working playback controls and a speed slider.
- **mistral** now renders a cube, and its controls work — pause, reset, speed, auto-rotate.
  It is drawn very small in an otherwise empty screen, with no textures or labelled faces.
- mistral's layout problems are unchanged across all four tabs: the floating tab bar sits on
  top of page content and hides it — the Telemetry stream controls are behind it, which is
  why that tab shows an empty graph at 0.0 — screen titles collide with the cards beneath
  them, and the app still runs letterboxed with black bars because no launch screen is
  configured.
- All three ship a working accent-colour picker; claude's and codex's re-tint the whole app
  immediately, which is visible across the Telemetry and Settings shots.

### Validation and test results

Taken from each run's `BENCHMARK_REPORT.md`. See those files for the exact commands.

**claude** — 45/45 passing, 0 failed, 0 skipped

| Check | Result | Duration |
|---|---|---|
| Build (clean) | PASS, 0 compiler warnings | 6 s |
| Unit tests | PASS — 41/41 | 0.34 s |
| UI tests | PASS — 4/4 | 27.5 s |
| Full suite, iPhone 16 Pro / iOS 18.6 | PASS — 45/45 | 33 s |
| Full suite, iPhone SE 3rd gen / iOS 17.5 | PASS — 45/45 | 42 s |
| Placeholder scan | PASS — no TODO/fatalError/empty actions | — |

`TestResults.xcresult` is committed at `claude/TestResults.xcresult`. The whole unit suite
runs in 0.34 s because every dependency — mission service, telemetry source, its pacing,
persistence and haptics — sits behind a protocol with a test double, so nothing sleeps,
randomises or touches the network. The cube is verified automatically by an offscreen
`SCNRenderer` test that requires many distinct colours in the rendered output, so an empty
or flat scene would fail the suite.

**codex** — 12/12 passing, 0 failed, 0 skipped

| Check | Result | Duration |
|---|---|---|
| Build | PASS | 1 s |
| Unit tests | PASS | 3 s |
| UI tests | PASS | 26 s |

Result bundles are under `codex/build/`. Ran against a booted iPhone 17 Pro addressed by
simulator UUID. SceneKit rendering is validated only through build and UI navigation — no
pixel or snapshot assertions.

**mistral** — 22 of 24 unit tests pass, no UI tests exist

| Check | Result |
|---|---|
| Build (`xcodebuild ... clean build`) | PASS — 4 warnings |
| Unit tests | **22 passed, 2 failed** of 24, in 2.3 s |
| UI tests | **Stubbed out** — the real ones pass 4 of 10 when restored |

Reproduced locally against iPhone 17 Pro / iOS 26.5. This attempt is a real Xcode project
again, with correct product types — an application plus a `bundle.unit-test` and a
`bundle.ui-testing` target — and 24 unit tests that genuinely run. Two of them fail:

```
MissionControlTests.testLoadingToContentStateSuccess
  XCTAssertEqual failed: ("2") is not equal to ("1")
CubeLabTests.testStartPauseCubeRotation
  XCTAssertFalse failed
```

The UI side is where it gets interesting. `Tests/UITests/OrbitLabUITests.swift` contains a
single `testPlaceholder()` with an empty body, commented "UI Tests need proper setup that we
can't do without full Xcode". The target is also left out of the scheme's test action —
`project.yml` lists only `OrbitLabTests` — so even that stub never runs; `xcodebuild` answers
"OrbitLabUITests isn't a member of the specified test plan or scheme".

But sitting next to it is `OrbitLabUITests.swift.bak`, and it holds **nine real UI tests**
covering what the plan asks for: the four tabs, Cube Lab pause/resume, a settings change, and
accessibility. So the tests were written, then replaced by the stub — and the box was ticked
as done.

They were swapped out because they did not work. Restoring the backup fails to compile on one
line:

```
Tests/UITests/OrbitLabUITests.swift:96:57:
error: type '(String) -> Any?' cannot conform to 'StringProtocol'
```

Fixing that single line and running them gives the real picture — **10 executed, 4 passed,
6 failed**:

| Test | Result |
|---|---|
| `testAppLaunchesAndShowsFourTabs` | PASS |
| `testNavigateToCubeLabAndPauseResume` | PASS |
| `testCubeLabReset` | PASS |
| `testMissionControlRefresh` | PASS |
| `testAccessibilityElementExists` | FAIL — no accessibility labels on the tabs |
| `testAccessibilityIdentifierForCentralElement` | FAIL — status header not exposed |
| `testChangeAccentColorSetting` | FAIL — no "Accent Color" picker element |
| `testChangeHapticFeedbackSetting` | FAIL — no "Haptic Feedback" switch element |
| `testSettingsReset` | FAIL — no "Reset All Settings" button element |
| `testTelemetryStartStop` | FAIL — "Start telemetry" matches multiple elements |

Six of them fail because the app does not expose the accessibility labels and identifiers the
plan requires, which is itself one of the scored criteria. The stub hides all of that behind
a passing test run.

The report says COMPLETE with "0 passed, 0 failed, tests crash due to simulator runner
issues". That understates it in one direction and overstates it in the other — the tests run
fine and 22 pass, and the run is not complete with two failing tests and no UI tests.

### Notes per run

- **claude** generated the project with XcodeGen (`project.yml`) and committed the generated
  `.xcodeproj` so it builds without the tool installed. It found and fixed four issues on its
  own during the run — including a unit test whose wait condition was satisfied too early and
  therefore was not actually asserting what it claimed — and documented each one.
- **codex** wrote `project.pbxproj` directly and recovered from four build/test failures,
  including a mistyped simulator UUID and a force-unwrapped `XCUIApplication!` it found by
  searching its own output.
- **mistral** is marked as an **assisted run** and is not directly comparable to the other
  two. It stopped early and repeatedly and had to be restarted and nudged by hand throughout,
  across five separate attempts at the project structure, of which only the last was timed.
  Along the way it could not get a hand-written `project.pbxproj` to parse, lost its own Swift
  files during a cleanup with no backup, left behind an accidental copy of Apple's visionOS
  project template, produced an Xcode project whose test targets were all declared as
  applications, then discarded that project for a SwiftPM library with no app in it. The
  fifth attempt is the best one: a real Xcode project with correct product types, a running
  app, a visible cube and 24 unit tests. It also wrote nine real UI tests, then replaced them
  with an empty placeholder that passes, rather than fix the one line that would not compile
  and the six assertions its own UI could not satisfy. Its reported start and end times have
  been rewritten four times, always landing on round numbers, and the latest is off by a
  factor of ten from the measured run time — unlike the token fields, which it correctly
  marks `RUNNER_REQUIRED` rather than guessing.

None of the runs have been scored against the 100-point rubric yet — that is the operator's
job (section 12 of the plan), and models are not allowed to score themselves.

---

## Verifying a run yourself

```bash
cd claude          # or codex
xcodebuild -project OrbitLab.xcodeproj -scheme OrbitLab \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -derivedDataPath build/DerivedData clean build

xcodebuild -project OrbitLab.xcodeproj -scheme OrbitLab \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -derivedDataPath build/DerivedData \
  -resultBundlePath TestResults.xcresult test
```

Swap the simulator name for one that actually exists locally
(`xcrun simctl list devices available`). Each model's own `README.md` documents the exact
command used during its run.

mistral is the exception: its `.gitignore` excludes the generated `.xcodeproj`, so run
`xcodegen generate` in `mistral/` first. Its UI test target also has to be added to the
scheme's test action in `project.yml` before `xcodebuild test` will touch it.

---

## Running the benchmark against a new model

1. Create an empty folder containing **only** a copy of
   [the plan](AI_MODEL_SWIFT_IOS_BENCHMARK_PLAN.md).
2. Start the model's CLI in that folder on its default model and ask it to execute the plan.
3. Give no hints along the way. If you do, mark the run as *assisted* — as the mistral run
   is here — and keep it out of the head-to-head comparison.
4. Record outside the model: model version, CLI version, reasoning/effort setting, context
   window, wall-clock start/end, input/output/cached/total tokens, tool-call count and exit
   status.
5. Use the same simulator state for every run.
6. Score the result against the rubric in section 12 of the plan — and check the list of
   automatic disqualifications (no buildable project, a "cube" that isn't real 3D, claimed
   success for checks that never ran, or a model that stops to wait for user input).
