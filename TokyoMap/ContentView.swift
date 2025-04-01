//
//  ContentView.swift
//  TokyoMap
//
//  Created by 船越舞斗 on 2025/04/01.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()
    
    var body: some View {
       MapView(
           geoJSONFeatures: viewModel.geoJSONFeatures
       )
        .onAppear {
            viewModel.loadAllData()
        }
    }
}

#Preview {
    ContentView()
}
