//
//  File.swift
//  
//
//  Created by Finer  Vine on 2021/8/5.
//

import Foundation
import NIO
import AsyncHTTPClient

public protocol APIRequestProtocol: AnyObject {
    var refreshableToken: OAuthRefreshable { get }
    var httpClient: HTTPClient { get }
    var responseDecoder: JSONDecoder { get }
    var currentToken: OAuthAccessToken? { get set }
    var tokenCreatedTime: Date? { get set }
    
    /// As part of an API request this returns a valid OAuth token to use with any of the .
    /// - Parameter closure: The closure to be executed with the valid access token.
    func withToken<NormalModel>(_ closure: @escaping (OAuthAccessToken) -> EventLoopFuture<NormalModel>) -> EventLoopFuture<NormalModel>
}

extension APIRequestProtocol {
    public func withToken<NormalModel>(_ closure: @escaping (OAuthAccessToken) -> EventLoopFuture<NormalModel>) -> EventLoopFuture<NormalModel> {
        guard let token = currentToken,
            let created = tokenCreatedTime,
            refreshableToken.isFresh(token: token, created: created) else {
            return refreshableToken.refresh().flatMap { newToken in
                self.currentToken = newToken
                self.tokenCreatedTime = Date()

                return closure(newToken)
            }
        }

        return closure(token)
    }

}
