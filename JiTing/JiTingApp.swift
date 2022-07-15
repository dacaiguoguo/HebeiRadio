//
//  JiTingApp.swift
//  JiTing
//
//  Created by yanguo sun on 2022/1/19.
//

import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    typealias UIViewControllerType = SFSafariViewController

    var url: URL?

    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url!)
    }

    func updateUIViewController(_ safariViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
    }
}
class User: ObservableObject {
    @Published var purl = "http://live.fm.hebrbtv.com:1935/live/zh/64K/tzwj_video.m3u8"
    @Published var index = 1
    init() {

    }
}

@main

struct JiTingApp: App {
    @StateObject var user = User()
    var body: some Scene {
        WindowGroup {
            TabView(selection:Binding(get: {
                return user.index
            }, set: { newvalue in
                user.index = newvalue
            })) {
                NavigationView {
                    ChannelListView(channelLocalDataList: load("ChannelList.json")).environmentObject(user)
                        .navigationTitle("河北广播")
                }.tabItem {
                    Image(systemName: "star")
                    Text("频道")
                }.tag(0)

                NavigationView {
//                    Text("本地")
                    SafariView(url: URL(string: user.purl))
                        .navigationTitle("河北广播")
                }.tabItem {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("本地")
                }.tag(1)
            }
        }
    }
}
