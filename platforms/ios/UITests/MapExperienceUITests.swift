import XCTest

@MainActor final class MapExperienceUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--moto-ui-offline", "--moto-provider-gateway", "--moto-reset-gateway"]
        app.launch(); return app
    }
    func testHomePanelHidesAndRestoresAllShortcuts() {
        let app = launch()
        let search = app.buttons["open-search"]
        XCTAssertTrue(search.waitForExistence(timeout: 15))
        let shortcuts = ["clock", "map", "display", "gearshape"].map { app.buttons["home-shortcut-" + $0] }
        XCTAssertTrue(shortcuts.allSatisfy(\.exists))
        let handle = app.buttons["Sheet Grabber"].firstMatch
        XCTAssertTrue(handle.waitForExistence(timeout: 5))
        let bottom = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: handle.frame.midX, dy: app.frame.height * 0.94))
        handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.1, thenDragTo: bottom)
        let hidden = NSPredicate { _, _ in shortcuts.allSatisfy { !$0.exists } }
        expectation(for: hidden, evaluatedWith: app); waitForExpectations(timeout: 10)
        XCTAssertTrue(search.isHittable); capture(app, "Home collapsed")
        let top = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: handle.frame.midX, dy: app.frame.height * 0.25))
        handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.1, thenDragTo: top)
        XCTAssertTrue(shortcuts[0].waitForExistence(timeout: 10)); XCTAssertTrue(shortcuts.allSatisfy(\.exists))
        capture(app, "Home expanded")
    }
    func testSearchAndDevicePanelsReturnToSameMap() {
        let app = launch()
        XCTAssertTrue(app.buttons["open-search"].waitForExistence(timeout: 15))
        app.buttons["open-search"].tap()
        XCTAssertTrue(app.textFields["destination-search-field"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["primary-navigation-action"].exists)
        capture(app, "Search")
        app.buttons["panel-close"].tap()
        XCTAssertTrue(app.buttons["home-shortcut-display"].waitForExistence(timeout: 5))
        app.buttons["home-shortcut-display"].tap()
        XCTAssertTrue(app.buttons["device-connection-action"].waitForExistence(timeout: 5))
        capture(app, "Device")
        app.buttons["panel-close"].tap()
        XCTAssertTrue(app.buttons["open-search"].waitForExistence(timeout: 5))
    }
    func testDayNightAppearance() {
        let app = launch()
        XCTAssertTrue(app.buttons["open-settings"].waitForExistence(timeout: 15))
        app.buttons["open-settings"].tap()
        let picker = app.segmentedControls["appearance-picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.buttons["白天"].tap(); capture(app, "Settings day")
        picker.buttons["夜间"].tap(); capture(app, "Settings night")
    }
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = name
        attachment.lifetime = .keepAlways; add(attachment)
    }
}
