import XCTest

final class GatewaySettingsUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testSaveGatewayPersistsAcrossLaunches() {
        let app = XCUIApplication()
        app.launchArguments = ["--moto-ui-offline", "--moto-provider-gateway", "--moto-reset-gateway"]
        app.launch()
        let setup = app.buttons["gateway-setup-button"]
        XCTAssertTrue(setup.waitForExistence(timeout: 10))
        setup.tap()
        app.buttons["gateway-settings-link"].tap()
        let field = app.textFields["gateway-address-field"].exists
            ? app.textFields["gateway-address-field"] : app.textViews["gateway-address-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("https://nav.example.com/moto-gps/api")
        keepScreenshot(app, "Gateway address entry")
        app.buttons["gateway-save-button"].tap()
        app.buttons["panel-close"].tap()
        XCTAssertTrue(app.buttons["open-search"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["gateway-setup-button"].exists)
        app.terminate()
        app.launchArguments = ["--moto-ui-offline", "--moto-provider-gateway"]
        app.launch()
        let settings = app.buttons["open-settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()
        app.buttons["gateway-settings-link"].tap()
        let saved = app.descendants(matching: .any).matching(identifier: "gateway-address-field").firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 5))
        XCTAssertEqual(saved.value as? String, "https://nav.example.com/moto-gps/api/")
        keepScreenshot(app, "Saved gateway settings")
    }

    func testInvalidAddressStaysInSettingsAndExplainsError() {
        let app = XCUIApplication()
        app.launchArguments = ["--moto-ui-offline", "--moto-provider-gateway", "--moto-reset-gateway"]
        app.launch()
        let setup = app.buttons["gateway-setup-button"]
        XCTAssertTrue(setup.waitForExistence(timeout: 10))
        setup.tap()
        app.buttons["gateway-settings-link"].tap()
        let field = app.descendants(matching: .any).matching(identifier: "gateway-address-field").firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("http://nav.example.com")
        app.buttons["gateway-save-button"].tap()
        let error = app.staticTexts["gateway-status-message"]
        XCTAssertTrue(error.waitForExistence(timeout: 5))
        XCTAssertTrue(error.label.contains("HTTPS"))
        keepScreenshot(app, "Invalid gateway address")
    }

    private func keepScreenshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
