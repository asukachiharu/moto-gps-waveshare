import SwiftUI

/// The map, navigation runtime and Bluetooth service survive every panel change.
struct ContentView: View {
    @ObservedObject var model: AppModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage("MotoGPS.Appearance") private var appearance = "system"
    @AppStorage("MotoGPS.FollowHeading") private var followHeading = true
    @State private var panel: MapPanel = .home
    @State private var detent: PresentationDetent = .medium
    @State private var recenterID = 0
    @State private var confirmsEnd = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let wide = sizeClass == .regular && geometry.size.width >= 600
                NavigationMapSurface(model: model, recenterID: recenterID, followsHeading: followHeading,
                    occlusion: wide ? CGSize(width: min(380, geometry.size.width * 0.42), height: 0) :
                        CGSize(width: 0, height: detent == .large ? geometry.size.height * 0.85 : detent == .medium ? geometry.size.height * 0.5 : 150))
                    .ignoresSafeArea()
                    .overlay(alignment: .topLeading) {
                        if model.isNavigationActive {
                            NavigationGuidanceCard(snapshot: model.navigation, failure: model.navigationFailure)
                                .frame(maxWidth: 420).padding()
                        }
                    }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("定位", systemImage: "location.fill") {
                        model.refreshMapLocation(); recenterID += 1
                    }.accessibilityIdentifier("map-recenter")
                }
                ToolbarItem(placement: .secondaryAction) {
                    Menu("更多", systemImage: "ellipsis") {
                        Button("导航设置", systemImage: "gearshape") { open(.settings) }
                            .accessibilityIdentifier("gateway-settings-toolbar")
                        Button("我的圆屏", systemImage: "display") { open(.device) }
                        Button("离线地图", systemImage: "map") { open(.downloads) }
                        Button("最近地点", systemImage: "clock") { open(.recent) }
                        Button("隐私与署名", systemImage: "hand.raised") { open(.privacy) }
                    }.accessibilityIdentifier("map-more")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: .constant(true)) {
            NavigationStack {
                panelContent
                    .toolbar {
                        if panel != .home {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("返回地图", systemImage: "xmark") { open(.home) }
                                    .accessibilityIdentifier("panel-close")
                            }
                        }
                    }
            }
            .presentationDetents(panel == .home ? [.height(116), .medium, .large] : [.large], selection: $detent)
            .presentationDragIndicator(.visible)
            .presentationContentInteraction(.resizes)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .interactiveDismissDisabled()
            .modifier(MapPanelPlacement(wide: sizeClass == .regular))
            .preferredColorScheme(colorScheme)
        }
        .tint(.blue)
        .preferredColorScheme(colorScheme)
        .onChange(of: model.destinationQuery) { _, _ in model.destinationQueryDidChange() }
        .onChange(of: model.selectedPlace) { _, place in
            if place != nil { open(.home) }
        }
        .onChange(of: model.isNavigationActive) { _, active in
            open(.home); detent = active ? .height(116) : .medium
        }
        .confirmationDialog("结束本次导航？", isPresented: $confirmsEnd, titleVisibility: .visible) {
            Button("结束导航", role: .destructive) { model.stopNavigation() }
        }
    }

    @ViewBuilder private var panelContent: some View {
        switch panel {
        case .home:
            if model.isNavigationActive {
                NavigationRidePanel(model: model, expanded: detent != .height(116), end: { confirmsEnd = true }, device: { open(.device) })
            } else if model.selectedPlace != nil {
                NavigationRoutePanel(model: model)
            } else {
                MapHomePanel(model: model, collapsed: detent == .height(116), open: open)
            }
        case .search: MapSearchPanel(model: model)
        case .recent: MapRecentPanel(model: model)
        case .device: MapDevicePanel(model: model)
        case .settings: NavigationSettingsPanel(model: model)
        case .downloads:
            MapDownloadsView(onClose: { open(.home) }, cityLoader: citySearchLoader,
                             store: model.surroundingMap, gatewayBaseURL: model.mapGatewayBaseURL,
                             route: model.mapDownloadRoute, destinationName: model.selectedPlace?.name)
        case .privacy: DataUseView(onClose: { open(.home) })
        }
    }
    private var colorScheme: ColorScheme? { appearance == "light" ? .light : appearance == "dark" ? .dark : nil }
    private var citySearchLoader: (@MainActor (String) async throws -> [MapCity])? {
        guard model.navigationSource == .sdk else { return nil }
        return { query in try await model.searchMapCities(query) }
    }
    private func open(_ destination: MapPanel) {
        panel = destination
        detent = destination == .home ? (model.isNavigationActive ? .height(116) : .medium) : .large
    }
}
