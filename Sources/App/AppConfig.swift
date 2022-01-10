//
//  File.swift
//  
//
//  Created by vine on 2021/8/6.
//

import Foundation
import Vapor

struct AppConfig {
    let corp_id: String
    let corp_secret: String
    let encoding_aesKey: String
    let encoding_token: String
    let backend_callbackUrl: String
    
    /*
     touch .env
     echo "CORP_ID=AAAAAAAAAAAAAAA" >> .env
     echo "CORP_SECRET=AAAAAAAAAA" >> .env
     echo "ENCODING_AESKEY=AAAAAAA" >> .env
     echo "ENCODING_TOKEN=AAAAAAAA" >> .env
     echo "BACKEND_CALLBACKURL=http://127.0.0.1:8080/hello" >> .env
     */
    static var environment: AppConfig {
        guard let coprid = Environment.get("CORP_ID"),
              let corpsecret = Environment.get("CORP_SECRET"),
              let encodingAesKey = Environment.get("ENCODING_AESKEY"),
              let encodingToken = Environment.get("ENCODING_TOKEN"),
              let backendCallbackUrl = Environment.get("BACKEND_CALLBACKURL") else {
                  assertionFailure("Please add app configuration to environment variables")
                  return .init(corp_id: "",
                               corp_secret: "",
                               encoding_aesKey: "",
                               encoding_token: "",
                               backend_callbackUrl: "http://127.0.0.1:8080/hello")
              }
        
        return .init(corp_id: coprid, corp_secret: corpsecret, encoding_aesKey: encodingAesKey, encoding_token: encodingToken, backend_callbackUrl: backendCallbackUrl)
    }
}

extension Application {
    struct AppConfigKey: StorageKey {
        typealias Value = AppConfig
    }
    
    var config: AppConfig {
        get {
            storage[AppConfigKey.self] ?? .environment
        }
        set {
            storage[AppConfigKey.self] = newValue
        }
    }
}

