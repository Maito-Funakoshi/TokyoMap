//
//  ContentView.swift
//  TokyoMap
//
//  Created by 船越舞斗 on 2025/04/01.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var viewModel = ContentViewModel()
    @StateObject private var mapViewStore = MapViewObservable()
    // 現在地へ移動するためのフラグ
    @State private var centerOnUserLocation = false
    
    @State private var showSideMenu = false // サイドメニューの状態を管理するプロパティ
    
    
    var body: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                MapView(
                    municipalitiesGeoJSONFeatures: viewModel.municipalitiesFeatures,
                    // prefecturesGeoJSONFeatures: viewModel.prefecturesFeatures,
                    mapViewStore: mapViewStore,
                    centerOnUserLocation: $centerOnUserLocation
                )
                .onAppear {
                    viewModel.loadAllData()
                }
                
                VStack {
                    // リストボタン
                    Button(action: {
                        withAnimation {
                            showSideMenu.toggle()
                        }
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .resizable()
                            .frame(width: 40, height: 28)
                            .foregroundColor(.black)
                    }
                    .padding()
                    
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
                
                // サイドメニュー
                GeometryReader { geometry in
                    NavigationView {
                        VStack(alignment: .leading, spacing: 16) {
                            // 「行った地点」セクション
                            Text("行った地点")
                                .font(.title2)
                                .bold()
                                .padding(.bottom, 8)
                            
                            List {
                                ForEach(mapViewStore.localities, id: \.self) { locality in
                                    Text(locality)
                                }
                            }
                            .listStyle(PlainListStyle()) // デフォルトスタイルを明示的に設定
                            .frame(maxHeight: 200) // 必要最低限の縦幅に制限
                            .background(Color.clear) // 背景を無色に設定
                            
                            // 「移動距離」セクション
                            Text("動いた距離")
                                .font(.title2)
                                .bold()
                            
                            Text("\(mapViewStore.totalDistance, specifier: "%.2f") m")
                                .font(.headline)
                                .padding()
                                .cornerRadius(8.0)
                            
                            Spacer()
                        }
                        .padding()
                    }
                    .frame(width: geometry.size.width / 2.5, height: geometry.size.height, alignment: .leading)
                    .background(Color.white) // 背景の半透明効果
                    .offset(x: showSideMenu ? 0 : -geometry.size.width / 2.5) // 左からスライド
                    .animation(.easeInOut(duration: 0.5), value: showSideMenu) // アニメーション追加
                    .onTapGesture {
                        withAnimation {
                            showSideMenu = false
                        }
                    }
                }
                
            }
        }
    }
}

#Preview {
    ContentView()
}
