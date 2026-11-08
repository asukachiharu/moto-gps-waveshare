import SwiftUI

struct NavigationGuidanceCard: View {
    let snapshot: MotoNavCoreSnapshot
    let failure: String?
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.system(size: 34, weight: .semibold)).frame(width: 44)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.title3.bold()).lineLimit(2)
                if !detail.isEmpty { Text(detail).font(.subheadline).foregroundStyle(.white.opacity(0.8)).lineLimit(2) }
            }
            Spacer(minLength: 0)
        }.foregroundStyle(.white).padding(18)
            .background(Color(red: 0.06, green: 0.09, blue: 0.12), in: .rect(cornerRadius: 20))
            .accessibilityIdentifier("navigation-guidance")
    }
    private var title: String {
        if failure != nil { return "导航需要处理" }
        if snapshot.gnssStale { return "定位信号较弱" }
        if snapshot.stateName == "arrived" { return "已到达目的地" }
        if snapshot.stateName == "rerouting" { return "正在重新规划" }
        if snapshot.hasNextManeuver {
            let distance = snapshot.distanceToManeuverM
            return distance >= 1000 ? String(format: "%.1f 公里后", distance / 1000) : "\(Int(max(0, distance).rounded())) 米后"
        }
        return snapshot.stateName == "navigating" ? "沿当前道路行驶" : "正在获取导航指引"
    }
    private var detail: String { failure ?? (snapshot.hasNextManeuver ? (snapshot.roadName.isEmpty ? snapshot.instructionText : snapshot.roadName) : "") }
    private var symbol: String {
        if failure != nil { return "exclamationmark.triangle" }
        if snapshot.gnssStale { return "location.slash" }
        switch snapshot.maneuverTypeName {
        case "left", "sharp_left": return "arrow.turn.up.left"
        case "right", "sharp_right": return "arrow.turn.up.right"
        case "slight_left": return "arrow.up.left"
        case "slight_right": return "arrow.up.right"
        case "u_turn_left", "u_turn_right": return "arrow.uturn.down"
        case "roundabout": return "arrow.trianglehead.clockwise.rotate.90"
        case "arrive": return "flag.checkered"
        default: return "arrow.up"
        }
    }
}
