//
//  WarningItem.swift
//  TokyoMap
//
//  Created by 船越舞斗 on 2025/04/01.
//

import Foundation

struct WarningItem: Identifiable {
    let id = UUID()
    let areaName: String
    let areaCode: String
    let kindNames: [String]
}
