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
//    @Published var warningItems: [WarningItem] = []
    
    func loadAllData() {
       do {
           let geoJSONFeatures = try loadGeoJSON(from: "japan")
           self.geoJSONFeatures = geoJSONFeatures
       } catch {
           assertionFailure("GeoJSONのデコードに失敗しました: \(error)")
       }
               
//        do {
//            let warningItems = try loadXML(from: "15_14_01_170216_VPWW54")
//            self.warningItems = warningItems
//        } catch {
//            assertionFailure("XMLのデコードに失敗しました: \(error)")
//        }
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
    
    
//    private func loadXML(from fileName: String) throws -> [WarningItem] {
//        guard let url = Bundle.main.url(forResource: fileName, withExtension: "xml"),
//              let data = try? Data(contentsOf: url),
//              let xmlString = String(data: data, encoding: .utf8) else {
//            assertionFailure("XMLのパースに失敗しました")
//            return []
//        }
//        
//        let parser = XMLParser()
//        let warningItems = try parser.parse(from: xmlString)
//        return warningItems
//    }
}
