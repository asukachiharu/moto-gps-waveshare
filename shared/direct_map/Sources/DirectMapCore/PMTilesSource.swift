import Foundation

public struct PMTilesSource: Codable, Equatable, Sendable {
    public let key: String
    public let url: URL
    public init(key: String,url: URL) throws {
        guard (1...80).contains(key.utf8.count),key.allSatisfy({$0.isASCII && ($0.isLetter || $0.isNumber || "-_.".contains($0))}),
              url.scheme=="https",url.host != nil,url.user==nil,url.password==nil,url.query==nil,url.fragment==nil else { throw MapFailure.invalid("地图源必须是 HTTPS PMTiles 静态文件") }
        self.key=key;self.url=url
    }
    public static func latest() async throws -> PMTilesSource {
        var request=URLRequest(url:URL(string:"https://build-metadata.protomaps.dev/builds.json")!)
        request.timeoutInterval=20
        request.setValue("https://maps.protomaps.com/",forHTTPHeaderField:"Referer")
        request.setValue("MotoNav/0.5 (personal offline basemap)",forHTTPHeaderField:"User-Agent")
        let data=try await MapHTTP.read(request,limit:2_000_000,status:200)
        struct Build: Decodable {let key: String;let version: String}
        let builds=try JSONDecoder().decode([Build].self,from:data)
        let keys=builds.filter {$0.version.hasPrefix("4.") && $0.key.range(of:"^[0-9]{8}\\.pmtiles$",options:.regularExpression) != nil}.map(\.key)
        guard let key=keys.max() else {throw MapFailure.invalid("暂时没有兼容的 Protomaps 地图版本")}
        return try PMTilesSource(key:key,url:URL(string:"https://build.protomaps.com/"+key)!)
    }
}
