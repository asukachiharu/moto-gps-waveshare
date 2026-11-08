import XCTest
@testable import DirectMapCore

final class DirectMapCoreTests: XCTestCase {
    func testPublicBeijingTileContainsRealRoadsAndBuildings() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "beijing-z15.mvt", withExtension: "gz", subdirectory: "Fixtures"))
        let compressed = try Data(contentsOf: url)
        let data = try MapBinary.decompress(compressed, compression: 2)
        let tile = try MapTileID.containing(Coordinate(latitude: 39.9042, longitude: 116.4074))
        let features = try VectorMapTile.decode(data, tile: tile)
        XCTAssertTrue(features.contains { $0.kind == 5 }); XCTAssertTrue(features.contains { $0.kind < 5 })
        XCTAssertTrue(features.flatMap(\.coordinates).allSatisfy(\.isValid))
    }
    func testCorruptVectorAndCompressedDataAreRejected() throws {
        let tile = try MapTileID(z: 15, x: 0, y: 0)
        XCTAssertThrowsError(try VectorMapTile.decode(Data([0x1a, 0xff]), tile: tile))
        XCTAssertThrowsError(try MapBinary.decompress(Data([0, 1, 2]), compression: 2))
    }
    func testInvalidTilesAndOversizedRegionsAreRejected() throws {
        XCTAssertThrowsError(try MapTileID(z: 15, x: 32768, y: 0))
        XCTAssertThrowsError(try MapRegion(south: -80, north: 80, west: -170, east: 170).tiles(limit: 100000))
    }
}
