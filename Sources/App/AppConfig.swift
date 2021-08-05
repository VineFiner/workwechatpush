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

    /*
     touch .env
     echo "CORP_ID=AAAAAAAAAAAAAAA" >> .env
     echo "CORP_SECRET=AAAAAAAAAA" >> .env
     */
    static var environment: AppConfig {
        guard let coprid = Environment.get("CORP_ID"),
              let corpsecret = Environment.get("CORP_SECRET")  else {
            fatalError("Please add app configuration to environment variables")
        }
        return .init(corp_id: coprid, corp_secret: corpsecret)
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

