//
//  LDSinaShare.swift
//  CGYC
//
//  Created by Artron_LQQ on 2017/6/8.
//  Copyright © 2017年 Artup. All rights reserved.
//
/* 简书博客: http://www.jianshu.com/u/2846c3d3a974

 
 demo地址: https://github.com/LQQZYY/LDThirdShare-Swift
 博文讲解: http://www.jianshu.com/p/5a468f60c111
 */

import UIKit

typealias LDSinaShare_loginFailedHandle = (_ error: String) -> Void
typealias LDSinaShare_loginSuccessHandle = (_ info: [String: Any]) -> Void
typealias LDSinaShare_resultHandle = (_ isSuccess: Bool,_ info: [AnyHashable: Any]?) -> Void
class LDSinaShare: NSObject {

    static var shared: LDSinaShare = LDSinaShare()
    private override init() { }
    
    fileprivate var appKey: String = ""
    fileprivate var appSecret: String = ""
    fileprivate var oredirectUri: String = ""
    fileprivate var accessToken: String = ""
    
    fileprivate var successHandle: LDSinaShare_loginSuccessHandle? = nil
    fileprivate var failHandle: LDSinaShare_loginFailedHandle? = nil
    fileprivate var resultHandle: LDSinaShare_resultHandle? = nil
    
    /// 是否安装新浪微博客户端
    ///
    /// - Returns: true: 安装; false: 未安装
    class func isInstall() -> Bool {
        
        return WeiboSDK.isWeiboAppInstalled()
    }
    
    /// 是否支持分享到新浪微博客户端
    ///
    /// - Returns: true: 支持; false: 不支持
    class func isCanShare() -> Bool {
        return WeiboSDK.isCanShareInWeiboAPP()
    }
    
    /// 新浪微博客户端是否支持SSO授权
    ///
    /// - Returns: true: 支持; false: 不支持
    class func isSupportSSO() -> Bool {
        return WeiboSDK.isCanSSOInWeiboApp()
    }
    
    /// 注册APP
    ///
    /// - Parameters:
    ///   - appKey: appKey
    ///   - appSecret: appSecret
    ///   - oredirectUri: 授权回调URI
    ///   - isDebug: 是否开启Debug模式, 开发期建议开启
    class func registeApp(_ appKey: String, appSecret: String, oredirectUri: String, isDebug: Bool = false) {
        
        LDSinaShare.shared.appKey = appKey
        LDSinaShare.shared.appSecret = appSecret
        LDSinaShare.shared.oredirectUri = oredirectUri
        
        WeiboSDK.registerApp(appKey)
        WeiboSDK.enableDebugMode(isDebug)
    }
    
    /// 新浪微博的回调 写在func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool
    ///
    /// - Parameter url: url
    /// - Returns: return value
    class func handle(_ url: URL) -> Bool {
        // response
        return WeiboSDK.handleOpen(url, delegate: LDSinaShare.shared)
    }
    
    /// 新浪微博登录方法
    ///
    /// - Parameters:
    ///   - userInfo: 自定义用户信息, 会在响应中返回
    ///   - success: 登录成功的回调
    ///   - failsure: 登录失败的回调
    class func login(userInfo: [String: Any]? = nil, success: LDSinaShare_loginSuccessHandle? = nil, failsure: LDSinaShare_loginFailedHandle? = nil) {
        
        let request = WBAuthorizeRequest()
        request.scope = "all"
        // 此字段的内容可自定义, 在请求成功后会原样返回, 可用于校验或者区分登录来源
        request.userInfo = userInfo
        request.redirectURI = LDSinaShare.shared.oredirectUri
        
        WeiboSDK.send(request)
        
        LDSinaShare.shared.successHandle = success
        LDSinaShare.shared.failHandle = failsure
    }
    
    
//    class func cancelAuth() {
//        
//        WeiboSDK.logOut(withToken: LDSinaShare.shared.accessToken, delegate: LDSinaShare.shared, withTag: "cancel")
//    }
}
// MARK: - 分享
extension LDSinaShare {
    
    class func shareText(_ text: String, userInfo: [String: Any]? = nil, shareResultHandle: LDSinaShare_resultHandle? = nil) {
        
        let authReq = WBAuthorizeRequest()
        authReq.redirectURI = LDSinaShare.shared.oredirectUri
        authReq.scope = "all"
        
        let message = WBMessageObject()
        message.text = text
        
        let req: WBSendMessageToWeiboRequest = WBSendMessageToWeiboRequest.request(withMessage: message, authInfo: authReq, access_token: LDSinaShare.shared.accessToken) as! WBSendMessageToWeiboRequest
        // 自定义的请求信息字典， 会在响应中原样返回
        req.userInfo = userInfo
        // 当未安装客户端时是否显示下载页
        req.shouldOpenWeiboAppInstallPageIfNotInstalled = false
        
        WeiboSDK.send(req)
        LDSinaShare.shared.resultHandle = shareResultHandle
    }
    
    class func shareImage(_ imgData: Data, text: String? = nil, userInfo: [String: Any]? = nil, shareResultHandle: LDSinaShare_resultHandle? = nil) {
        
        let authReq = WBAuthorizeRequest()
        authReq.redirectURI = LDSinaShare.shared.oredirectUri
        authReq.scope = "all"
        
        let message = WBMessageObject()
        message.text = text
        
        let img = WBImageObject()
        
