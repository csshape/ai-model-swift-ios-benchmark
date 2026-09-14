import XCTest

final class OrbitLabUITests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launchArguments = ["--reset-settings", "--ui-testing"]
        app.launch()
    }

    func testAppStartsAndShowsFourTabs() {
        let tabBar = app.tabBars.firstMatch

        XCTAssertTrue(tabBar.buttons["Mission"].waitForExistence(timeout: 5))
        XCTAssertTrue(tabBar.buttons["Cube"].exists)
        XCTAssertTrue(tabBar.buttons["Telemetry"].exists)
        XCTAssertTrue(tabBar.buttons["Settings"].exists)
    }

    func testNavigateToCubeAndPauseStartRotation() {
        app.tabBars.buttons["Cube"].tap()

        let toggle = app.buttons["cube.rotation.toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        XCTAssertEqual(toggle.label, "Pause Rotation")

        toggle.tap()
        XCTAssertEqual(toggle.label, "Start Rotation")

        toggle.tap()
        XCTAssertEqual(toggle.label, "Pause Rotation")
    }

    func testChangingSettingIsObservableInUI() {
        app.tabBars.buttons["Settings"].tap()

        let status = app.staticTexts["settings.accent.status"]
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertEqual(status.label, "Selected Accent: Orbital Blue")

        app.buttons["settings.accent.solarGold"].tap()

        let changedAccent = NSPredicate(format: "label == %@", "Selected Accent: Solar Gold")
        expectation(for: changedAccent, evaluatedWith: status)
        waitForExpectations(timeout: 5)
    }

    func testCentralAccessibilityElementCanBeFoundByStableIdentifier() {
        app.tabBars.buttons["Mission"].tap()

        let header = app.descendants(matching: .any)["mission.status.header"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))
    }
}
