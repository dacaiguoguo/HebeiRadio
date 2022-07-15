//
//  ContentView.swift
//  JiTing
//
//  Created by yanguo sun on 2022/1/19.
//

import SwiftUI

struct ChannelListView: View {
    let channelLocalDataList: [Channel]

    var body: some View {
        List {
            ForEach(channelLocalDataList) { channel in
                NavigationLink(destination: NodeListView(noder: Noder(channelID: channel.channelID)).navigationTitle("频道栏目")) {
                    ChannelRowView(channel: channel).padding()
                }

            }
        }
    }
}

// 频道Row
struct ChannelRowView: View {
    let channel: Channel
    @State private var iconImage = UIImage(systemName: "photo.circle")!

    var body: some View {
//        HStack { // row 默认带有HStack
            channelImage
            channelInfo
//        }
    }

    private var channelImage: some View {
        Image(uiImage: self.iconImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 50, height: 50)
            .task {
                do {
                    self.iconImage = try await fetchPhoto(url: channel.iconUrl)
                } catch {
                    self.iconImage = UIImage(systemName: "wifi.exclamationmark")!
                }
            }
    }

    private var channelInfo: some View {
        VStack(alignment: .leading) {
            Text(channel.name)
                .foregroundColor(.primary)
                .font(.headline)
            Spacer()
            Text(channel.rateName)
                .foregroundColor(.secondary)
                .font(.subheadline)
        }
    }
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChannelListView(channelLocalDataList: load("ChannelList.json"))
                .navigationTitle("河北广播")
        }
    }
}
