//
//  File.swift
//  
//
//  Created by Finer  Vine on 2021/9/4.
//

import Foundation
import NIO
import WorkWechatSDK

extension NormalClient {
    // 这里是请求
    func pushNormalInfo(message: MessageInfo) throws -> EventLoopFuture<MessageSendResult> {
//        let body: [String: Any] = ["name": "", "folder": [:], "@microsoft.graph.conflictBehavior": "rename"]
//        let requestBody = try JSONSerialization.data(withJSONObject: body)
        let requestBody = try JSONEncoder().encode(message)
        return self.pushMessageInfo(data: requestBody)
    }
}
