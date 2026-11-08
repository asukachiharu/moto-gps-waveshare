import Foundation
import MotoNavigationCore

enum NavigationSourceMode: String, CaseIterable, Identifiable, Sendable {
    case sdk, gateway
    var id: String { rawValue }
    var title: String { self == .sdk ? "高德 iOS SDK" : "自建网关" }
}

/// A route session captures one immutable provider. Switching modes cannot mix
/// replies or change the provider of an already-running navigation runtime.
final class NavigationProviderRouter: NavigationRouteProviding, @unchecked Sendable {
    let mode: NavigationSourceMode
    private let sdk: AMapSDKNavigationService
    private let gatewayRoutes: AmapGatewayRouteProvider
    private let gatewayPlaces: AmapGatewayPlaceProvider
    init(mode: NavigationSourceMode, baseURL: URL, sdk: AMapSDKNavigationService) {
        self.mode = mode; self.sdk = sdk
        gatewayRoutes = AmapGatewayRouteProvider(baseURL: baseURL)
        gatewayPlaces = AmapGatewayPlaceProvider(baseURL: baseURL)
    }
    func route(for request: RouteRequest) async throws -> RouteEnvelope {
        if mode == .sdk { return try await sdk.route(for: request) }
        return try await gatewayRoutes.route(for: request)
    }
    func routeOptions(for request: RouteRequest) async throws -> [RoutePlan] {
        if mode == .sdk { return try await sdk.routeOptions(for: request) }
        return try await gatewayRoutes.routeOptions(for: request)
    }
    func search(keywords: String, near origin: WGS84Point?) async throws -> [PlaceSearchResult] {
        if mode == .sdk { return try await sdk.search(keywords: keywords, near: origin) }
        return try await gatewayPlaces.search(keywords: keywords, near: origin)
    }
}
