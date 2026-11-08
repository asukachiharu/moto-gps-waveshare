import Foundation

public struct GeographicMapFeature: Sendable {
    public let id: UInt64
    public let kind: UInt8
    public let name: String
    public var coordinates: [Coordinate]
    public init(id:UInt64,kind:UInt8,name:String,coordinates:[Coordinate]) {self.id=id;self.kind=kind;self.name=name;self.coordinates=coordinates}
}

/// The public Mapbox Vector Tile protobuf format, using Protomaps roads/buildings.
/// Parsing and geometry budgets apply before allocation and before BLE reduction.
public enum VectorMapTile {
    public static func decode(_ data:Data,tile:MapTileID) throws -> [GeographicMapFeature] {
        if data.isEmpty {return []}
        guard data.count<=2_000_000 else {throw MapFailure.invalid("矢量瓦片过大")}
        var reader=MapBinaryReader(data),layers=0,output:[GeographicMapFeature]=[],budget=120_000
        while !reader.finished {
            let (field,wire)=try reader.field()
            if field==3 && wire==2 {
                layers+=1;guard layers<=32 else {throw MapFailure.invalid("地图图层过多")}
                output += try layer(reader.blob(),tile:tile,budget:&budget)
            } else {try reader.skip(wire)}
        }
        return output
    }
    private static func string(_ data:Data,limit:Int=512) throws -> String {
        guard data.count<=limit,let text=String(data:data,encoding:.utf8),!text.contains("\0") else {throw MapFailure.invalid("地图文字无效")};return text
    }
    private static func layer(_ data:Data,tile:MapTileID,budget:inout Int) throws -> [GeographicMapFeature] {
        var r=MapBinaryReader(data),name="",extent:UInt64=4096,version:UInt64=1
        var features:[Data]=[],keys:[String]=[],values:[String]=[]
        while !r.finished {
            let (f,w)=try r.field()
            switch (f,w) {
            case (1,2): name=try string(r.blob(),limit:64)
            case (2,2): guard features.count<20_000 else {throw MapFailure.invalid("地图要素过多")};features.append(try r.blob())
            case (3,2): guard keys.count<4096 else {throw MapFailure.invalid("地图属性过多")};keys.append(try string(r.blob()))
            case (4,2):
                guard values.count<16_384 else {throw MapFailure.invalid("地图属性过多")}
                var v=MapBinaryReader(try r.blob()),text=""
                while !v.finished {let (a,b)=try v.field();if a==1 && b==2 {text=try string(v.blob())}else{try v.skip(b)}}
                values.append(text)
            case (5,0): extent=try r.varint()
            case (15,0): version=try r.varint()
            default: try r.skip(w)
            }
        }
        guard extent>0,extent<=65536,(1...2).contains(version) else {throw MapFailure.invalid("矢量图层格式无效")}
        guard name=="roads" || name=="buildings" else {return []}
        var result:[GeographicMapFeature]=[]
        for (index,bytes) in features.enumerated() {
            var feature=MapBinaryReader(bytes),id=UInt64(index+1),type:UInt64=0,tags:[UInt64]=[],geometry=Data()
            while !feature.finished {
                let (f,w)=try feature.field()
                switch (f,w) {
                case (1,0): id=try feature.varint()
                case (2,2):
                    var t=MapBinaryReader(try feature.blob())
                    while !t.finished {guard tags.count<256 else {throw MapFailure.invalid("地图标签过多")};tags.append(try t.varint())}
                case (3,0): type=try feature.varint()
                case (4,2): geometry=try feature.blob()
                default:try feature.skip(w)
                }
            }
            guard tags.count%2==0 else {throw MapFailure.invalid("地图标签损坏")}
            guard name=="roads" ? type==2:type==3 else {continue}
            var properties:[String:String]=[:]
            for i in stride(from:0,to:tags.count,by:2) {
                guard tags[i]<UInt64(keys.count),tags[i+1]<UInt64(values.count) else {throw MapFailure.invalid("地图标签索引越界")}
                properties[keys[Int(tags[i])]]=values[Int(tags[i+1])]
            }
            let kind:UInt8
            if name=="buildings" {kind=5}
            else {switch properties["kind"] {case "highway":kind=4;case "major_road":kind=3;case "medium_road":kind=2;case "minor_road":kind=1;default:kind=0}}
            let parts=try paths(geometry,extent:Int64(extent),budget:&budget)
            for (part,points) in parts.enumerated() where points.count>=2 {
                // Namespace tile/layer/feature/part IDs: vendor IDs are not OSM way IDs.
                var hash:UInt64=14695981039346656037
                for b in "\(tile.id)/\(name)/\(id)/\(part)".utf8 {hash=(hash ^ UInt64(b)) &* 1099511628211}
                let label=properties["name:zh"] ?? properties["name"] ?? ""
                result.append(GeographicMapFeature(id:max(1,hash),kind:kind,name:label,
                    coordinates:points.map {tile.coordinate(x:Double($0.0),y:Double($0.1),extent:Double(extent))}))
            }
        }
        return result
    }
    private static func paths(_ data:Data,extent:Int64,budget:inout Int) throws -> [[(Int64,Int64)]] {
        var r=MapBinaryReader(data),x:Int64=0,y:Int64=0,result:[[(Int64,Int64)]]=[],part:[(Int64,Int64)]=[],count=0
        func signed(_ value:UInt64) throws -> Int64 {
            guard value<=UInt32.max else {throw MapFailure.invalid("地图坐标溢出")}
            return Int64(value>>1) ^ -Int64(value&1)
        }
        while !r.finished {
            let command=try r.varint(),op=command&7,n=command>>3
            guard n>0,n<=4096 else {throw MapFailure.invalid("地图绘图指令超限")}
            if op==7 {
                guard n==1,part.count>=3 else {throw MapFailure.invalid("地图闭合指令无效")}
                if let first=part.first,let last=part.last,first.0 != last.0 || first.1 != last.1 {part.append(first)}
                continue
            }
            guard op==1 || op==2,op != 2 || !part.isEmpty else {throw MapFailure.invalid("地图绘图顺序无效")}
            for _ in 0..<n {
                if op==1 && !part.isEmpty {result.append(part);part=[]}
                x += try signed(r.varint());y += try signed(r.varint());budget-=1;count+=1
                guard budget>=0,count<=4096,abs(x)<=extent*16,abs(y)<=extent*16 else {throw MapFailure.invalid("地图几何超限")}
                part.append((x,y))
            }
        }
        if !part.isEmpty {result.append(part)};return result
    }
}
