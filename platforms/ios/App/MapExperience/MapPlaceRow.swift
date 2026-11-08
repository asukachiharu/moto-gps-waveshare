import SwiftUI

struct MapPlaceRow: View {
    let place: PlaceSearchResult
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "mappin.circle.fill").font(.title2).foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 5) {
                Text(place.name).foregroundStyle(.primary)
                Text([place.displayArea, place.address].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
            }.frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }.padding(.vertical, 8).frame(minHeight: 44).contentShape(.rect)
    }
}
