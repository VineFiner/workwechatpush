//
//  File.swift
//  
//
//  Created by Finer  Vine on 2021/8/7.
//

import Foundation

struct MessageInfo: Codable {
    let touser: String
    var msgtype: String = "text"
    let agentid: Int
    var safe: Int = 0
    
    let text: MessageTextContent?
    let news: MessageNewsContent?
}

/// 文本消息
struct MessageTextContent: Codable {
    let content: String
}

/// 图文消息
struct MessageNewsContent: Codable {
    let articles: [MessageNewsArticle]
    
    struct MessageNewsArticle: Codable {
        let title: String
        let description: String?
        let url: String?
        let picurl: String?
        
        let appid: String? //小程序appid，必须是与当前应用关联的小程序，appid和pagepath必须同时填写，填写后会忽略url字段
        let pagepath: String? // 点击消息卡片后的小程序页面，仅限本小程序内的页面。appid和pagepath必须同时填写，填写后会忽略url字段
    }
}
