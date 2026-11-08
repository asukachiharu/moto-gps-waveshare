import Foundation

enum MapHTTP {
    static func read(_ request: URLRequest,limit: Int,status: Int,range: (UInt64,UInt64)?=nil) async throws -> Data {
        try await response(request,limit:limit,status:status,range:range).0
    }
    static func response(_ request:URLRequest,limit:Int,status:Int,range:(UInt64,UInt64)?=nil) async throws -> (Data,String?) {
        let (stream,response)=try await URLSession.shared.bytes(for:request)
        guard let http=response as? HTTPURLResponse,http.statusCode==status,response.expectedContentLength<=limit else { throw MapFailure.invalid("地图下载失败，请检查网络或地图源") }
        if let range {
            let expected="bytes \(range.0)-\(range.0+range.1-1)/"
            guard http.value(forHTTPHeaderField:"Content-Range")?.hasPrefix(expected)==true,
                  response.expectedContentLength<0 || response.expectedContentLength==Int64(range.1),
                  [nil,"identity"].contains(http.value(forHTTPHeaderField:"Content-Encoding")) else {throw MapFailure.invalid("地图源未正确支持分段下载")}
        }
        var data=Data();data.reserveCapacity(min(limit,64_000))
        for try await byte in stream {try Task.checkCancellation();guard data.count<limit else {throw MapFailure.invalid("地图响应超限")};data.append(byte)}
        if let range, data.count != Int(range.1) {throw MapFailure.invalid("地图分段下载不完整")}
        return (data,http.value(forHTTPHeaderField:"ETag"))
    }
}

public struct MapTileRange: Codable,Sendable {
    public let tile: MapTileID
    public let offset: UInt64
    public let length: UInt64
}

/// Reads only indexed HTTP ranges, never the world archive. A source is immutable
/// and pinned by date for the lifetime of an offline pack.
public actor PMTilesArchive {
    public let source: PMTilesSource
    private var header: PMTilesHeader?
    private var root:[PMTilesEntry]=[]
    private var leaves:[UInt64:[PMTilesEntry]]=[:]
    private var etag:String?
    public init(source: PMTilesSource,entityTag:String?=nil){self.source=source;self.etag=entityTag}
    private func range(_ offset: UInt64,_ length: UInt64) async throws -> Data {
        _ = try PMTilesSource(key:source.key,url:source.url)
        if let etag {guard etag.utf8.count<=512,!etag.contains("\n"),!etag.contains("\r") else {throw MapFailure.invalid("地图版本标识无效")}}
        guard length>0,length<=2_000_000,offset<=UInt64.max-length else {throw MapFailure.invalid("地图请求范围无效")}
        var request=URLRequest(url:source.url,cachePolicy:.reloadIgnoringLocalCacheData,timeoutInterval:30)
        request.setValue("bytes=\(offset)-\(offset+length-1)",forHTTPHeaderField:"Range")
        request.setValue("identity",forHTTPHeaderField:"Accept-Encoding")
        request.setValue("MotoNav/0.5",forHTTPHeaderField:"User-Agent")
        if let etag {request.setValue(etag,forHTTPHeaderField:"If-Match")}
        let (data,received)=try await MapHTTP.response(request,limit:Int(length),status:206,range:(offset,length))
        if let etag,received != etag {throw MapFailure.invalid("地图源已变化，请重新检查更新")}
        if etag==nil {etag=received};return data
    }
    private func load() async throws -> PMTilesHeader {
        if let header {return header}
        let prefix=try await range(0,16384),h=try PMTilesHeader(prefix)
        let compressed=prefix.subdata(in:Int(h.rootOffset)..<Int(h.rootOffset+h.rootLength))
        root=try PMTilesDirectory.decode(MapBinary.decompress(compressed,compression:h.internalCompression))
        header=h;return h
    }
    public func locate(_ tile: MapTileID) async throws -> MapTileRange {
        let h=try await load()
        guard (h.minZoom...h.maxZoom).contains(tile.z) else {throw MapFailure.invalid("地图缺少所需详细级别")}
        var entries=root
        for _ in 0..<4 {
            guard let e=PMTilesDirectory.find(tile.id,in:entries) else {return MapTileRange(tile:tile,offset:0,length:0)}
            if e.runLength>0 {
                guard e.offset<=h.tileLength,e.length<=h.tileLength-e.offset else {throw MapFailure.invalid("瓦片索引越界")}
                return MapTileRange(tile:tile,offset:h.tileOffset+e.offset,length:e.length)
            }
            guard e.offset<=h.leafLength,e.length<=h.leafLength-e.offset else {throw MapFailure.invalid("子索引越界")}
            if let cached=leaves[e.offset] {entries=cached}
            else {
                let bytes=try await range(h.leafOffset+e.offset,e.length)
                entries=try PMTilesDirectory.decode(MapBinary.decompress(bytes,compression:h.internalCompression))
                if leaves.count>=24 {leaves.removeAll(keepingCapacity:true)};leaves[e.offset]=entries
            }
        }
        throw MapFailure.invalid("地图索引层数过多")
    }
    public func compressedTile(_ item: MapTileRange) async throws -> Data {
        if item.length==0 {return Data()}
        let h=try await load()
        guard item.offset>=h.tileOffset,item.offset<=h.tileOffset+h.tileLength,item.length<=h.tileOffset+h.tileLength-item.offset else {throw MapFailure.invalid("离线瓦片范围无效")}
        return try await range(item.offset,item.length)
    }
    public func compressedTiles(_ items:[MapTileRange]) async throws -> [MapTileID:Data] {
        guard !items.isEmpty,items.count<=128,Set(items.map(\.tile)).count==items.count,
              items.allSatisfy({$0.length<=2_000_000 && $0.offset<=UInt64.max-$0.length}) else {throw MapFailure.invalid("离线下载批次超限")}
        let nonempty=items.filter{$0.length>0}
        var result=Dictionary(uniqueKeysWithValues:items.filter{$0.length==0}.map{($0.tile,Data())})
        guard let start=nonempty.map(\.offset).min(),let end=nonempty.map({$0.offset+$0.length}).max() else {return result}
        let h=try await load()
        guard start>=h.tileOffset,end<=h.tileOffset+h.tileLength,end>=start,end-start<=2_000_000 else {throw MapFailure.invalid("离线下载批次范围无效")}
        let data=try await range(start,end-start)
        for item in nonempty {result[item.tile]=data.subdata(in:Int(item.offset-start)..<Int(item.offset-start+item.length))}
        return result
    }
    public func tile(_ tile: MapTileID) async throws -> Data {
        let h=try await load(),item=try await locate(tile)
        let data=try await compressedTile(item)
        return data.isEmpty ? data:try MapBinary.decompress(data,compression:h.tileCompression)
    }
    public func compression() async throws -> UInt8 {try await load().tileCompression}
    public func entityTag() async throws -> String? {_ = try await load();return etag}
}
