//
//  XMLParser.swift
//  TokyoMap
//
//  Created by 船越舞斗 on 2025/04/01.
//

import Kanna

struct XMLParser {
    private let namespaces = [
        "head": "http://xml.kishou.go.jp/jmaxml1/informationBasis1/"
    ]
    
    func parse(from xmlString: String) throws -> [WarningItem] {
        let xml = try Kanna.XML(xml: xmlString, encoding: .utf8)
        let xpath = "//head:Information[@type='気象警報・注意報（市町村等）']/head:Item"
        let items = xml.xpath(xpath, namespaces: namespaces).compactMap(parseWarningItem(from:))
        return items
    }
    
    private func parseWarningItem(from item: XMLElement) -> WarningItem? {
        guard let area = item.at_xpath("head:Areas/head:Area", namespaces: namespaces),
              let areaName = area.at_xpath("head:Name", namespaces: namespaces)?.text,
              let areaCode = area.at_xpath("head:Code", namespaces: namespaces)?.text else {
            return nil
        }
        let kindNames = item.xpath("head:Kind/head:Name", namespaces: namespaces).compactMap { $0.text }
        return WarningItem(areaName: areaName, areaCode: areaCode, kindNames: kindNames)
    }
}

