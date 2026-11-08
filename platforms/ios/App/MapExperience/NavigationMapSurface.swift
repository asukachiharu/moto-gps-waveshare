import MapKit
import MotoNavigationCore
import SwiftUI

/// One interactive map across search, route selection and navigation.
struct NavigationMapSurface: UIViewRepresentable {
    @ObservedObject var model: AppModel
    let recenterID: Int
    let followsHeading: Bool
    let occlusion: CGSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.delegate = context.coordinator
        map.mapType = .standard
        map.showsCompass = false
        map.showsScale = false
        map.showsTraffic = true
        map.showsUserLocation = !ProcessInfo.processInfo.arguments.contains("--moto-ui-offline")
        map.registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self]) {
            [weak coordinator = context.coordinator] (map: MKMapView, _: UITraitCollection) in
            coordinator?.refreshRouteAppearance(on: map)
        }
        return map
    }
    func updateUIView(_ map: MKMapView, context: Context) {
        let owner = context.coordinator
        let tracking: MKUserTrackingMode = followsHeading && model.isNavigationActive ? .followWithHeading : .follow
        if owner.recenterID != recenterID || owner.wasNavigating != model.isNavigationActive {
            owner.recenterID = recenterID; owner.wasNavigating = model.isNavigationActive
            map.setUserTrackingMode(tracking, animated: !reduceMotion)
        }
        let candidates = model.mapDisplayRoutes
        let selected = model.isNavigationActive ? candidates.first?.id : model.selectedRoutePreviewID
        owner.selectedID = selected
        let signature = candidates.map { $0.id + ":" + String($0.route.generatedAtMs) }.joined(separator: "|") +
            "::" + (selected ?? "") + "::" + (model.selectedPlace?.id ?? "")
        guard owner.signature != signature else { return }
        owner.signature = signature
        map.removeOverlays(map.overlays)
        map.removeAnnotations(map.annotations.filter { !($0 is MKUserLocation) })
        var coordinates: [CLLocationCoordinate2D] = []
        for candidate in candidates.sorted(by: { ($0.id == selected ? 1 : 0) < ($1.id == selected ? 1 : 0) }) {
            let points = candidate.route.polyline.map { point -> CLLocationCoordinate2D in
                let wgs = ChinaCoordinateTransform.gcj02ToWGS84(point)
                return CLLocationCoordinate2D(latitude: wgs.latitudeDeg, longitude: wgs.longitudeDeg)
            }
            guard points.count >= 2 else { continue }
            let line = MKPolyline(coordinates: points, count: points.count); line.title = candidate.id
            map.addOverlay(line, level: .aboveRoads); coordinates += points
        }
        if let place = model.selectedPlace {
            let destination = MKPointAnnotation()
            destination.coordinate = CLLocationCoordinate2D(latitude: place.location.latitudeDeg, longitude: place.location.longitudeDeg)
            destination.title = place.name; destination.subtitle = "moto-finish"
            map.addAnnotation(destination); coordinates.append(destination.coordinate)
        }
        if let origin = model.routePreviewOrigin {
            coordinates.append(CLLocationCoordinate2D(latitude: origin.latitudeDeg, longitude: origin.longitudeDeg))
        }
        guard !model.isNavigationActive, !coordinates.isEmpty else { return }
        var bounds = MKMapRect.null
        for coordinate in coordinates {
            let point = MKMapPoint(coordinate)
            bounds = bounds.union(MKMapRect(x: point.x, y: point.y, width: 1, height: 1))
        }
        map.setVisibleMapRect(bounds,
            edgePadding: UIEdgeInsets(top: 100, left: occlusion.width + 30, bottom: occlusion.height + 30, right: 30),
            animated: owner.hasPresentedRoute && !reduceMotion)
        owner.hasPresentedRoute = true
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var signature = ""
        var recenterID = -1
        var wasNavigating = false
        var selectedID: String?
        var hasPresentedRoute = false

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: polyline)
            configure(renderer, for: polyline, traits: mapView.traitCollection)
            return renderer
        }

        func refreshRouteAppearance(on mapView: MKMapView) {
            // Overlay renderers draw resolved colors. Refresh their strokes when
            // appearance changes even if the route IDs have stayed the same.
            for overlay in mapView.overlays {
                guard let polyline = overlay as? MKPolyline,
                      let renderer = mapView.renderer(for: overlay) as? MKPolylineRenderer
                else { continue }
                configure(renderer, for: polyline, traits: mapView.traitCollection)
                renderer.setNeedsDisplay()
            }
        }

        private func configure(
            _ renderer: MKPolylineRenderer,
            for polyline: MKPolyline,
            traits: UITraitCollection
        ) {
            let isSelected = polyline.title == selectedID
            let color: UIColor = isSelected ? .systemBlue : .systemGray
            renderer.strokeColor = color.resolvedColor(with: traits)
            renderer.lineWidth = isSelected ? 7 : 5
            renderer.lineCap = .round
            renderer.lineJoin = .round
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let point = annotation as? MKPointAnnotation else { return nil }
            let identifier = "route-endpoint"
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView)
                ?? MKMarkerAnnotationView(annotation: point, reuseIdentifier: identifier)
            view.annotation = point
            let isStart = point.subtitle == "moto-start"
            view.markerTintColor = isStart ? .systemBlue : .systemRed
            view.glyphImage = UIImage(systemName: isStart ? "location.fill" : "flag.fill")
            view.glyphTintColor = .white
            view.subtitleVisibility = .hidden
            view.displayPriority = .required
            return view
        }
    }
}
