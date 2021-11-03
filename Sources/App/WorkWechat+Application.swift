//
//  File.swift
//  
//
//  Created by vine on 2021/8/6.
//

import Foundation
import WorkWechatSDK
import Vapor

extension Application {
    // 这里是变量
    public var workWechat: WorkWechat {
        .init(application: self, logger: self.logger, eventLoop: self.eventLoopGroup.next())
    }
    
    // 这是持久化秘钥
    private struct WorkWechatCredentialsKey: StorageKey {
        typealias Value = OAuthAccountCredentials
    }
    
    // 创建客户端
    public struct WorkWechat {
        public let application: Application
        public let logger: Logger
        
        // 配置文件
        public var credentials: OAuthAccountCredentials {
            get {
                if let credentials = application.storage[WorkWechatCredentialsKey.self] {
                    return credentials
                } else {
                    fatalError("Cloud credentials configuration has not been set. Use app.microsoftGraph.credentials = ...")
                }
            }
            nonmutating set {
                if application.storage[WorkWechatCredentialsKey.self] == nil {
                    application.storage[WorkWechatCredentialsKey.self] = newValue
                } else {
                    fatalError("Overriding credentials configuration after being set is not allowed.")
                }
            }
        }
        
        /// 客户端
        public let eventLoop: EventLoop
        public var client: NormalClient {
            let new  = NormalClient.init(credentials: self.credentials, httpClient: self.http, eventLoop: self.eventLoop, logger: self.logger)
            return new
        }
        
        /// Custom `HTTPClient` that ignores unclean SSL shutdown.
        private struct WorkWechatHTTPClientKey: StorageKey, LockKey {
            typealias Value = HTTPClient
        }
        public var http: HTTPClient {
            if let existing = application.storage[WorkWechatHTTPClientKey.self] {
                return existing
            } else {
                let lock = application.locks.lock(for: WorkWechatHTTPClientKey.self)
                lock.lock()
                defer { lock.unlock() }
                if let existing = application.storage[WorkWechatHTTPClientKey.self] {
                    return existing
                }
                let new = HTTPClient(
                    eventLoopGroupProvider: .shared(application.eventLoopGroup),
                    configuration: HTTPClient.Configuration(ignoreUncleanSSLShutdown: true)
                )
                application.storage.set(WorkWechatHTTPClientKey.self, to: new) {
                    try $0.syncShutdown()
                }
                return new
            }
        }
    }
    
}

extension Request {
    private struct WorkWechatClientKey: StorageKey {
        typealias Value = NormalClient
    }
    
    public var workWechatClient: NormalClient {
        if let existing = application.storage[WorkWechatClientKey.self] {
            return existing.hopped(to: self.eventLoop)
        } else {
            let client = Application.WorkWechat.init(application: self.application, logger: self.logger, eventLoop: self.eventLoop).client
            application.storage[WorkWechatClientKey.self] = client
            return client
        }
    }
}
