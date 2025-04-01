//
//  MapView.swift
//  TokyoMap
//
//  Created by 船越舞斗 on 2025/04/01.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: UIViewRepresentable {
    var geoJSONFeatures: [MKGeoJSONFeature]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .mutedStandard
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)
        uiView.addOverlays(geoJSONFeatures.flatMap(createOverlays(from:)))
    }

    private func createOverlays(from feature: MKGeoJSONFeature) -> [MKOverlay] {
        guard let metadata = extractMetadata(from: feature) else {
            return []
        }
        return feature.geometry.flatMap { geometry in
            switch geometry {
            case let polygon as MKPolygon:
                polygon.title = metadata.regionName
                polygon.subtitle = metadata.regionCode
                return [polygon]
            case let multiPolygon as MKMultiPolygon:
                multiPolygon.title = metadata.regionName
                multiPolygon.subtitle = metadata.regionCode
                return multiPolygon.polygons
            default:
                return []
            }
        }
    }

    private func extractMetadata(from feature: MKGeoJSONFeature) -> Metadata? {
        guard let data = feature.properties else {
            return nil
        }
        let decoder = JSONDecoder()
        return try? decoder.decode(Metadata.self, from: data)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        
        

        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polygon = overlay as? MKPolygon else {
                return .init()
            }

            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.fillColor = .green.withAlphaComponent(0.5)
            renderer.strokeColor = .gray
            renderer.lineWidth = 1
            return renderer
        }
    }

    private struct Metadata: Codable {
        let regionName: String
        let regionCode: String

        enum CodingKeys: String, CodingKey {
            case regionName = "regionname"
            case regionCode = "regioncode"
        }
    }
}
