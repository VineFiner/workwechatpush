//
//  File.swift
//  
//
//  Created by vine on 2021/1/4.
//

import Foundation

public struct OAuthAccountCredentials: Codable {
    public let corp_id: String
    public let corp_secret: String
    
    public init(coprid: String, corpsecret: String ) {
        self.corp_id = coprid
        self.corp_secret = corpsecret
    }
}
