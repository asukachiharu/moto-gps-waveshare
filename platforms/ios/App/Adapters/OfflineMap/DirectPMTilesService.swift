import DirectMapCore
import Foundation
import MotoNavigationCore

/// Phone-only bounded PMTiles/MVT reader. Returns the existing map wire format;
/// firmware still receives only its local scene window, not vector tile data.
actor DirectPMTilesService {
    private var archive: PMTilesArchive?
    private var source: PMTilesSource?
    private func selectedArchive() async throws -> (PMTilesArchive, PMTilesSource) {
        if let archive, let source { return (archive, source) }
        let candidate = try await PMTilesSource.latest()
        if let archive, let source { return (archive, source) }
        let value = PMTilesArchive(source: candidate); archive = value; source = candidate
        return (value, candidate)
    }
    func load(_ tile: MapTileID) async throws -> Data {
        guard tile.isValid else { throw SurroundingMapError.invalidTile }
        let (archive, source) = try await selectedArchive()
        let id = try DirectMapCore.MapTileID(z: tile.z, x: tile.x, y: tile.y)
        let data = try await archive.tile(id)
        let features = try VectorMapTile.decode(data, tile: id).sorted {
            ($0.kind == 5 ? -1 : Int($0.kind)) > ($1.kind == 5 ? -1 : Int($1.kind))
        }
        var roads: [OfflineMapRoad] = [], buildings: [OfflineMapBuilding] = [], totalNodes = 0
        for feature in features {
            try Task.checkCancellation()
            var geometry = feature.coordinates
            if feature.kind == 5, geometry.first == geometry.last { geometry.removeLast() }
            guard geometry.count >= (feature.kind == 5 ? 3 : 2), geometry.count <= 2048,
                  totalNodes + geometry.count <= 120000, roads.count + buildings.count < 12000 else { continue }
            let points = geometry.map { coordinate -> OfflineMapPointE6 in
                let point = ChinaCoordinateTransform.wgs84ToGCJ02(WGS84Point(longitudeDeg: coordinate.longitude, latitudeDeg: coordinate.latitude))
                return OfflineMapPointE6(latitudeE6: Int32((point.latitudeDeg * 1000000).rounded()), longitudeE6: Int32((point.longitudeDeg * 1000000).rounded()))
            }
            totalNodes += points.count
            if feature.kind == 5 {
                buildings.append(OfflineMapBuilding(osmWayID: nil, name: feature.name.isEmpty ? nil : String(feature.name.prefix(128)), buildingClass: "generic", points: points))
            } else {
                let roadClass: String
                switch feature.kind { case 4: roadClass = "motorway"; case 3: roadClass = "primary"; case 2: roadClass = "secondary"; case 1: roadClass = "residential"; default: roadClass = "other" }
                roads.append(OfflineMapRoad(osmWayID: nil, roadClass: roadClass, points: points))
            }
        }
        let document = MapTileDocument(schemaVersion: 1, coordinateSystem: "GCJ-02", tile: tile, roads: roads, buildings: buildings,
            source: OfflineMapSource(provider: "Protomaps / " + source.key, licence: "ODbL", attributionURL: "https://www.openstreetmap.org/copyright",
                                     retrievedAt: ISO8601DateFormatter().string(from: Date()), bboxWGS84: nil))
        let encoded = try JSONEncoder().encode(document)
        _ = try MapTileDocument.decode(encoded, expectedTile: tile)
        return encoded
    }
}
