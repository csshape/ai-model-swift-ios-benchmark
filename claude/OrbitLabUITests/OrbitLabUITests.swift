import XCTest

final class OrbitLabUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Every run starts from a clean in-memory store, so no test depends on another.
        app.launchArguments = [A11y.uiTestLaunchArgument]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func test_appLaunchesAndShowsAllFourTabs() {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))

        for title in [TabTitle.missionControl, TabTitle.cubeLab, TabTitle.telemetry, TabTitle.settings] {
            XCTAssertTrue(tabBar.buttons[title].exists, "Missing tab: \(title)")
        }
    }

    func test_missionControlExposesItsStatusHeaderByAccessibilityIdentifier() {
        let header = element(withIdentifier: A11y.MissionControl.statusHeader)

        XCTAssertTrue(header.waitForExistence(timeout: 10), "The status header must be reachable by a stable identifier")
        XCTAssertFalse((header.value as? String ?? "").isEmpty, "The header must expose its state to assistive technology")
    }

    func test_cubeLabPauseAndStartUpdatesTheRotationStatus() {
        app.tabBars.buttons[TabTitle.cubeLab].tap()

        let status = element(withIdentifier: A11y.CubeLab.statusLabel)
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        XCTAssertEqual(status.value as? String, "Rotating")

        let playPause = app.buttons[A11y.CubeLab.playPauseButton]
        XCTAssertTrue(playPause.waitForExistence(timeout: 5))
        playPause.tap()

        XCTAssertTrue(waitForValue("Paused", on: status), "Tapping pause must stop the rotation")

        playPause.tap()
        XCTAssertTrue(waitForValue("Rotating", on: status), "Tapping start must resume the rotation")
    }

    func test_changingTheTelemetryCadenceSettingIsVisibleOnTheTelemetryTab() {
        app.tabBars.buttons[TabTitle.telemetry].tap()
        let cadence = element(withIdentifier: A11y.Telemetry.cadenceLabel)
        XCTAssertTrue(cadence.waitForExistence(timeout: 10))
        XCTAssertEqual(cadence.value as? String, "Standard")

        app.tabBars.buttons[TabTitle.settings].tap()
        let toggle = app.switches[A11y.Settings.reducedCadenceToggle]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.tap()

        let summary = element(withIdentifier: A11y.Settings.summary)
        XCTAssertTrue(summary.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForValueContaining("Reduced cadence", on: summary))

        app.tabBars.buttons[TabTitle.telemetry].tap()
        XCTAssertTrue(waitForValue("Reduced", on: cadence), "The telemetry tab must reflect the new cadence")
    }

    // MARK: - Helpers

    /// Identifiers are set on SwiftUI views whose concrete element type can differ between
    /// iOS versions, so the lookup is deliberately type agnostic.
    private func element(withIdentifier identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func waitForValue(_ expected: String, on element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "value == %@", expected)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    private func waitForValueContaining(_ fragment: String, on element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "value CONTAINS %@", fragment)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
