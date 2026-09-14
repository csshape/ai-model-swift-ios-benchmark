import XCTest

class OrbitLabUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunchesAndShowsTabs() {
        let app = XCUIApplication()
        app.launch()
        let tabs = ["Mission Control", "Cube Lab", "Telemetry", "Settings"]
        for tab in tabs {
            let b = app.tabBars.buttons[tab]
            XCTAssertTrue(b.waitForExistence(timeout: 5), "Tab \(tab) should exist")
        }
        XCTAssertTrue(app.tabBars.buttons["Mission Control"].isSelected)
    }

    func testNavigationToCubeLab() {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Cube Lab"].tap()
        XCTAssertTrue(app.tabBars.buttons["Cube Lab"].isSelected)
        XCTAssertTrue(app.otherElements["cube3DView"].waitForExistence(timeout: 5))
    }

    func testCubeLabPauseStart() {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Cube Lab"].tap()
        let btn = app.buttons["toggleRotationButton"]
        XCTAssertTrue(btn.waitForExistence(timeout: 5))
        btn.tap()
        btn.tap()
        XCTAssertTrue(btn.exists)
    }

    func testAccessibilityElements() {
        let app = XCUIApplication()
        app.launch()
        let ids = ["mainTabView", "missionControlView", "missionControlTab", "cubeLabTab", "telemetryTab", "settingsTab"]
        for id in ids {
            let e = app.otherElements[id]
            XCTAssertTrue(e.waitForExistence(timeout: 3), "Element \(id) should be accessible")
        }
    }
}
