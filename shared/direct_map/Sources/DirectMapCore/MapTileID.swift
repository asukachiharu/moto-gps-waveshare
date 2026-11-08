import Foundation

public struct MapTileID: Codable, Hashable, Sendable, Identifiable {
    public let z: Int
    public let x: Int
    public let y: Int
    public var id: UInt64 { hilbertID }
    public init(z: Int,x: Int,y: Int) throws {
        guard (0...22).contains(z), (0..<(1 << z)).contains(x), (0..<(1 << z)).contains(y) else { throw MapFailure.invalid("瓦片坐标无效") }
        self.z=z;self.x=x;self.y=y
    }
    private enum CodingKeys:String,CodingKey{case z,x,y}
    public init(from decoder:Decoder) throws {
        let c=try decoder.container(keyedBy:CodingKeys.self)
        try self.init(z:c.decode(Int.self,forKey:.z),x:c.decode(Int.self,forKey:.x),y:c.decode(Int.self,forKey:.y))
    }
    public var hilbertID: UInt64 {
        var px=x,py=y,d: UInt64=0,s=(1 << z)/2
        while s>0 {
            let rx=(px&s)>0 ? 1:0,ry=(py&s)>0 ? 1:0
            d += UInt64(s)*UInt64(s)*UInt64((3*rx)^ry)
            if ry==0 { if rx==1 { px=s-1-px;py=s-1-py };swap(&px,&py) }
            s /= 2
        }
        return ((UInt64(1) << (2*z))-1)/3+d
    }
    public var fileName: String { "\(z)-\(x)-\(y).mvt" }
    public static func containing(_ coordinate: Coordinate,zoom: Int=15) throws -> MapTileID {
        guard coordinate.isValid, abs(coordinate.latitude)<=85.05112878,(0...22).contains(zoom) else { throw MapFailure.invalid("地图超出覆盖范围") }
        let n=Double(1 << zoom),lat=coordinate.latitude * .pi/180
        let x=Int(floor((coordinate.longitude+180)/360*n)),y=Int(floor((1-log(tan(lat)+1/cos(lat)) / .pi)/2*n))
        return try MapTileID(z:zoom,x:max(0,min(Int(n)-1,x)),y:max(0,min(Int(n)-1,y)))
    }
    public func coordinate(x pixelX: Double,y pixelY: Double,extent: Double) -> Coordinate {
        let n=Double(1 << z)
        return Coordinate(latitude:atan(sinh(.pi*(1-2*(Double(y)+pixelY/extent)/n)))*180 / .pi,
            longitude:(Double(x)+pixelX/extent)/n*360-180)
    }
}

public struct MapRegion: Codable, Sendable, Equatable {
    public let south: Double,north: Double,west: Double,east: Double
    public init(south: Double,north: Double,west: Double,east: Double) throws {
        guard [south,north,west,east].allSatisfy(\.isFinite),south<north,west<east,
              south >= -85,north <= 85,west >= -180,east <= 180 else { throw MapFailure.invalid("行政区边界无效") }
        self.south=south;self.north=north;self.west=west;self.east=east
    }
    public func tiles(zoom: Int=15,limit: Int=100_000) throws -> [MapTileID] {
        let a=try MapTileID.containing(Coordinate(latitude:north,longitude:west),zoom:zoom)
        let b=try MapTileID.containing(Coordinate(latitude:south,longitude:east),zoom:zoom)
        guard b.x>=a.x,b.y>=a.y,(b.x-a.x+1)*(b.y-a.y+1)<=limit else { throw MapFailure.invalid("此区域过大，请选择市或区县") }
        var result:[MapTileID]=[]
        for x in a.x...b.x { for y in a.y...b.y { result.append(try MapTileID(z:zoom,x:x,y:y)) } }
        return result.sorted { $0.id<$1.id }
    }
    public func contains(_ c: Coordinate) -> Bool { c.latitude>=south && c.latitude<=north && c.longitude>=west && c.longitude<=east }
}
