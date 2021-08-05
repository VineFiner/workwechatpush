//
//  File.swift
//  
//
//  Created by vine on 2021/1/4.
//

import Foundation
import NIO
import AsyncHTTPClient

public class OAuthCredentialLoader {
    public static func getRefreshableToken(credentials: OAuthAccountCredentials,
                                           andClient client: HTTPClient,
                                           eventLoop: EventLoop) -> OAuthRefreshable {
        
        // Check Service account first.
        return OAuthServiceAccount.init(credentials: credentials, httpClient: client, eventLoop: eventLoop)
    }
}
