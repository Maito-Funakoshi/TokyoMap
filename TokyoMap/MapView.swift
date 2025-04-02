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
        mapView.showsUserLocation = true // 現在地を表示
        mapView.pointOfInterestFilter = .excludingAll

        // 初期表示のズーム設定
        let initialCoordinate = CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917) // 東京の座標
        let region = MKCoordinateRegion(
            center: initialCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1) // ズーム範囲を設定
        )
        mapView.setRegion(region, animated: false)
        
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
        // 訪れた自治体名を格納する配列を定義
        @State var visitedLocalities: [String] = []
        
        private let locationManager = CLLocationManager()
        private let geocoder = CLGeocoder() // 逆ジオコーディング用のインスタンスを追加
        private var locationUpdateTimer: Timer? // 位置情報更新用のタイマーを追加

        override init() {
            super.init()
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization() // 位置情報の使用許可をリクエスト
            startLocationUpdates() // タイマーを開始
        }

        private func startLocationUpdates() {
            // 一定時間ごとに現在地を取得するタイマーを設定
            locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
                self?.locationManager.requestLocation()
            }
        }

        private func stopLocationUpdates() {
            // タイマーを停止
            locationUpdateTimer?.invalidate()
            locationUpdateTimer = nil
        }

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last else { return }
            print("現在地: \(location.coordinate.latitude), \(location.coordinate.longitude)")

            // 逆ジオコーディングを実行
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    print("逆ジオコーディングに失敗しました: \(error.localizedDescription)")
                    return
                }

                guard let placemark = placemarks?.first else {
                    print("位置情報が見つかりませんでした")
                    return
                }

                if let locality = placemark.locality {
                    if !self.visitedLocalities.contains(locality) {
                        print("新しい自治体に訪れました: \(locality)")
                        self.visitedLocalities.append(locality) // 新しい自治体をリストに追加
                    } else {
                        print("既に訪れた自治体: \(locality)")
                    }
                } else {
                    print("自治体名を取得できませんでした")
                }
            }
        }

        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print("位置情報の取得に失敗しました: \(error.localizedDescription)")
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polygon = overlay as? MKPolygon else {
                return .init()
            }

            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.fillColor = UIColor(red: 93/255, green: 167/255, blue: 79/255, alpha: 1).withAlphaComponent(0.9)
            renderer.strokeColor = .white
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
