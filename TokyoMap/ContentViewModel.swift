//
//  ContentViewModel.swift
//  TokyoMap
//
//  Created by 船越舞斗 on 2025/04/01.
//

import Foundation
import MapKit

final class ContentViewModel: ObservableObject {
    @Published var geoJSONFeatures: [MKGeoJSONFeature] = []
    
    func loadAllData() {
       do {
           let geoJSONFeatures = try loadGeoJSON(from: "japan")
           self.geoJSONFeatures = geoJSONFeatures
       } catch {
           assertionFailure("GeoJSONのデコードに失敗しました: \(error)")
       }
    }
    
   private func loadGeoJSON(from fileName: String) throws -> [MKGeoJSONFeature] {
       guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
             let data = try? Data(contentsOf: url) else {
           assertionFailure("GeoJSONの読み込みに失敗しました")
           return []
       }

       let decoder = MKGeoJSONDecoder()
       guard let features = try decoder.decode(data) as? [MKGeoJSONFeature] else {
           assertionFailure("GeoJSONのデコードに失敗しました")
           return []
       }
       return features
   }
}
