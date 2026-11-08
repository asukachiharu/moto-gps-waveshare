import Foundation

public struct PMTilesHeader: Sendable {
    public let rootOffset: UInt64,rootLength: UInt64,leafOffset: UInt64,leafLength: UInt64,tileOffset: UInt64,tileLength: UInt64
    public let internalCompression: UInt8,tileCompression: UInt8,minZoom: Int,maxZoom: Int
    public init(_ data: Data) throws {
        let b=Array(data)
        guard b.count>=127,Array(b.prefix(7))==Array("PMTiles".utf8),b[7]==3,b[99]==1,
              [1,2].contains(b[97]),[1,2].contains(b[98]),b[100]<=b[101],b[101]<=22 else { throw MapFailure.invalid("不是支持的 PMTiles 3 矢量地图") }
        func u64(_ p: Int)->UInt64 { (0..<8).reduce(0) { $0 | UInt64(b[p+$1]) << ($1*8) } }
        rootOffset=u64(8);rootLength=u64(16);leafOffset=u64(40);leafLength=u64(48);tileOffset=u64(56);tileLength=u64(64)
        internalCompression=b[97];tileCompression=b[98];minZoom=Int(b[100]);maxZoom=Int(b[101])
        guard rootOffset>=127,rootLength>0,rootLength<=16257,rootOffset<=16384-rootLength,
              leafOffset<=UInt64.max-leafLength,tileOffset<=UInt64.max-tileLength,tileLength>0 else { throw MapFailure.invalid("地图索引范围损坏") }
        // Streaming writers may append metadata and leaves AFTER tile data.
        // The offsets are authoritative; validate non-overlap without imposing
        // the illustrative section order from the format documentation.
        let metadataOffset=u64(24),metadataLength=u64(32)
        guard metadataOffset<=UInt64.max-metadataLength else {throw MapFailure.invalid("地图元数据溢出")}
        let sections=[(rootOffset,rootLength),(metadataOffset,metadataLength),(leafOffset,leafLength),(tileOffset,tileLength)]
            .filter{$0.1>0}.sorted{$0.0<$1.0}
        var end:UInt64=127
        for (offset,length) in sections {
            guard offset>=end else {throw MapFailure.invalid("地图数据段重叠")};end=offset+length
        }
    }
}

public struct PMTilesEntry: Sendable, Equatable {
    public let tileID: UInt64,offset: UInt64,length: UInt64,runLength: UInt64
}
public enum PMTilesDirectory {
    public static func decode(_ data: Data) throws -> [PMTilesEntry] {
        guard data.count<=2_000_000 else { throw MapFailure.invalid("地图索引过大") }
        var r=MapBinaryReader(data);let n=try r.varint()
        guard n>0,n<=100_000 else { throw MapFailure.invalid("地图索引数量无效") }
        var ids:[UInt64]=[],runs:[UInt64]=[],lengths:[UInt64]=[],last:UInt64=0
        for i in 0..<n {
            let delta=try r.varint();guard delta<=UInt64.max-last,i==0 || delta>0 else { throw MapFailure.invalid("地图索引顺序无效") }
            last+=delta;ids.append(last)
        }
        for _ in 0..<n { runs.append(try r.varint()) }
        for _ in 0..<n { let size=try r.varint();guard size>0,size<=2_000_000 else { throw MapFailure.invalid("瓦片长度超限") };lengths.append(size) }
        var entries:[PMTilesEntry]=[],end:UInt64=0
        for i in 0..<Int(n) {
            let raw=try r.varint();guard raw>0 || i>0 else { throw MapFailure.invalid("地图偏移无效") }
            let offset=raw==0 ? end:raw-1
            guard offset<=UInt64.max-lengths[i],runs[i]<=UInt64.max-ids[i] else { throw MapFailure.invalid("地图偏移溢出") }
            end=offset+lengths[i];entries.append(PMTilesEntry(tileID:ids[i],offset:offset,length:lengths[i],runLength:runs[i]))
        }
        guard r.finished else { throw MapFailure.invalid("地图索引有多余数据") };return entries
    }
    public static func find(_ id: UInt64,in entries: [PMTilesEntry]) -> PMTilesEntry? {
        var lo=0,hi=entries.count
        while lo<hi { let mid=(lo+hi)/2;if entries[mid].tileID<=id {lo=mid+1}else{hi=mid} }
        guard lo>0 else {return nil};let e=entries[lo-1]
        return e.runLength==0 || id-e.tileID<e.runLength ? e:nil
    }
}
