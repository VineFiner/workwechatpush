//
//  File.swift
//  
//
//  Created by Finer  Vine on 2021/8/5.
//

import Foundation
import AsyncHTTPClient
import Logging
import NIO

public final class NormalClient {
    var request: NormalRequest
    
    public init(credentials: OAuthAccountCredentials,  httpClient: HTTPClient, eventLoop: EventLoop, logger: Logger) {
        let refreshableToken = OAuthCredentialLoader.getRefreshableToken(credentials: credentials,
                                                                         andClient: httpClient,
                                                                         eventLoop: eventLoop)
        request = NormalRequest(httpClient: httpClient, eventLoop: eventLoop, oauth: refreshableToken)
    }
    /// Hop to a new eventloop to execute requests on.
    /// - Parameter eventLoop: The eventloop to execute requests on.
    public func hopped(to eventLoop: EventLoop) -> NormalClient {
        request.eventLoop = eventLoop
        return self
    }
}

extension NormalClient {
    
    var endpoint: String {
        return "https://qyapi.weixin.qq.com"
    }
    
    // 这里是请求
    func pushNormalInfo(message: MessageInfo) throws -> EventLoopFuture<MessageSendResult> {
        let url = "\(endpoint)/cgi-bin/message/send"
//        let body: [String: Any] = ["name": "", "folder": [:], "@microsoft.graph.conflictBehavior": "rename"]
//        let requestBody = try JSONSerialization.data(withJSONObject: body)
        let requestBody = try JSONEncoder().encode(message)
        return request.send(method: .POST, path: url, body: .data(requestBody))
    }
}
