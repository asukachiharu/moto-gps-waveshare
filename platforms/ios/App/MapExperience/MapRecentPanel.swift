import SwiftUI

struct MapRecentPanel: View {
    @ObservedObject var model: AppModel
    var body: some View {
        List {
            if model.recentPlaces.isEmpty { ContentUnavailableView("暂无最近地点", systemImage: "clock") }
            ForEach(model.recentPlaces) { place in
                Button { model.selectPlace(place) } label: { MapPlaceRow(place: place) }
            }
            if !model.recentPlaces.isEmpty { Button("清空最近地点", role: .destructive, action: model.clearRecentPlaces) }
        }.navigationTitle("最近地点").navigationBarTitleDisplayMode(.inline)
    }
}
