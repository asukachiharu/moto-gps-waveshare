import SwiftUI

struct MapHomePanel: View {
    @ObservedObject var model: AppModel
    let collapsed: Bool
    let open: (MapPanel) -> Void
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    Button { open(.search) } label: {
                        Label("搜索地点或地址", systemImage: "magnifyingglass")
                            .foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                            .padding(15).background(.quaternary, in: .rect(cornerRadius: 16))
                    }.buttonStyle(.plain).accessibilityIdentifier("open-search")
                    Button("设置", systemImage: "person.crop.circle") { open(.settings) }
                        .labelStyle(.iconOnly).font(.title).accessibilityIdentifier("open-settings")
                }
                if !collapsed {
                    if !model.isNavigationServiceConfigured {
                        Button("配置导航服务", systemImage: "key") { open(.settings) }
                            .accessibilityIdentifier("gateway-setup-button")
                    }
                    HStack {
                        shortcut("最近", "clock", .recent)
                        shortcut("离线地图", "map", .downloads)
                        shortcut("圆屏", "display", .device)
                        shortcut("设置", "gearshape", .settings)
                    }
                    if !model.recentPlaces.isEmpty {
                        Text("最近地点").font(.headline)
                        ForEach(model.recentPlaces) { place in
                            Button { model.selectPlace(place) } label: { MapPlaceRow(place: place) }
                                .buttonStyle(.plain)
                        }
                    }
                    if model.searchLocationStatus == .permissionDenied {
                        Label("请在系统设置中允许定位", systemImage: "location.slash").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }.padding(.horizontal, 20).padding(.vertical, collapsed ? 12 : 20)
        }.accessibilityIdentifier("map-home-panel")
    }
    private func shortcut(_ title: String, _ symbol: String, _ destination: MapPanel) -> some View {
        Button { open(destination) } label: {
            VStack(spacing: 8) {
                Image(systemName: symbol).font(.title3).frame(width: 50, height: 50)
                    .background(.quaternary, in: .rect(cornerRadius: 16))
                Text(title).font(.caption).foregroundStyle(.primary)
            }.frame(maxWidth: .infinity)
        }.buttonStyle(.plain).accessibilityIdentifier("home-shortcut-" + symbol)
    }
}
