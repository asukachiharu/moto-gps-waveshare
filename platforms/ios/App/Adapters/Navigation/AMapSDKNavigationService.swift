import Foundation
import MotoNavigationCore

/// The official SDK supplies search and complete routes. The upstream shared
/// NavCore remains authoritative for GNSS matching, instructions and BLE output.
/// This is not AMapNaviDriveManager guidance or its internal voice engine.
@MainActor final class AMapSDKNavigationService {
    private var initializedKey: String?
    private var bridge: MNSearchSDKBridge?
    private let keys = AMapKeyStore(ephemeral: ProcessInfo.processInfo.arguments.contains("--moto-ui-offline"))
    private(set) var requiresRestart = false
    var hasKey: Bool { keys.load() != nil }
    var consent: Bool { UserDefaults.standard.bool(forKey: "MotoGPS.SDKPrivacyConsent") }
    var isConfigured: Bool { MNSearchSDKBridge.available && hasKey && consent && !requiresRestart }
    func save(key: String, consent: Bool) throws {
        if !key.isEmpty {
            let changed = keys.load() != key
            try keys.save(key)
            if changed && initializedKey != nil { requiresRestart = true }
        }
        UserDefaults.standard.set(consent, forKey: "MotoGPS.SDKPrivacyConsent")
        if !consent { bridge?.invalidate(); bridge = nil }
    }
    private func client() throws -> MNSearchSDKBridge {
        guard MNSearchSDKBridge.available else { throw SDKConfigurationError.unavailable }
        guard consent, let key = keys.load(), !requiresRestart else { throw SDKConfigurationError.configuration }
        if let bridge { return bridge }
        let value = MNSearchSDKBridge(apiKey: key); bridge = value; initializedKey = key; return value
    }
    func search(keywords: String, near origin: WGS84Point?) async throws -> [PlaceSearchResult] {
        try Task.checkCancellation()
        let client = try client()
        let data: Data = try await withCheckedThrowingContinuation { continuation in
            client.search(keywords: String(keywords.prefix(128)), longitude: origin?.longitudeDeg ?? .nan,
                          latitude: origin?.latitudeDeg ?? .nan) { data, error in
                if let data { continuation.resume(returning: data) }
                else { continuation.resume(throwing: error ?? SDKConfigurationError.response) }
            }
        }
        try Task.checkCancellation()
        let places = try JSONDecoder().decode([SDKPlace].self, from: data)
        guard places.count <= 20 else { throw SDKConfigurationError.response }
        return places.compactMap { place in
            guard place.longitude.isFinite, place.latitude.isFinite,
                  (-180...180).contains(place.longitude), (-90...90).contains(place.latitude) else { return nil }
            let point = ChinaCoordinateTransform.gcj02ToWGS84(GCJ02Point(longitudeDeg: place.longitude, latitudeDeg: place.latitude))
            return PlaceSearchResult(id: place.id, name: place.name, address: place.address,
                city: place.city, district: place.district, displayArea: place.city + place.district,
                location: point, distanceM: nil)
        }
    }
    func route(for request: RouteRequest) async throws -> RouteEnvelope {
        guard let first = try await routeOptions(for: request).first else { throw SDKConfigurationError.response }
        return RouteEnvelope(requestID: request.requestID, route: first)
    }
    func searchCities(_ keywords: String) async throws -> [MapCity] {
        try Task.checkCancellation()
        let client = try client()
        let data: Data = try await withCheckedThrowingContinuation { continuation in
            client.districts(keywords: String(keywords.prefix(80))) { data, error in
                if let data { continuation.resume(returning: data) }
                else { continuation.resume(throwing: error ?? SDKConfigurationError.response) }
            }
        }
        try Task.checkCancellation()
        return try SDKDistrictMapper.cities(from: data)
    }
    func routeOptions(for request: RouteRequest) async throws -> [RoutePlan] {
        guard request.origin.isValid, request.destination.isValid else { throw SDKConfigurationError.response }
        try Task.checkCancellation()
        let client = try client()
        let data: Data = try await withCheckedThrowingContinuation { continuation in
            client.routes(originLongitude: request.origin.longitudeDeg, originLatitude: request.origin.latitudeDeg,
                          destinationLongitude: request.destination.longitudeDeg, destinationLatitude: request.destination.latitudeDeg) { data, error in
                if let data { continuation.resume(returning: data) }
                else { continuation.resume(throwing: error ?? SDKConfigurationError.response) }
            }
        }
        try Task.checkCancellation()
        return try SDKRouteMapper.routes(from: data)
    }
}

private struct SDKPlace: Decodable {
    let id, name, address, city, district: String
    let longitude, latitude: Double
}

enum SDKConfigurationError: LocalizedError {
    case unavailable, configuration, response
    var errorDescription: String? {
        switch self {
        case .unavailable: "模拟器不包含高德设备 SDK，请在 iPhone 上使用或选择网关模式。"
        case .configuration: "请先配置高德 iOS Key 并同意隐私说明；修改已启用的 Key 后需要重新打开 App。"
        case .response: "高德未返回完整可用的路线或地点。"
        }
    }
}
