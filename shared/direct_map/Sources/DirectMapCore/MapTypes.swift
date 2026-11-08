import Foundation

public struct Coordinate: Codable, Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public init(latitude: Double, longitude: Double) { self.latitude = latitude; self.longitude = longitude }
    public var isValid: Bool { latitude.isFinite && longitude.isFinite && (-90...90).contains(latitude) && (-180...180).contains(longitude) }
}
public enum MapFailure: LocalizedError {
    case invalid(String)
    public var errorDescription: String? { switch self { case let .invalid(message): message } }
}
