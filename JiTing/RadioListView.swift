//
//  ContentView.swift
//  JiTing
//
//  Created by yanguo sun on 2022/1/19.
//

import SwiftUI



struct RadioListView: View {
    @ObservedObject var radior:Radior
    @EnvironmentObject var user: User

    var body: some View {
        List {
            ForEach(radior.dataList) { radio in
                HStack {
                        Text(radio.name)
                        Text(radio.fileSize)

                }.onTapGesture {
                    user.purl = radio.radioUrl.absoluteString
                    user.index = 1
                }.padding()
            }
        }.task {
            do {
                let radio = try await radior.fetchRadio(url: radior.fetchUrl)
                radior.dataList = radio.vod
            } catch {

            }
        }
    }
}


struct RadioListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RadioListView(radior: Radior(channelID: "228", nodeID: "914"))
                .navigationTitle("河北广播")
        }
    }
}
