import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }
    
    // 发送消息 http://127.0.0.1:8080/info
    app.post("info") { req -> EventLoopFuture<MessageSendResult> in
        let body = try req.content.decode(MessageInfo.self)
        return try req.workWechatClient.pushNormalInfo(message: body)
    }
    
    try app.register(collection: WorkWechatController())
}

extension MessageSendResult: Content { }
