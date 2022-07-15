//
//  JiTingApp.swift
//  JiTing
//
//  Created by yanguo sun on 2022/1/19.
//

import SwiftUI

@main
struct JiTingApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationView {
                    ChannelListView(channelLocalDataList: load("ChannelList.json"))
                        .navigationTitle("河北广播")
                }.tabItem {
                    Image(systemName: "star")
                    Text("频道")
                }.tag(0)

                NavigationView {
                    ChannelListView(channelLocalDataList: load("ChannelList.json"))
                        .navigationTitle("河北广播")
                }.tabItem {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("本地")
                }.tag(1)
            }
        }
    }
}
