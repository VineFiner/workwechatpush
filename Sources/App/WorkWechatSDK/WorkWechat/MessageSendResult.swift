//
//  File.swift
//  
//
//  Created by Finer  Vine on 2021/8/7.
//

import Foundation

struct MessageSendResult: Codable {
    let errcode: Int
    let errmsg: String
    let invaliduser: String
}
