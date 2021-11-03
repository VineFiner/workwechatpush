//
//  File.swift
//  
//
//  Created by Finer  Vine on 2021/8/7.
//

import Foundation
import Vapor
import Kanna
import WorkWechatSDK

struct WorkWechatController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api", "work")
        api.get(use: index(req:))
        api.post(use: receiveWeChatInfo(req:))
    }
    
    // http://127.0.0.1:8080/api/work?msg_signature=ASDFQWESADFSFSFASDFSS&timestamp=13500001234&nonce=123412323&echostr=ENCRYPT_STR
    func index(req: Request) throws -> EventLoopFuture<String> {
        
        struct WorkReceiveVerifyInfo: Codable {
            let msg_signature: String
            let timestamp: Int
            let nonce: String
            let echostr: String
        }
        
        let receiveInfo = try req.query.decode(WorkReceiveVerifyInfo.self)
        let replyEchoStr = try verifyURL(msgSignature: receiveInfo.msg_signature, timeStamp: receiveInfo.timestamp, nonce: receiveInfo.nonce, echostr: receiveInfo.echostr, logger: req.logger)
        req.logger.info("\(replyEchoStr)")
        return req.eventLoop.future(replyEchoStr)
    }
    
    /* 接收消息请求的说明
     * https://work.weixin.qq.com/api/doc/90000/90135/90241#%E5%9B%BE%E6%96%87%E6%B6%88%E6%81%AF
     */
    func receiveWeChatInfo(req: Request) throws -> EventLoopFuture<Response> {

        let receiveInfo = try req.query.decode(WorkQueryReceiveInfo.self)
        let reqData = try req.content.decode(String.self, using: PlaintextDecoder())
        req.logger.debug("req: \(req) \nreqData:\(reqData)")
        let reqContent = try WorkPostReceiveInfo.deserialize(reqData)
        
        let receiveMessageXml = try DecryptMsg(msgSignature: receiveInfo.msg_signature, timeStamp: receiveInfo.timestamp, nonce: receiveInfo.nonce, msgEncrypt: reqContent.encrypt, logger: req.logger)
        req.logger.debug("receiveMessageXml:\(receiveMessageXml)")
        
        let receiveMessage = try WorkReceiveContentInfo.deserialize(receiveMessageXml)
        req.logger.info("message:\(receiveMessage.content)")
        
        // 这里是后端回调
        return req.client.post("\(AppConfig.environment.backend_callbackUrl)") {req in
//            // Encode query string to the request URL.
//            try req.query.encode(["q": "test"])

            // Encode JSON to the request body.
            try req.content.encode(receiveMessage)
//
//            // Add auth header to the request
//            let auth = BasicAuthorization(username: "something", password: "somethingelse")
//            req.headers.basicAuthorization = auth
        }
        .flatMapThrowing { res -> (xmlContent: String, signature: String, timestamp: String, nonce: String) in
            var receiveXmlString: String = ""
            
            if let callbackJson = try? res.content.decode(WorkCallbackTextContentInfo.self) {
                receiveXmlString = callbackJson.toXml()
                req.logger.info("replayString:\(callbackJson.Content)")
            } else {
                receiveXmlString = try res.content.decode(String.self, using: PlaintextDecoder())
                req.logger.debug("replayXmlString:\(receiveXmlString)")
            }
            
            let timestamp = receiveInfo.timestamp
            let nonce = receiveInfo.nonce
            
            let replayMessage: (signature: String, xmlContent: String) = try EncryptMsg(timeStamp: timestamp, nonce: nonce, msgEncrypt: receiveXmlString, logger: req.logger)
            req.logger.debug("replayMessage:\(replayMessage.xmlContent)")
            return (replayMessage.xmlContent, replayMessage.signature, "\(timestamp)", nonce)
        }
        .flatMap { replay -> EventLoopFuture<Response> in
            return WorkResponseXML(value: """
                <xml>
                   <Encrypt><![CDATA[\(replay.xmlContent)]]></Encrypt>
                   <MsgSignature><![CDATA[\(replay.signature)]]></MsgSignature>
                   <TimeStamp>\(replay.timestamp)</TimeStamp>
                   <Nonce><![CDATA[\(replay.nonce)]]></Nonce>
                </xml>
                """).encodeResponse(for: req)
        }
    }

    struct WorkQueryReceiveInfo: Codable {
        let msg_signature: String
        let timestamp: Int
        let nonce: String
    }
    
    struct WorkPostReceiveInfo: Codable {
        let toUserName: String
        let agentId: String
        let encrypt: String
        
        static func deserialize(_ xml: String) throws -> WorkPostReceiveInfo {
            let node = try XML(xml: xml, encoding: .utf8)
            guard let toUserNameElement = node.at_xpath("//ToUserName"),
                  let toUserName = toUserNameElement.text?.trimmingCharacters(in: .whitespacesAndNewlines)  else {
                throw Abort(.badRequest, reason: "ToUserName error")
            }
            guard let encryptElement = node.at_xpath("//Encrypt"),
                  let encrypt = encryptElement.text?.trimmingCharacters(in: .whitespacesAndNewlines)  else {
                throw Abort(.badRequest, reason: "Encrypt error")
            }
            guard let agentIDElement = node.at_xpath("//AgentID"),
                  let agentID = agentIDElement.text?.trimmingCharacters(in: .whitespacesAndNewlines)  else {
                throw Abort(.badRequest, reason: "AgentID error")
            }
            return WorkPostReceiveInfo(toUserName: toUserName, agentId: agentID, encrypt: encrypt)
        }
    }
    
    struct WorkReceiveContentInfo: Content {
        let toUserName: String
        let fromUserName: String
        let createTime: String
        let msgType: String
        let content: String
        let MsgId: String
        let agentId: String
        
        static func deserialize(_ xml: String) throws -> WorkReceiveContentInfo {
            let node = try XML(xml: xml, encoding: .utf8)
            guard let toUserNameElement = node.at_xpath("//ToUserName"),
                  let toUserName = toUserNameElement.text?.trimmingCharacters(in: .whitespacesAndNewlines)  else {
                throw Abort(.badRequest, reason: "ToUserName error")
            }
            guard let fromUserNameElement = node.at_xpath("//FromUserName"),
                  let fromUserName = fromUserNameElement.text?.trimmingCharacters(in: .whitespacesAndNewlines)  else {
                throw Abort(.badRequest, reason: "FromUserName error")
            }
            guard let createTimeElement = node.at_xpath("//CreateTime"),
                  let createTime = createTimeElement.text?.trimmingCharacters(in: .whitespacesAndNewlines)  else {
                throw Abort(.badRequest, reason: "CreateTime error")
            }
            guard let msgTypeElement = node.at_xpath("//MsgType"),
                  let msgType = msgTypeElement.text?.trimmingCharacters(in: .whitespacesAndNewlines)  else {
                throw Abort(.badRequest, reason: "MsgType error")
            }
            guard let contentElement = node.at_xpath("//Content"),
                  let content = contentElement.text?.trimmingCharacters(in: .whitespacesAndNewlines)  else {
                throw Abort(.badRequest, reason: "Content error")
            }
            guard let msgIdElement = node.at_xpath("//MsgId"),
                  let msgId = msgIdElement.text?.trimmingCharacters(in: .whitespacesAndNewlines)  else {
                throw Abort(.badRequest, reason: "MsgId error")
            }
            guard let agentIDElement = node.at_xpath("//AgentID"),
                  let agentID = agentIDElement.text?.trimmingCharacters(in: .whitespacesAndNewlines)  else {
                throw Abort(.badRequest, reason: "AgentID error")
            }
            
            return WorkReceiveContentInfo(toUserName: toUserName, fromUserName: fromUserName, createTime: createTime, msgType: msgType, content: content, MsgId: msgId, agentId: agentID)
        }
    }
}

