//
//  Channeler.swift
//  JiTing
//
//  Created by yanguo sun on 2022/1/19.
//

import Foundation


struct Node: Decodable {
    var BBSFavCount: String = ""
    var isLive: String = ""
    var audioCount: String = ""
    var nodePic2: String = ""
    var channelName: String = ""
    var channelID: String = ""
    var community: String = ""
    var needCheck: String = ""
    var channelRate: String = ""
    var stationId: String = ""
    var latestContent: String = ""
    var download: String = ""
    var actor: String = ""
    var channelDes: String = ""
    var type:NodeType = NodeType()
    var nodePic: String = ""
    var nodeID: String = ""
    var playCount: String = ""
    var BBSURL: String = ""
    var name: String = ""
    var shareUrl: String = ""
    var liveUrl: String = ""
    var BBSID: String = ""

    struct NodeType:Decodable {
        var name:String = ""
        var ID:String = ""
    }
}

extension Node: Identifiable {
    var id: String {
        nodeID
    }
}

extension Node {
    var iconUrl: URL {
        URL(string: nodePic2) ?? URL(string: "http://app.fm.hebrbtv.com/CMSNEWSIMG/pubNode_add_saveImg/www1/2021-08/26/pubNode_86409535914806397797435.jpg")!
    }
}


class Noder: ObservableObject {
    @Published  var nodeDataList: [Node] = []
    var channelID:String

    init(channelID: String) {
        self.channelID = channelID
    }

    var fetchUrl: URL {
        // http://i.fm.hebrbtv.com/wap/json/cms_getNodeInfo_channelID_228.json
        URL(string: "http://i.fm.hebrbtv.com/wap/json/cms_getNodeInfo_channelID_\(channelID).json")!
    }

    func fetchNodeList(url: URL) async throws -> [Node] {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
                  throw LoaderError.invalidServerResponse
              }
        do {
            let dataList = try JSONDecoder().decode([Node].self, from: data)
            return dataList
        } catch let error {
            print(error)
            return []
        }
    }
}
