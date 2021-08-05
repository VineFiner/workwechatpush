//
//  File.swift
//  
//
//  Created by vine on 2021/1/4.
//

import Foundation
import NIOHTTP1
import AsyncHTTPClient
import NIO

public final class OAuthServiceAccount: OAuthRefreshable {
    public let httpClient: HTTPClient
    public let credentials: OAuthAccountCredentials
    public let eventLoop: EventLoop
        
    private let decoder = JSONDecoder()
    
    init(credentials: OAuthAccountCredentials, httpClient: HTTPClient, eventLoop: EventLoop) {
        self.credentials = credentials
        self.httpClient = httpClient
        self.eventLoop = eventLoop
    }
    
    public func refresh() -> EventLoopFuture<OAuthAccessToken> {
        do {
            let headers: HTTPHeaders = ["Content-Type": "application/x-www-form-urlencoded"]
            let tokenUrl = "\(OAuthTokenAudience)?corpid=\(credentials.corp_id)&corpsecret=\(credentials.corp_secret)"
            let request = try HTTPClient.Request(url: tokenUrl, method: .GET, headers: headers)
            
            return httpClient.execute(request: request, eventLoop: .delegate(on: self.eventLoop)).flatMap { response in
                
                guard var byteBuffer = response.body,
                let responseData = byteBuffer.readData(length: byteBuffer.readableBytes),
                response.status == .ok else {
                    return self.eventLoop.makeFailedFuture(OAuthRefreshError.noResponse(response.status))
                }
                
                do {
                    let tokenModel = try self.decoder.decode(OAuthAccessToken.self, from: responseData)
                    return self.eventLoop.makeSucceededFuture(tokenModel)
                } catch {
                    return self.eventLoop.makeFailedFuture(error)
                }
            }
            
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }
}


enum OAuthRefreshError: Error {
    case noResponse(HTTPResponseStatus)
    
    var localizedDescription: String {
        switch self {
        case .noResponse(let status):
            return "A request to the OAuth authorization server failed with response status \(status.code)."
        }
    }
}
