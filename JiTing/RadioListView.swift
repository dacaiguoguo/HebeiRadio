//
//  ContentView.swift
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


struct RadioListView: View {
    @ObservedObject var radior:Radior
    @State var showSafari = false

    var body: some View {
        List {
            ForEach(radior.dataList) { radio in
                HStack {
                    NavigationLink(destination:SafariView(url:radio.radioUrl)) {
                        Text(radio.name)
                        Text(radio.fileSize)
                    }
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
