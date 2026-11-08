import Foundation
import XCTest
@testable import MOTO_GPS

final class SDKRouteMapperTests: XCTestCase {
    private func response(polyline: String = "0,0;0.001,0", stepDistance: Int = 100) throws -> Data {
        try JSONSerialization.data(withJSONObject: [["distance": 100, "duration": 60, "steps": [
            ["distance": stepDistance, "polyline": polyline, "road": "test", "instruction": "左转",
             "action": "左转", "assistant": "", "traffic": [["distance": 100, "status": "未知"]]]
        ]]])
    }
    func testActualSDKStepTurnOccursAtItsEndAndUnknownTrafficStaysUnknown() throws {
        let routes = try SDKRouteMapper.routes(from: response(), generatedAtMs: 1234)
        XCTAssertEqual(routes.count, 1)
        XCTAssertEqual(routes[0].maneuvers.first?.routeOffsetM, 100)
        XCTAssertEqual(routes[0].maneuvers.first?.type, .left)
        XCTAssertEqual(routes[0].traffic.first?.level, .unknown)
        XCTAssertEqual(routes[0].provider, "amap-ios-sdk")
        XCTAssertEqual(routes[0].generatedAtMs, 1234)
    }
    func testIncompleteAndOversizedStepGeometryIsRejected() throws {
        XCTAssertThrowsError(try SDKRouteMapper.routes(from: response(polyline: "")))
        XCTAssertThrowsError(try SDKRouteMapper.routes(from: response(polyline: "nan,0;0,0")))
        XCTAssertThrowsError(try SDKRouteMapper.routes(from: response(stepDistance: 101)))
    }
    func testCityBoundaryIncludesEveryIslandAndRejectsInvalidGeometry() throws {
        let data = try JSONSerialization.data(withJSONObject: [["id": "test", "name": "test", "level": "city",
            "polylines": ["0,0;0.01,0;0,0.01", "0.1,0.1;0.11,0.1;0.1,0.11"]]])
        let bounds = try XCTUnwrap(SDKDistrictMapper.cities(from: data).first?.boundsWGS84)
        XCTAssertLessThan(bounds[0], 0); XCTAssertLessThan(bounds[1], 0)
        XCTAssertGreaterThan(bounds[2], 0.11); XCTAssertGreaterThan(bounds[3], 0.11)
        XCTAssertThrowsError(try SDKDistrictMapper.cities(from: Data("[{\"id\":\"x\",\"name\":\"x\",\"level\":\"city\",\"polylines\":[\"nan,0\"]}]".utf8)))
    }
}
