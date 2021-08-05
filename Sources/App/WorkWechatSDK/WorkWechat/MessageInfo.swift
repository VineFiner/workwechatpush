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
    let text: MessageTextContent
    var safe: Int = 0
    
    struct MessageTextContent: Codable {
        let content: String
    }
}
