import XCTest

@MainActor final class SDKSettingsUITests: XCTestCase {
    func testRuntimeKeyEntryRejectsInvalidKeyWithoutStartingNavigation() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--moto-ui-offline", "-MotoGPS.NavigationSource", "sdk"]
        app.launch()
        XCTAssertTrue(app.buttons["open-settings"].waitForExistence(timeout: 15))
        app.buttons["open-settings"].tap()
        let key = app.secureTextFields["amap-key-input"]
        XCTAssertTrue(key.waitForExistence(timeout: 5))
        key.tap(); key.typeText("invalid")
        app.buttons["amap-key-save"].tap()
        let message = app.staticTexts["navigation-settings-message"]
        XCTAssertTrue(message.waitForExistence(timeout: 5))
        XCTAssertTrue(message.label.contains("Key 格式不正确"))
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "SDK runtime key settings"; image.lifetime = .keepAlways; add(image)
        XCTAssertFalse(app.buttons["primary-navigation-action"].exists)
    }
}
