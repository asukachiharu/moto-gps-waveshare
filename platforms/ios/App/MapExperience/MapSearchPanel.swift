import SwiftUI

struct MapSearchPanel: View {
    @ObservedObject var model: AppModel
    @FocusState private var focused: Bool
    var body: some View {
        List {
            Section {
                TextField("搜索地点或地址", text: $model.destinationQuery)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .submitLabel(.search).focused($focused)
                    .onSubmit { model.submitDestinationSearch() }
                    .accessibilityIdentifier("destination-search-field")
            }
            Section {
                if model.isSearchingPlaces { ProgressView("正在搜索") }
                ForEach(model.placeResults) { place in
                    Button { focused = false; model.selectPlace(place) } label: { MapPlaceRow(place: place) }
                }
                if let failure = model.placeSearchFailure {
                    Text(failure).foregroundStyle(.secondary)
                    Button("重试", action: model.submitDestinationSearch)
                } else if model.destinationQuery.count < 2 {
                    Text("输入至少两个字查找目的地").foregroundStyle(.secondary)
                }
            } footer: { Text(model.searchScopeText) }
        }.navigationTitle("搜索目的地").navigationBarTitleDisplayMode(.inline)
    }
}
