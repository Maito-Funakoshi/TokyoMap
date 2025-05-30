//
//  MapView.swift
//  TokyoMap
//
//  Created by 船越舞斗 on 2025/04/01.
//

import SwiftUI
import MapKit
import CoreLocation

// アプリ全体で共有できる観測可能なオブジェクトを作成
class MapViewObservable: ObservableObject {
    @Published var localities: [String] = []
    @Published var newLocality: String = ""
    @Published var totalDistance: Double = 0.0 // 移動距離を記録する変数を追加
    @Published var trajectory: [CLLocationCoordinate2D] = []
    
    func addLocality(_ locality: String) {
        if !localities.contains(locality) {
            localities.append(locality)
        }
    }
}

struct MapView: UIViewRepresentable {
    var geoJSONFeatures: [MKGeoJSONFeature]
    
    // 親ビューから渡されるObservableObjectへの参照
    @ObservedObject var mapViewStore: MapViewObservable
    
    // 現在地へ移動するためのフラグ
    @Binding var centerOnUserLocation: Bool
    
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
        // GeoJSONデータが更新されたらオーバーレイを追加/更新する
        if !geoJSONFeatures.isEmpty && uiView.overlays.filter({ $0 is MKPolygon || $0 is MKMultiPolygon }).isEmpty {
            DispatchQueue.global(qos: .userInitiated).async {
                let overlays = self.geoJSONFeatures.flatMap(self.createOverlays(from:))
                DispatchQueue.main.async {
                    uiView.addOverlays(overlays)
                }
            }
        }
        
        // 軌跡の描画処理
        // 既存の軌跡のポリラインを削除
        uiView.overlays.filter { $0 is MKPolyline }.forEach { uiView.removeOverlay($0) }
        
        // 新しい軌跡のポリラインを追加（2点以上ある場合のみ）
        if mapViewStore.trajectory.count >= 2 {
            let polyline = MKPolyline(coordinates: mapViewStore.trajectory, count: mapViewStore.trajectory.count)
            uiView.addOverlay(polyline)
        }
        
        // 現在地へ移動するフラグがtrueの場合のみ処理
        if centerOnUserLocation {
            if let userLocation = uiView.userLocation.location {
                let region = MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                )
                uiView.setRegion(region, animated: true)
            }
            // フラグをリセット（一度だけ移動するため）
            DispatchQueue.main.async {
                self.centerOnUserLocation = false
            }
        }
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
        // ストアへの参照をコーディネーターに渡す
        Coordinator(mapViewStore: mapViewStore)
    }
    
    final class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        // @Stateを削除し、外部から渡されるストアを保持する
        private var mapViewStore: MapViewObservable
        private var lastLocation: CLLocation? // 前回の位置情報を記録する変数を追加
        
        private let locationManager = CLLocationManager()
        private let geocoder = CLGeocoder()
        private var locationUpdateTimer: Timer?
        
        // 初期化時にストアを受け取る
        init(mapViewStore: MapViewObservable) {
            self.mapViewStore = mapViewStore
            super.init()
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            startLocationUpdates()
        }
        
        private func startLocationUpdates() {
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            // 10mの精度
            locationManager.distanceFilter = 5 // 5m移動するごとに更新
            locationManager.startUpdatingLocation()
        }
        
        private func stopLocationUpdates() {
            locationUpdateTimer?.invalidate()
            locationUpdateTimer = nil
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last else { return }
            
            print("現在地: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            self.mapViewStore.trajectory.append(location.coordinate)
            
            
            // 移動距離を計算して更新
            if let lastLocation = lastLocation {
                let distance = location.distance(from: lastLocation)
                DispatchQueue.main.async {
                    self.mapViewStore.totalDistance += distance
                }
            }
            self.lastLocation = location // 現在の位置を記録
            
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("逆ジオコーディングに失敗しました: \(error.localizedDescription)")
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    print("位置情報が見つかりませんでした")
                    return
                }
                
                if let locality = placemark.locality {
                    
                    if !self.mapViewStore.localities.contains(locality) {
                        print("新しい自治体に訪れました: \(locality)")
                        NotificationManager.instance.sendNotification("新たな場所に移動しました！", locality)
                        // メインスレッドで状態を更新
                        DispatchQueue.main.async {
                            self.mapViewStore.addLocality(locality)
                        }
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
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor(red: 93/255, green: 167/255, blue: 79/255, alpha: 1).withAlphaComponent(0.9)
                renderer.strokeColor = .white
                renderer.lineWidth = 1
                return renderer
            } else if let polyline = overlay as? MKPolyline {
                // 軌跡の描画設定
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.blue
                renderer.lineWidth = 4.0
                renderer.alpha = 0.7
                return renderer
            }
            
            return .init()
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
