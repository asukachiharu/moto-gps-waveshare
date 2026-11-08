import Foundation
import MapCompression

public enum MapBinary {
    public static func decompress(_ data: Data, compression: UInt8, limit: Int = 2_000_000) throws -> Data {
        guard data.count <= limit, limit > 0, limit <= 4_000_000 else { throw MapFailure.invalid("地图数据过大") }
        if compression == 1 { return data }
        guard compression == 2, !data.isEmpty else { throw MapFailure.invalid("不支持的地图压缩格式") }
        var output = Data(count: limit), count = 0
        let result = output.withUnsafeMutableBytes { destination in
            data.withUnsafeBytes { source in
                mn_map_gunzip(source.bindMemory(to: UInt8.self).baseAddress, data.count,
                    destination.bindMemory(to: UInt8.self).baseAddress, limit, &count)
            }
        }
        guard result == 0 else { throw MapFailure.invalid("地图压缩数据损坏或超限") }
        output.count = count; return output
    }
}

struct MapBinaryReader {
    let bytes: [UInt8]
    var position = 0
    init(_ data: Data) { bytes = Array(data) }
    var finished: Bool { position == bytes.count }
    mutating func varint() throws -> UInt64 {
        var value: UInt64 = 0
        for shift in stride(from: 0, through: 63, by: 7) {
            guard position < bytes.count else { throw MapFailure.invalid("地图数据截断") }
            let byte = bytes[position]; position += 1
            guard shift < 63 || byte <= 1 else { throw MapFailure.invalid("地图整数溢出") }
            value |= UInt64(byte & 127) << shift
            if byte < 128 { return value }
        }
        throw MapFailure.invalid("地图整数损坏")
    }
    mutating func data(count: Int) throws -> Data {
        guard count >= 0, count <= bytes.count-position else { throw MapFailure.invalid("地图数据截断") }
        defer { position += count }; return Data(bytes[position..<(position+count)])
    }
    mutating func field() throws -> (Int,UInt8) {
        let tag = try varint()
        guard tag >> 3 > 0, tag >> 3 <= UInt64(Int32.max) else { throw MapFailure.invalid("地图字段无效") }
        return (Int(tag >> 3),UInt8(tag & 7))
    }
    mutating func blob() throws -> Data {
        let count = try varint(); guard count <= 2_000_000 else { throw MapFailure.invalid("地图字段过大") }
        return try data(count: Int(count))
    }
    mutating func skip(_ wire: UInt8) throws {
        switch wire { case 0: _ = try varint(); case 1: _ = try data(count: 8)
        case 2: _ = try blob(); case 5: _ = try data(count: 4)
        default: throw MapFailure.invalid("地图字段类型无效") }
    }
}
