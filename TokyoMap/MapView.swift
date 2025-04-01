//
//  MapView.swift
//  TokyoMap
//
//  Created by 船越舞斗 on 2025/04/01.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    var geoJSONFeatures: [MKGeoJSONFeature]
//    var warningItems: [WarningItem]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .mutedStandard
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
//        context.coordinator.updateWarningItems(warningItems)
        
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
    
    final class Coordinator: NSObject, MKMapViewDelegate {
//        private var warningItems: [WarningItem] = []
        
//        private let warningTypeColors: [(String, UIColor)] = [
//            ("特別警報", .purple.withAlphaComponent(0.5)),
//            ("警報", .red.withAlphaComponent(0.5)),
//            ("注意報", .yellow.withAlphaComponent(0.5))
//        ]
        
//        func updateWarningItems(_ warningItems: [WarningItem]) {
//            self.warningItems = warningItems
//        }
        
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

//        private func resolveFillColor(for polygon: MKPolygon) -> UIColor {
//            // 警報の有無に関わらず、すべての地域を緑色に塗る
//            return .green.withAlphaComponent(0.5)
//            
//            /* 元のコード
//            guard let areaCode = polygon.subtitle,
//                  let warningItem = warningItems.first(where: { $0.areaCode == areaCode }),
//                  let (_, color) = warningTypeColors.first(where: { warningType, _ in
//                      warningItem.kindNames.contains { $0.contains(warningType) }
//                  }) else {
//                return .clear
//            }
//            
//            return color
//            */
//        }
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
