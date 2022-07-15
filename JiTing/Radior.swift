//
//  Channeler.swift
//  JiTing
//
//  Created by yanguo sun on 2022/1/19.
//

import Foundation


struct Radio: Decodable {
    var nodeID: String = ""
    var shareUrl: String = ""
    var pageSize: String = ""
    var vod: [Vod] = []
    var vodCount: String = ""
    var live: String = ""

    struct Vod: Decodable {
        var pubTime: String = ""
        var fileSize: String = ""
        var dun: String = ""
        var fileID: String = ""
        var playCount: String = ""
        var downURL: String = ""
        var name: String = ""
        var playURL: String = ""
    }
}

extension Radio: Identifiable {
    var id: String {
        nodeID
    }
}

extension Radio.Vod: Identifiable {
    var id: String {
        fileID
    }
}

extension Radio.Vod {
    var radioUrl: URL {
    // jtplayer://abcdsfl.com
        let ss = downURL.replacingOccurrences(of: "http://", with: "jtplayer://")
        return URL(string: ss) ?? URL(string: "http://app.fm.hebrbtv.com/CMSNEWSIMG/pubNode_add_saveImg/www1/2021-08/26/pubNode_86409535914806397797435.jpg")!
    }
}


class Radior: ObservableObject {
    @Published  var dataList: [Radio.Vod] = []
    var channelID:String
    var nodeID:String

    init(channelID: String, nodeID: String) {
        self.channelID = channelID
        self.nodeID = nodeID
    }

    var fetchUrl: URL {
        // http://app.fm.hebrbtv.com/bvradio_app/service/cms_getVod_size_40_nodeID_914.json
        URL(string: "http://app.fm.hebrbtv.com/bvradio_app/service/cms_getVod_size_40_nodeID_\(nodeID).json")!
    }

    func fetchRadio(url: URL) async throws -> Radio {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
                  throw LoaderError.invalidServerResponse
              }
        do {
            let dataList = try JSONDecoder().decode([Radio].self, from: data)
            guard let filet = dataList.first else {
                return Radio()
            }
            return filet
        } catch let error {
            print(error)
            return Radio()
        }
    }
}