        // 不能超过10M
        img.imageData = imgData
        message.imageObject = img
        
        
        let req: WBSendMessageToWeiboRequest = WBSendMessageToWeiboRequest.request(withMessage: message, authInfo: authReq, access_token: LDSinaShare.shared.accessToken) as! WBSendMessageToWeiboRequest
        
        // 自定义的请求信息字典， 会在响应中原样返回
        req.userInfo = userInfo
        req.shouldOpenWeiboAppInstallPageIfNotInstalled = false // 当未安装客户端时是否显示下载页
        LDSinaShare.shared.resultHandle = shareResultHandle
        if Thread.current.isMainThread {
            WeiboSDK.send(req)
        } else {
            DispatchQueue.main.async {
                WeiboSDK.send(req)
            }
        }
        
    }
    
    class func shareWeb(_ url: String,objectID: String,  title: String, text: String? = nil, description: String? = nil, scheme: String? = nil, thumbImgData: Data? = nil, userInfo: [String: Any]? = nil, shareResultHandle: LDSinaShare_resultHandle? = nil) {
        LDSinaShare.shared.resultHandle = shareResultHandle
        
        let authReq = WBAuthorizeRequest()
        authReq.redirectURI = LDSinaShare.shared.oredirectUri
        authReq.scope = "all"
        
        let message = WBMessageObject()
        message.text = text
        
        let web = WBWebpageObject()
        
        web.objectID = objectID
        web.title = title
        web.description = description
        // 点击多媒体内容时唤起第三方应用的指定页面
        web.scheme = scheme
        
        // 预览图 不能超过32k
        web.thumbnailData = thumbImgData
        
        web.webpageUrl = url
        
        message.mediaObject = web
        
        let req: WBSendMessageToWeiboRequest = WBSendMessageToWeiboRequest.request(withMessage: message, authInfo: authReq, access_token: LDSinaShare.shared.accessToken) as! WBSendMessageToWeiboRequest
        
        // 自定义的请求信息字典， 会在响应中原样返回
        req.userInfo = userInfo
        req.shouldOpenWeiboAppInstallPageIfNotInstalled = false // 当未安装客户端时是否显示下载页
        
        WeiboSDK.send(req)
    }
}

//MARK: - WeiboSDKDelegate
extension LDSinaShare: WeiboSDKDelegate, WBHttpRequestDelegate {
    
    func request(_ request: WBHttpRequest!, didReceive response: URLResponse!) {
        
    }
    
    func request(_ request: WBHttpRequest!, didFailWithError error: Error!) {
        
    }
    
    func didReceiveWeiboRequest(_ request: WBBaseRequest!) {
        
    }
    
    func didReceiveWeiboResponse(_ response: WBBaseResponse!) {
        
        if response is WBAuthorizeResponse {
            // 微博登录
            
            if let res = response as? WBAuthorizeResponse {
               
                if res.statusCode == .success {
                    // 授权成功
                    if let uid = res.userID, let access = res.accessToken {
                        
                        self.getUserInfo(uid, accessToken: access)
                    }
                } else if res.statusCode == .userCancel {
                    // 用户取消
                    if let closure = self.failHandle {
                        closure("用户取消授权")
                    }
                } else {
                    if let closure = self.failHandle {
                        closure("授权失败")
                    }
                }
                
            } else {
                if let closure = self.failHandle {
                    closure("获取授权信息异常")
                }
            }
        } else if response is WBSendMessageToWeiboResponse {
            // 微博分享
            let rm = response as! WBSendMessageToWeiboResponse
            
            if rm.statusCode == WeiboSDKResponseStatusCode.success {
                // 成功
                
                //                let accessToken = rm.authResponse.accessToken
                //                let uid = rm.authResponse.userID
                
                let userInfo = rm.requestUserInfo // request 中设置的自定义信息
                if let rs = self.resultHandle {
                    rs(true, userInfo)
                }
            } else {
                // 失败
                if let rs = self.resultHandle {
                    rs(false, nil)
                }
            }
        }
    }
}
// MARK: - 获取授权信息
fileprivate extension LDSinaShare {
    
    func getUserInfo(_ uid: String, accessToken: String) {
        
        var info: [String: Any] = [:]
        info["uid"] = uid
        info["accessToken"] = accessToken
        self.accessToken = accessToken
        
        let queue = DispatchQueue(label: "sinaWeiboLoginQueue")
        queue.async {
            
            let urlStr = "https://api.weibo.com/2/users/show.json?uid=\(uid)&access_token=\(accessToken)&source=\(self.appKey)"
            
            let url = URL(string: urlStr)
            
            do {
                //                    let responseStr = try String.init(contentsOf: url!, encoding: String.Encoding.utf8)
                
                let responseData = try Data.init(contentsOf: url!, options: Data.ReadingOptions.alwaysMapped)
                
                let dict = try JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions.allowFragments) as? Dictionary<String, Any>
                
                guard let dic = dict else {
                    DispatchQueue.main.async {
                        if let closure = self.failHandle {
                            closure("获取授权信息异常")
                        }
                    }
                    
                    return
                }
                
                info["rawData"] = dic
                if let name = dic["name"] as? String {
                    info["nickname"] = name
                }
                
                if let sex = dic["gender"] as? String {
                    info["sex"] = sex == "m" ? "男" : "女"
                }
                
                if let img = dic["avatar_hd"] as? String {
                    info["avatarStr"] = img
                }
                
                DispatchQueue.main.async {
                    if let closure = self.successHandle {
                        
                        closure(info)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    if let closure = self.failHandle {
                        closure("获取授权信息异常")
                    }
                }
            }
        }
    }
}
