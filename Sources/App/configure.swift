import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // 这里进行配置
    // MARK: App Config
    app.config = .environment
    
    // MARK: WorkWechat
    app.workWechat.credentials = .init(coprid: app.config.corp_id, corpsecret: app.config.corp_secret)
    
    // register routes
    try routes(app)
}
