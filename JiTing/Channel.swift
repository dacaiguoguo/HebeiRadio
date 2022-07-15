//
//  Channeler.swift
//  JiTing
//
//  Created by yanguo sun on 2022/1/19.
//

import Foundation


struct Channel: Decodable {
    var channelPic3:String = ""
    var channelPic2:String = ""
    var channelID:String = ""
    var stationId:String = ""
    var rateName:String = ""
    var channelDesc:String = ""
    var playUrl:String = ""
    var shareURL:String = ""
    var canShare:String = ""
    var playCount:String = ""
    var channelPic:String = ""
    var name:String = ""
    var fullName:String = ""
    var stationName:String = ""
    var shortName:String = ""

}

extension Channel: Identifiable {
    var id: String {
        channelID
    }
}

extension Channel {
    var iconUrl: URL {
        //http://app.fm.hebrbtv.com/bvradio_app/service/downloadResourceService_1_/cms/cms_images/tpk_add_saveImg/null/2021/08/tpk_63748200992102429412021.jpg
        URL(string: "http://app.fm.hebrbtv.com/bvradio_app/service/downloadResourceService_1_\(channelPic2)")!
    }
}

