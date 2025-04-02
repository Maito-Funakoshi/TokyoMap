//
//  ContentView.swift
//  TokyoMap
//
//  Created by 船越舞斗 on 2025/04/01.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()
    @StateObject private var localitiesStore = VisitedLocalitiesStore()
    // 現在地へ移動するためのフラグ
    @State private var centerOnUserLocation = false
    
    var body: some View {
       VStack {
           ZStack(alignment: .bottomTrailing) {
               MapView(
                   geoJSONFeatures: viewModel.geoJSONFeatures,
                   localitiesStore: localitiesStore,
                   centerOnUserLocation: $centerOnUserLocation
               )
               .onAppear {
                   viewModel.loadAllData()
               }

               // 現在地ボタン
               Button(action: {
                   centerOnUserLocation = true
               }) {
                   Image(systemName: "location.square.fill")
                       .resizable()
                       .frame(width: 40, height: 40)
                       .background(Color.white.opacity(1.0))
                       .cornerRadius(8.0)
               }
               .padding()
           }
            
            // 訪問した自治体のリストを表示する例
            List {
                ForEach(localitiesStore.localities, id: \.self) { locality in
                    Text(locality)
                }
            }
            .frame(height: 200)
       }
    }
}

#Preview {
    ContentView()
}
