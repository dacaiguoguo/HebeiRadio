//
//  ContentView.swift
//  JiTing
//
//  Created by yanguo sun on 2022/1/19.
//

import SwiftUI

struct NodeListView: View {
    @ObservedObject var noder:Noder

    var body: some View {
        List {
            ForEach(noder.nodeDataList) { node in
                NavigationLink(destination: RadioListView(radior: Radior(channelID: node.channelID, nodeID: node.nodeID)).navigationTitle("历史记录")) {
                    NodeRowView(node: node).padding()
                }
            }
        }.task {
            do {
                let nodeDataList = try await noder.fetchNodeList(url: noder.fetchUrl)
                noder.nodeDataList = nodeDataList
            } catch {

            }
        }
    }
}

// 频道Row
struct NodeRowView: View {
    let node: Node
    @State private var iconImage = UIImage(systemName: "photo.circle")!

    var body: some View {
//        HStack {
            Image(uiImage: self.iconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .task {
                    do {
                        self.iconImage = try await fetchPhoto(url: node.iconUrl)
                    } catch {
                        self.iconImage = UIImage(systemName: "wifi.exclamationmark")!
                    }
                }
            VStack(alignment: .leading) {
                Text(node.name)
                    .foregroundColor(.primary)
                    .font(.headline)
                Spacer()
                Text(node.nodeID)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
//            }
//            Link("Play", destination: URL(string: node.download)!).environment(\.openURL, OpenURLAction { url in
//                return .systemAction
//            })
        }
    }
}

struct NodeListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NodeListView(noder: Noder(channelID: "228"))
                .navigationTitle("河北广播")
        }
    }
}
