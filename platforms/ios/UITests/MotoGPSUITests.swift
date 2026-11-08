import XCTest

/// Offline UI regression for the map workflow. Live route/SDK service coverage
/// requires a configured phone; demo or fixture responses are not used here.
@MainActor final class MotoGPSUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    func testNoRouteCannotStartNavigationOrDemo() {
        let app = XCUIApplication()
        app.launchArguments = ["--moto-ui-offline", "--moto-reset-gateway"]
        app.launch()
        XCTAssertTrue(app.buttons["open-search"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["primary-navigation-action"].exists)
        XCTAssertFalse(app.buttons["demo-navigation-button"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["active-navigation-panel"].exists)
    }
    func testLargeTextHomeKeepsSearchReachable() {
        let app = XCUIApplication()
        app.launchArguments = ["--moto-ui-offline", "--moto-reset-gateway", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let search = app.buttons["open-search"]
        XCTAssertTrue(search.waitForExistence(timeout: 15)); XCTAssertTrue(search.isHittable)
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "Home accessibility XXXL"
        shot.lifetime = .keepAlways; add(shot)
        search.tap()
        XCTAssertTrue(app.textFields["destination-search-field"].waitForExistence(timeout: 10))
    }
}
