import Foundation
import MotoNavigationCore

/// Bounded conversion of official SDK response values, never synthetic routes.
enum SDKRouteMapper {
    static func routes(from data: Data, generatedAtMs: UInt64 = UInt64(Date.now.timeIntervalSince1970 * 1000)) throws -> [RoutePlan] {
        guard data.count <= 2_000_000 else { throw SDKConfigurationError.response }
        let paths = try JSONDecoder().decode([Path].self, from: data)
        guard !paths.isEmpty, paths.count <= 3 else { throw SDKConfigurationError.response }
        return try paths.map { path in
            guard path.distance.isFinite, path.distance > 0, path.distance <= 10_000_000, path.duration > 0, path.duration <= 604800,
                  !path.steps.isEmpty, path.steps.count <= 4096 else { throw SDKConfigurationError.response }
            var points: [GCJ02Point] = [], maneuvers: [RouteManeuver] = [], traffic: [TrafficSegment] = []
            var offset = 0.0
            for (index, step) in path.steps.enumerated() {
                guard step.distance.isFinite, step.distance >= 0, step.distance <= path.distance, step.polyline.utf8.count <= 1_500_000 else { throw SDKConfigurationError.response }
                var geometry: [GCJ02Point] = []
                for pair in step.polyline.split(separator: ";") {
                    let parts = pair.split(separator: ",")
                    guard parts.count == 2, let x = Double(parts[0]), let y = Double(parts[1]),
                          x.isFinite, y.isFinite, (-180...180).contains(x), (-90...90).contains(y) else { throw SDKConfigurationError.response }
                    geometry.append(GCJ02Point(longitudeDeg: x, latitudeDeg: y))
                    guard geometry.count <= 50000 else { throw SDKConfigurationError.response }
                }
                guard step.distance == 0 || geometry.count >= 2 else { throw SDKConfigurationError.response }
                for point in geometry where points.last != point { points.append(point) }
                guard points.count <= 50000 else { throw SDKConfigurationError.response }
                // AMap action occurs after traversing the step, matching the
                // existing gateway transformer and the shared NavCore contract.
                maneuvers.append(RouteManeuver(id: UInt32(index + 1), type: maneuver(step.action + step.assistant),
                    routeOffsetM: min(path.distance, offset + step.distance), roadName: String(step.road.prefix(32)),
                    instruction: String(step.instruction.prefix(80))))
                var trafficOffset = offset
                guard step.traffic.count <= 4096 else { throw SDKConfigurationError.response }
                for tmc in step.traffic {
                    guard tmc.distance.isFinite, tmc.distance >= 0 else { throw SDKConfigurationError.response }
                    let end = min(offset + step.distance, trafficOffset + tmc.distance)
                    if end > trafficOffset {
                        traffic.append(TrafficSegment(startOffsetM: trafficOffset, endOffsetM: end, level: level(tmc.status)))
                    }
                    guard traffic.count <= 4096 else { throw SDKConfigurationError.response }
                    trafficOffset = end
                }
                offset += step.distance
                guard offset.isFinite, offset <= path.distance + 100 else { throw SDKConfigurationError.response }
            }
            guard points.count >= 2 else { throw SDKConfigurationError.response }
            return RoutePlan(routeID: "sdk-" + UUID().uuidString, provider: "amap-ios-sdk", generatedAtMs: generatedAtMs,
                totalDistanceM: path.distance, totalDurationS: path.duration, polyline: points, maneuvers: maneuvers, traffic: traffic)
        }
    }
    private static func maneuver(_ action: String) -> ManeuverType {
        if action.contains("到达") { return .arrive }
        if action.contains("环岛") { return .roundabout }
        if action.contains("掉头") { return .uTurnLeft }
        if action.contains("左") { return action.contains("靠") || action.contains("斜") ? .slightLeft : .left }
        if action.contains("右") { return action.contains("靠") || action.contains("斜") ? .slightRight : .right }
        if action.contains("直行") { return .continue }
        return .unknown
    }
    private static func level(_ status: String) -> TrafficLevel {
        switch status {
        case "畅通": .freeFlow
        case "缓行": .slow
        case "拥堵": .congested
        case "严重拥堵": .severe
        default: .unknown
        }
    }
    private struct Path: Decodable {
        let distance: Double
        let duration: Int
        let steps: [Step]
    }
    private struct Step: Decodable {
        let distance: Double
        let polyline, road, instruction, action, assistant: String
        let traffic: [TMC]
    }
    private struct TMC: Decodable { let distance: Double; let status: String }
}