struct WorkResponseXML {
    let value: String
}

extension WorkResponseXML: ResponseEncodable {
    public func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
        var headers = HTTPHeaders()
        headers.contentType = .xml
        return request.eventLoop.makeSucceededFuture(.init(
            status: .ok, headers: headers, body: .init(string: value)
        ))
    }
}
extension WorkWechatController {
    // 验证URL
    func verifyURL(msgSignature: String, timeStamp: Int, nonce: String, echostr: String, logger: Logger) throws  -> String {
        let cpt = try WXBizJsonMsgCrypt(sToken: AppConfig.environment.encoding_token, sEncodingAESKey: AppConfig.environment.encoding_aesKey, sReceiveId: AppConfig.environment.corp_id, logger: logger)
        return try cpt.verifyURL(sMsgSignature: msgSignature, sTimeStamp: "\(timeStamp)", sNonce: nonce, sEchoStr: echostr)
    }
    
    // 解密函数
    func DecryptMsg(msgSignature: String, timeStamp: Int, nonce: String, msgEncrypt: String, logger: Logger) throws  -> String {
        let cpt = try WXBizJsonMsgCrypt(sToken: AppConfig.environment.encoding_token, sEncodingAESKey: AppConfig.environment.encoding_aesKey, sReceiveId: AppConfig.environment.corp_id, logger: logger)
        return try cpt.decryptMsg(msgSignature: msgSignature, timeStamp: "\(timeStamp)", nonce: nonce, msgEncrypt: msgEncrypt)
    }
    
    // 加密函数
    func EncryptMsg(timeStamp: Int, nonce: String, msgEncrypt: String, logger: Logger) throws  -> (signature: String, xmlContent: String) {
        let cpt = try WXBizJsonMsgCrypt(sToken: AppConfig.environment.encoding_token, sEncodingAESKey: AppConfig.environment.encoding_aesKey, sReceiveId: AppConfig.environment.corp_id, logger: logger)
        return try cpt.encryptMsg(replyMsg: msgEncrypt, timestamp: "\(timeStamp)", nonce: nonce)
    }
}

// 文本消息
struct WorkCallbackTextContentInfo: Codable {
    let ToUserName: String
    let FromUserName: String
    let CreateTime: String
    let MsgType: String
    
    let Content: String
    
    func toXml() -> String {
        """
        <xml>
           <ToUserName><![CDATA[\(ToUserName)]]></ToUserName>
           <FromUserName><![CDATA[\(FromUserName)]]></FromUserName>
           <CreateTime>\(CreateTime)</CreateTime>
           <MsgType><![CDATA[\(MsgType)]]></MsgType>
           <Content><![CDATA[\(Content)]]></Content>
        </xml>
        """
    }
}
