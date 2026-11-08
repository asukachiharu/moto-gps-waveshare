import SwiftUI

enum MapPanel: String, Identifiable {
    case home, search, recent, device, settings, downloads, privacy
    var id: String { rawValue }
}

struct MapPanelPlacement: ViewModifier {
    let wide: Bool
    func body(content: Content) -> some View {
        if #available(iOS 27, *) { content.presentationPlacement(wide ? .leading : .automatic) }
        else { content }
    }
}
