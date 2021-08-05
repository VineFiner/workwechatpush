//
//  File.swift
//  
//
//  Created by Finer  Vine on 2021/8/7.
//

import Foundation
import Vapor

struct WorkWechatController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api", "work")
        api.get(use: index(req:))
    }
    
    // http://127.0.0.1:8080/api/work?msg_signature=ASDFQWEXZCVAQFASDFASDFSS&timestamp=13500001234&nonce=123412323&echostr=ENCRYPT_STR
    func index(req: Request) throws -> EventLoopFuture<String> {
        
        struct WorkReceiveInfo: Codable {
            let msg_signature: String
            let timestamp: Int
            let nonce: String
            let echostr: String
        }
        
        let receiveInfo = try req.query.decode(WorkReceiveInfo.self)
        let replyEchoStr = DecryptMsg(msgSignature: receiveInfo.msg_signature, timeStamp: receiveInfo.timestamp, nonce: receiveInfo.nonce, echostr: receiveInfo.echostr)
        req.logger.info("\(replyEchoStr)")
        return req.eventLoop.future(replyEchoStr)
    }
    

}

extension WorkWechatController {
    // 解密函数
    func DecryptMsg(msgSignature: String, timeStamp: Int, nonce: String, echostr: String) -> String {
        return ""
    }

}
