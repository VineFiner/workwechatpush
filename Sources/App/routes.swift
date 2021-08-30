import Vapor
import Kanna
import WorkWechatSDK

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    /* hello Call back
     curl --location --request POST 'http://127.0.0.1:8080/hello' \
     --header 'Content-Type: application/json' \
     --data-raw '{
         "toUserName": "@all",
         "fromUserName": "Vine",
         "createTime": "0",
         "msgType": "text",
         "content": "测试",
         "MsgId": "1",
         "agentId": "1000002",
     }'
     */
    app.post("hello") { req -> EventLoopFuture<CallbackTextContentInfo> in
        
        struct WorkReceiveContentInfo: Content {
            let toUserName: String
            let fromUserName: String
            let createTime: String
            let msgType: String
            let content: String
            let MsgId: String
            let agentId: String
        }
        let receive = try req.content.decode(WorkReceiveContentInfo.self)
        guard let urlPath = "https://baike.baidu.com/item/\(receive.content)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            let callback = CallbackTextContentInfo.init(ToUserName: receive.toUserName, FromUserName: receive.fromUserName, CreateTime: receive.createTime, MsgType: receive.msgType, Content: receive.content)
            return req.eventLoop.future(callback)
        }
        return req.client.get(.init(string: urlPath))
            .map { res -> CallbackTextContentInfo in
                var contentString: String = receive.content
                if let receiveXmlString = try? res.content.decode(String.self, using: PlaintextDecoder()),
                   let node = try? HTML(html: receiveXmlString, encoding: .utf8),
                   let contentElement = node.at_xpath(#"//div[@class="lemma-summary"]/div[@class="para"]"#),
                   let content = contentElement.text?.trimmingCharacters(in: .whitespacesAndNewlines)
                {
                    contentString = content + "\n" + urlPath
                    req.logger.info("\(contentString)")
                }
                let callback = CallbackTextContentInfo.init(ToUserName: receive.toUserName, FromUserName: receive.fromUserName, CreateTime: receive.createTime, MsgType: receive.msgType, Content: contentString)
                return callback
        }
    }
    
    /** 简单推送文本消息
     curl --location --request POST 'http://127.0.0.1:8080/info' \
     --header 'Content-Type: application/json' \
     --data-raw '{
         "touser": "@all",
         "msgtype": "text",
         "agentid": 1000002,
         "text": {
             "content": "我就试一下"
         },
         "safe": 0
     }'
     */
    app.post("info") { req -> EventLoopFuture<MessageSendResult> in
        let body = try req.content.decode(MessageInfo.self)
        return try req.workWechatClient.pushNormalInfo(message: body)
    }
    
    try app.register(collection: WorkWechatController())
}

// 文本消息
struct CallbackTextContentInfo: Content {
    let ToUserName: String
    let FromUserName: String
    let CreateTime: String
    let MsgType: String
    let Content: String
}

extension MessageSendResult: Content { }
