import Foundation
import MotoNavigationCore

enum SDKDistrictMapper {
    /// Require an actual administrative boundary. A POI centre is insufficient
    /// for a complete city download. Include every ring and a 5km edge margin.
    static func cities(from data: Data) throws -> [MapCity] {
        guard data.count <= 2_000_000 else { throw SDKConfigurationError.response }
        let values = try JSONDecoder().decode([District].self, from: data)
        guard values.count <= 20 else { throw SDKConfigurationError.response }
        return try values.compactMap { district in
            var west = Double.infinity, east = -Double.infinity
            var south = Double.infinity, north = -Double.infinity, count = 0
            for ring in district.polylines {
                for pair in ring.split(separator: ";") {
                    let parts = pair.split(separator: ",")
                    guard parts.count == 2, let x = Double(parts[0]), let y = Double(parts[1]),
                          x.isFinite, y.isFinite, abs(x) <= 180, abs(y) <= 85 else { throw SDKConfigurationError.response }
                    count += 1
                    guard count <= 100_000 else { throw SDKConfigurationError.response }
                    let point = ChinaCoordinateTransform.gcj02ToWGS84(GCJ02Point(longitudeDeg: x, latitudeDeg: y))
                    west = min(west, point.longitudeDeg); east = max(east, point.longitudeDeg)
                    south = min(south, point.latitudeDeg); north = max(north, point.latitudeDeg)
                }
            }
            guard count >= 3, west < east, south < north else { return nil }
            let dy = 5000.0 / 111195
            let dx = dy / max(0.01, cos((south + north) / 2 * .pi / 180))
            return MapCity(id: district.id, name: String(district.name.prefix(120)), detail: "行政边界及周边 5 公里",
                boundsWGS84: [max(-180, west - dx), max(-85, south - dy), min(180, east + dx), min(85, north + dy)])
        }
    }
    private struct District: Decodable { let id, name, level: String; let polylines: [String] }
}
