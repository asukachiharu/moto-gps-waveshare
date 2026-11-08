import SwiftUI

struct NavigationRoutePanel: View {
    @ObservedObject var model: AppModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(model.selectedPlace?.name ?? "目的地").font(.title3.bold())
                        Label("从我的位置出发", systemImage: "location.fill").font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("更换目的地", systemImage: "xmark") { model.clearDestination() }
                        .labelStyle(.iconOnly).accessibilityIdentifier("destination-change-button")
                }
                if model.isPlanningRoutePreview { ProgressView("正在规划路线").accessibilityIdentifier("route-preview-loading") }
                if let failure = model.routePreviewFailure {
                    Text(failure).foregroundStyle(.secondary)
                    Button("重新规划", action: model.planRoutePreview)
                }
                if model.hasRoutePreview {
                    ScrollView(.horizontal) {
                        HStack(spacing: 12) {
                            ForEach(model.routePreviewCandidates) { candidate in
                                Button { model.selectRoutePreview(candidate.id) } label: {
                                    VStack(alignment: .leading, spacing: 7) {
                                        Text(candidate.durationText).font(.title3.bold())
                                        Text(candidate.distanceText).font(.subheadline)
                                        Text(candidate.title).font(.caption)
                                        Text(candidate.trafficSummary).font(.caption).foregroundStyle(.secondary)
                                    }.frame(minWidth: 150, alignment: .leading).padding(16)
                                        .background(.quaternary, in: .rect(cornerRadius: 18))
                                        .overlay { RoundedRectangle(cornerRadius: 18).stroke(candidate.id == model.selectedRoutePreviewID ? Color.blue : .clear, lineWidth: 2) }
                                }.buttonStyle(.plain).accessibilityIdentifier("route-option-\(candidate.ordinal)")
                                    .accessibilityAddTraits(candidate.id == model.selectedRoutePreviewID ? .isSelected : [])
                            }
                        }.padding(2)
                    }.scrollIndicators(.hidden)
                }
                if let failure = model.navigationFailure { Text(failure).foregroundStyle(.secondary) }
                Button(action: model.startNavigation) {
                    Label("开始导航", systemImage: "location.fill").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 8)
                }.buttonStyle(.borderedProminent).controlSize(.large)
                    .disabled(!model.canStartNavigation).accessibilityIdentifier("primary-navigation-action")
            }.padding(20)
        }.accessibilityIdentifier("route-selection-panel")
    }
}
