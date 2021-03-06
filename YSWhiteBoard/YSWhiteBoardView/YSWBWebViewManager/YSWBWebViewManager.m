//
//  YSWBWebViewManager.m
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/22.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import "YSWBWebViewManager.h"
#import "YSWKWebViewWeakDelegate.h"
#import "YSWBLogger.h"
#import <objc/message.h>

@implementation WKProcessPool (SharedProcessPool)

+ (WKProcessPool *)sharedProcessPool
{
    static WKProcessPool *SharedProcessPool;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SharedProcessPool = [[WKProcessPool alloc] init];
    });
    
    return SharedProcessPool;
}

@end

@interface YSWBWebViewManager ()
<
    WKNavigationDelegate,
    WKScriptMessageHandler,
    UIScrollViewDelegate
>

@property (nonatomic, strong) WKWebView *webView;

@property (nonatomic, copy) wbLoadFinishedBlock loadFinishedBlock;
@property (nonatomic, strong) NSString *wbWebUrl;

@property (nonatomic, strong) NSMutableDictionary *audioDic;

@end

@implementation YSWBWebViewManager

- (WKWebView *)createWhiteBoardWithFrame:(CGRect)frame
                       loadFinishedBlock:(wbLoadFinishedBlock)loadFinishedBlock
{
    return [self createWhiteBoardWithFrame:frame connectH5CoursewareUrlCookies:nil loadFinishedBlock:loadFinishedBlock];
}

- (WKWebView *)createWhiteBoardWithFrame:(CGRect)frame
connectH5CoursewareUrlCookies:(NSArray <NSDictionary *> *)connectH5CoursewareUrlCookies
            loadFinishedBlock:(wbLoadFinishedBlock)loadFinishedBlock
{
    self.loadFinishedBlock = loadFinishedBlock;
    self.wbWebUrl = @"/publish/index.html#/mobileApp?languageType=ch";

    [self createWKWebViewWithFrame:frame connectH5CoursewareUrlCookies:connectH5CoursewareUrlCookies];

    return self.webView;
}

- (void)createWKWebViewWithFrame:(CGRect)frame connectH5CoursewareUrlCookies:(NSArray <NSDictionary *> *)connectH5CoursewareUrlCookies
{
    WKWebView *webView =
        [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)
                           configuration:[self createWKWebViewConfiguration]];
    self.webView = webView;
    
    webView.backgroundColor            = [UIColor clearColor];
    webView.userInteractionEnabled     = YES;
    webView.navigationDelegate         = self;
    webView.scrollView.delegate        = self;
    webView.scrollView.scrollEnabled   = NO;
    webView.scrollView.backgroundColor = [UIColor clearColor];

    webView.opaque = NO;

    // 禁用长按出现粘贴复制的问题
    NSMutableString *javascript = [NSMutableString string];
    // 禁止长按
    [javascript
        appendString:@"document.documentElement.style.webkitTouchCallout='none';"];
    // 禁止选择
    [javascript appendString:@"document.documentElement.style.webkitUserSelect='none';"];
    // 背景透明 需要opaque = NO
    [javascript appendString:@"document.body.style.backgroundColor=rgba(0,0,0,0);"];

    WKUserScript *noneSelectScript =
        [[WKUserScript alloc] initWithSource:javascript
                               injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                            forMainFrameOnly:YES];
    [webView.configuration.userContentController addUserScript:noneSelectScript];

#ifdef __IPHONE_11_0
    if ([webView.scrollView respondsToSelector:@selector(setContentInsetAdjustmentBehavior:)]) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
        //if (@available(iOS 11.0, *)) {
            [webView.scrollView
                setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
        }
    }
#endif

#if IS_LOAD_LOCAL_INDEX
    // 加载本地的h5文件
    NSURL *path =
        [YSWBBUNDLE URLForResource:@"react_mobile_new_publishdir/index" withExtension:@"html"];
//    NSString *urlStr = [NSString
//        stringWithFormat:@"%@#/mobileApp?languageType=%@&loadComponentName=%@", path.absoluteString,
//                         [self getCurrentLanguage], loadComponentName];
    NSString *urlStr = [NSString
        stringWithFormat:@"%@?debug=false", path.absoluteString];

#else
//    NSString *urlStr = [NSString stringWithFormat:@"http://%@%@&loadComponentName=%@", PointToHost,
//                                                  _sEduWhiteBoardUrl, loadComponentName];
    NSString *urlStr = [NSString
        stringWithFormat:@"http://%@/index.html?debug=false", PointToHost];

#endif

    NSURL *url = [NSURL URLWithString:urlStr];

    // 清理
    [self clearcookie:webView];

    // 添加cookie
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
    //if (@available(iOS 11.0, *)) {
        WKHTTPCookieStore *cookieStore = _webView.configuration.websiteDataStore.httpCookieStore;
        //get cookies
        for (NSDictionary *cookieDic in connectH5CoursewareUrlCookies)
        {
            NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieDic];
            [cookieStore setCookie:cookie completionHandler:nil];
        }
    }
    else
    {
        NSHTTPCookieStorage *cookieStore = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (NSDictionary *cookieDic in connectH5CoursewareUrlCookies)
        {
            NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieDic];
            [cookieStore setCookie:cookie];
        }
    }

    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView loadRequest:request];
}

- (void)clearcookie:(WKWebView *)webView
{
    // 清除cookies
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
    }
    else
    {
        NSHTTPCookie *cookie;
        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (cookie in [storage cookies])
        {
            [storage deleteCookie:cookie];
        }
    }

    // 清除UIWebView的缓存
    NSURLCache *cache = [NSURLCache sharedURLCache];
    [cache removeAllCachedResponses];
    [cache setDiskCapacity:0];
    [cache setMemoryCapacity:0];

    // 清除部分，可以自己设置
    // NSSet *websiteDataTypes= [NSSet setWithArray:types];
    // 清除所有
    NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
    //// Date from
    NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
    //// Execute
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
        // Done
        NSLog(@"清除缓存完毕");
    }];
    
    // webview暂停加载
    [webView stopLoading];
}

- (WKWebViewConfiguration *)createWKWebViewConfiguration
{
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];

    // 设置偏好设置
    config.preferences = [[WKPreferences alloc] init];
    // 默认为0
    config.preferences.minimumFontSize = 10;
    // 默认认为YES
    config.preferences.javaScriptEnabled = YES;
    // 在iOS上默认为NO，表示不能自动通过窗口打开
    config.preferences.javaScriptCanOpenWindowsAutomatically = NO;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
    //if (@available(iOS 9.0, *)) {

        [config.preferences setValue:@(YES) forKey:@"allowFileAccessFromFileURLs"]; //跨域
    }
    // web内容处理池
    config.processPool = [WKProcessPool sharedProcessPool];
    
    /*
     @property (nonatomic) BOOL mediaPlaybackRequiresUserAction
     API_DEPRECATED_WITH_REPLACEMENT("requiresUserActionForMediaPlayback", ios(8.0, 9.0));
     @property (nonatomic) BOOL mediaPlaybackAllowsAirPlay
     API_DEPRECATED_WITH_REPLACEMENT("allowsAirPlayForMediaPlayback", ios(8.0, 9.0));
     @property (nonatomic) BOOL requiresUserActionForMediaPlayback
     API_DEPRECATED_WITH_REPLACEMENT("mediaTypesRequiringUserActionForPlayback", ios(9.0, 10.0));
     */

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
    //if (@available(iOS 8.0, *)) {
        config.mediaPlaybackRequiresUserAction =
            NO;                                  //把手动播放设置NO ios(8.0,
                                                 //9.0)，这个属性决定了HTML5视频可以自动播放还是需要用户启动播放。iPhone和iPad默认都是YES。
        config.mediaPlaybackAllowsAirPlay = YES; //允许播放，ios(8.0, 9.0)
    }

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
    //if (@available(iOS 9.0, *)) {
        // ios 默认yes ios9
        // ios9 ios 10 A Boolean value indicating whether HTML5 videos require the user to start
        // playing them (YES) or whether the videos can be played automatically (NO).
        config.requiresUserActionForMediaPlayback = NO;
        config.allowsAirPlayForMediaPlayback      = YES;
    }

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0) {
    //if (@available(iOS 10.0, *)) {
        // ios10 Determines which media types require a user gesture to begin playing
        config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    }
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
    //if (@available(iOS 11.0, *)) {
        config.preferences.minimumFontSize = 0;
    }
    //是否允许内联(YES)或使用本机全屏控制器(NO)，默认是NO。A Boolean value indicating whether HTML5
    //videos play inline (YES) or use the native full-screen controller (NO).
    config.allowsInlineMediaPlayback = YES;

    config.userContentController = [self createWKUserContentController];
    
    return config;
}

- (WKUserContentController *)createWKUserContentController
{
    //注册handler
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    
    BMWeakSelf
    YSWKWebViewWeakDelegate *weakWeb = [[YSWKWebViewWeakDelegate alloc] initWithDelegate:weakSelf];

    [userContentController addScriptMessageHandler:weakWeb name:sYSSignalPubMsg];
    [userContentController addScriptMessageHandler:weakWeb name:sYSSignalDelMsg];
    [userContentController addScriptMessageHandler:weakWeb name:sYSSignalOnPageFinished];
    [userContentController addScriptMessageHandler:weakWeb name:sYSSignalPrintLogMessage];
    [userContentController addScriptMessageHandler:weakWeb name:sYSSignalPublishNetworkMedia];
    [userContentController addScriptMessageHandler:weakWeb name:sYSSignalSetProperty];
    [userContentController addScriptMessageHandler:weakWeb name:sYSSignalChangeWebPageFullScreen];
    [userContentController addScriptMessageHandler:weakWeb name:sYSSignalSendActionCommand];
    [userContentController addScriptMessageHandler:weakWeb name:sYSSignalSaveValueByKey];
    [userContentController addScriptMessageHandler:weakWeb name:sYSSignalGetValueByKey];
    [userContentController addScriptMessageHandler:weakWeb name:sYSSignalOnJsPlay];

    return userContentController;
}


#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message
{
    // 打印所传过来的参数，只支持NSNumber, NSString, NSDate, NSArray,
    // NSDictionary, and NSNull类型
    WB_INFO(@"userContentController message.name:%@, message.body:%@", message.name, message.body);
    
    if ([message.name isEqualToString:sYSSignalPubMsg])
    {
        [self onJsPubMsg:message.body];
    }
    else if ([message.name isEqualToString:sYSSignalDelMsg])
    {
        [self onJsDelMsg:message.body];
    }
    // 页面加载完成
    else if ([message.name isEqualToString:sYSSignalOnPageFinished])
    {
        [self onJsPageFinished];
    }
    else if ([message.name isEqualToString:sYSSignalPrintLogMessage])
    {
        //[self printLogMessage:message.name aMessageBody:message.body];
    }
    else if ([message.name isEqualToString:sYSSignalPublishNetworkMedia])
    {
        [self onJsPublishNetworkMedia:message.body];
    }
    else if ([message.name isEqualToString:sYSSignalUnpublishNetworkMedia])
    {

    }
    // 全屏
    else if ([message.name isEqualToString:sYSSignalChangeWebPageFullScreen])
    {
        //[self ChangeWebPageFullScreen:message.name aMessageBody:message.body];
    }
    else if ([message.name isEqualToString:sYSSignalSetProperty])
    {
        [self setJsProperty:message.body];

    }
    else if ([message.name isEqualToString:sYSSignalSendActionCommand])
    {
        [self sendActionCommand:message.name aMessageBody:message.body];
    }
    else if ([message.name isEqualToString:sYSSignalSaveValueByKey])
    {
        [self saveVlueByKey:message.body];
    }
    else if ([message.name isEqualToString:sYSSignalGetValueByKey])
    {
        [self getValueByKey:message.body];
    }
    else if ([message.name isEqualToString:sYSSignalOnJsPlay])
    {
        [self onJsPlay:message.body];
    }
}

- (void)onJsPubMsg:(NSDictionary *)aJs
{
    NSString *msgString = [aJs bm_stringForKey:@"data"];
    if (![msgString bm_isNotEmpty])
    {
        return;
    }
    
    NSMutableDictionary *msgDic = [NSMutableDictionary dictionaryWithDictionary:[YSRoomUtil convertWithData:msgString]];
    if (![msgDic bm_isNotEmptyDictionary])
    {
        return;
    }

    NSString *msgName = [msgDic bm_stringForKey:@"name"];
    if ([msgName isEqualToString:sYSSignalShowPage] || [msgName isEqualToString:sYSSignalExtendShowPage])
    {
        id data = msgDic[@"data"];
        NSDictionary *dic = [YSRoomUtil convertWithData:data];
        
        NSMutableDictionary *dataDic = [NSMutableDictionary dictionaryWithDictionary:dic];
        NSMutableDictionary *filedata =
            [NSMutableDictionary dictionaryWithDictionary:dataDic[@"filedata"]];
        [filedata removeObjectForKey:@"baseurl"];

        [dataDic setObject:filedata forKey:@"filedata"];
        
        NSString *dataString = [dataDic bm_toJSON];
        
        [msgDic bm_setString:dataString forKey:@"data"];
    }

    NSString *msgId = [msgDic bm_stringForKey:@"id"];
    NSString *toId = [msgDic bm_stringForKey:@"toID"];
    NSString *tData = [msgDic bm_stringForKey:@"data"];
    NSString *associatedMsgID  = [msgDic bm_stringForKey:@"associatedMsgID"];
    NSString *associatedUserID = [msgDic bm_stringForKey:@"associatedUserID"];
    NSDictionary *expandParams = [msgDic bm_dictionaryForKey:@"expandParams"];

    if ([msgName isEqualToString:sYSSignalShowPage] || [msgName isEqualToString:sYSSignalExtendShowPage])
    {
        toId = YSRoomPubMsgTellAll;
        [self stopPlayMp3];
    }

    NSMutableDictionary *pubDict = [NSMutableDictionary dictionary];
    [pubDict setValue:associatedMsgID forKey:@"associatedMsgID"];
    [pubDict setValue:associatedUserID forKey:@"associatedUserID"];
    if (expandParams)
    {
        [pubDict addEntriesFromDictionary:expandParams];
    }
    
    NSLog(@"onPubMsg msgName:%@", msgName);
#warning onJsPubMsg
    [[YSRoomInterface instance] pubMsg:msgName
                                 msgID:msgId
                                  toID:toId
                                  data:tData
                                  save:YES
                         extensionData:pubDict
                       associatedMsgID:associatedMsgID
                      associatedUserID:associatedUserID
                               expires:0
                            completion:nil];
}

- (void)onJsDelMsg:(NSDictionary *)aJs
{
    NSString *msgString = [aJs bm_stringForKey:@"data"];
    if (![msgString bm_isNotEmpty])
    {
        return;
    }
    
    NSDictionary *msgDic = [YSRoomUtil convertWithData:msgString];
    if (![msgDic bm_isNotEmptyDictionary])
    {
        return;
    }

    NSString *msgName = [msgDic bm_stringForKey:@"name"];
    NSString *msgId = [msgDic bm_stringForKey:@"id"];
    NSString *toId = [msgDic bm_stringForKey:@"toID"];
    NSString *data = [msgDic bm_stringForKey:@"data"];

    BOOL isCanDraw = [YSRoomInterface instance].localUser.canDraw;
    BOOL isTeacher = ([YSRoomInterface instance].localUser.role == YSUserType_Teacher);
    BOOL isSharpsChangeMsg = [msgName isEqualToString:sYSSignalSharpsChange];
    BOOL isBeginClass = [YSWhiteBoardManager shareInstance].isBeginClass;
    BOOL isCanSend = (isBeginClass && ((isCanDraw && isSharpsChangeMsg) || isTeacher));
    if (!isCanSend)
    {
        return;
    }

    [[YSRoomInterface instance] delMsg:msgName msgID:msgId toID:toId data:data completion:nil];
}

#pragma mark 页面加载完成

- (void)onJsPageFinished
{
    NSMutableDictionary *msgDic = [NSMutableDictionary dictionary];

    msgDic[@"languageType"] = [YSRoomUtil getCurrentLanguage];
    msgDic[@"deviceType"] = BMIS_IPHONE ? @"phone" : @"pad";
    msgDic[@"debugLog"] = @(false);

    // 文档(主白板)
    // isSendLogMessageToProtogenesis clientType 字段 外层和 mobileInfo下 都是有用的，不能去重
    msgDic[@"mobileInfo"] = @{ @"isSendLogMessageToProtogenesis" : @(false), @"clientType" : @"ios" };
    msgDic[@"isSendLogMessageToProtogenesis"] = @(false);
    msgDic[@"clientType"] = @"ios";
    msgDic[@"playback"] = [YSWhiteBoardManager shareInstance].configration[YSWhiteBoardPlayBackKey];

    [self onPagefinishSendJSMessage:msgDic];
}

- (void)onPagefinishSendJSMessage:(NSDictionary *)msgDic
{
    if (![msgDic bm_isNotEmptyDictionary])
    {
        return;
    }
    
#if 1
    
    if (self.loadFinishedBlock)
    {
        self.loadFinishedBlock();
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(onWBWebViewManagerPageFinshed)])
    {
        [self.delegate onWBWebViewManagerPageFinshed];
    }

#else
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:msgDic
                                                   options:0
                                                     error:nil];
    NSString *strMsg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *js   = [NSString stringWithFormat:@"JsSocket.%@(%@)", WBFakeJsSdkInitInfo, strMsg];

    WB_INFO(@"evaluateJS - onPagefinish - %@", msgDic);

    BMWeakSelf
    [self.webView evaluateJavaScript:js completionHandler:^(id _Nullable response, NSError *_Nullable error) {
        
        if (weakSelf.loadFinishedBlock)
        {
            weakSelf.loadFinishedBlock();
        }
        
        // 尝试开始 预加载
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(onWBWebViewManagerPageFinshed)])
        {
            [weakSelf.delegate onWBWebViewManagerPageFinshed];
        }
    }];
#endif
}
/// app中play PPT中的media
- (void)onJsPublishNetworkMedia:(NSDictionary *)videoData
{
    //    publishNetworkMediaJson = {url:url , audio:audio , video:video
    //    ,attributes:{source:'dynamicPPT' , filename:filename , fileid:fileid , toID:toID ,
    //    type:'media' } }

    if (![videoData bm_isNotEmptyDictionary])
    {
        return;
    }
    
    NSString *tDataString = [videoData bm_stringForKey:@"data"];
    NSDictionary *dataDic = [YSRoomUtil convertWithData:tDataString];
    
    if ([[dataDic bm_stringForKey:@"type"] isEqualToString:@"audio"])
    {
        [self onJsPlayMp3:dataDic];
        return;
    }

    NSString *url = [dataDic bm_stringForKey:@"url"];
    BOOL isvideo = [dataDic bm_boolForKey:@"video"];
    NSMutableDictionary *param = [NSMutableDictionary dictionaryWithDictionary:[dataDic bm_dictionaryForKey:@"attributes"]];
    NSString *fileID = [param bm_stringForKey:@"fileid"];
    NSString *whiteboardID = [YSRoomUtil getwhiteboardIDFromFileId:fileID];

    [param setObject:whiteboardID forKey:@"whiteboardId"];
    [param removeObjectForKey:@"instanceId"];
    
//    NSString *fileId = [NSString stringWithFormat:@"%@_video", [param bm_stringForKey:@"fileid"]];
//    NSMutableDictionary *paramDic = [NSMutableDictionary dictionaryWithDictionary:param];
//    [paramDic bm_setString:fileId forKey:@"fileid"];

    if ([YSWhiteBoardManager shareInstance].mediaFileModel)
    {
        [[YSRoomInterface instance] stopShareMediaFile:^(NSError *error) {
            if (!error)
            {
                NSString *toID;
                if ([YSWhiteBoardManager shareInstance].isBeginClass)
                {
                    toID = YSRoomPubMsgTellAll;
                }
                else
                {
                    toID = [YSRoomInterface instance].localUser.peerID;
                }
                [[YSRoomInterface instance] startShareMediaFile:url
                                                      isVideo:isvideo
                                                         toID:toID
                                                   attributes:param
                                                        block:nil];
            }
        }];
    }
    else
    {
        NSString *toID;
        if ([YSWhiteBoardManager shareInstance].isBeginClass)
        {
            toID = YSRoomPubMsgTellAll;
        }
        else
        {
            toID = [YSRoomInterface instance].localUser.peerID;
        }
        [[YSRoomInterface instance] startShareMediaFile:url
                                              isVideo:isvideo
                                                 toID:toID
                                           attributes:param
                                                block:nil];
    }
}

- (NSMutableDictionary *)audioDic
{
    if (!_audioDic)
    {
        _audioDic = [NSMutableDictionary dictionary];
    }
    
    return _audioDic;
}

- (void)onJsPlayMp3:(NSDictionary *)videoData
{
    NSDictionary *dic = [videoData bm_dictionaryForKey:@"other"];

    NSString *url = [videoData bm_stringForKey:@"url"];
    NSString *audioElementId = [dic bm_stringForKey:@"audioElementId" withDefault:@""];
    NSString *key = [NSString stringWithFormat:@"%@-%@", url, audioElementId];
    NSString *resumeKey = [NSString stringWithFormat:@"resume%@-%@", url, audioElementId];

    NSLog(@"onJsPlayMp3 %@", videoData);
    
    if ([videoData bm_boolForKey:@"isPlay"])
    {
        int oldPlayerId = (int)[self.audioDic bm_intForKey:key];
        if (oldPlayerId > -1)
        {
            if ([self.audioDic bm_boolForKey:resumeKey])
            {
                [[YSRoomInterface instance] resumePlayMedia:oldPlayerId];
                [self.audioDic removeObjectForKey:resumeKey];
            }
            else
            {
                [[YSRoomInterface instance] stopPlayMediaFile:oldPlayerId];
                
                NSInteger playerId = [[YSRoomInterface instance] startPlayMediaFile:url window:nil loop:NO progress:nil];
                if (playerId > -1)
                {
                    [self.audioDic bm_setInteger:playerId forKey:key];
                }
            }
        }
        else
        {
            NSInteger playerId = [[YSRoomInterface instance] startPlayMediaFile:url window:nil loop:NO progress:nil];
            if (playerId > -1)
            {
                [self.audioDic bm_setInteger:playerId forKey:key];
            }
        }
    }
    else
    {
        int oldPlayerId = (int)[self.audioDic bm_intForKey:key];
        if (oldPlayerId > -1)
        {
            NSString *current  = [dic[@"currentTime"] description];
            NSString *duration = [dic[@"duration"] description];
            if ([current isEqualToString:duration] == NO)
            {
                [self.audioDic bm_setBool:YES forKey:resumeKey];
                [[YSRoomInterface instance] pausePlayMedia:oldPlayerId];
            }
        }
    }
}

// 翻页停止播放媒体MP3
- (void)stopPlayMp3
{
    if (self.audioDic.count > 0)
    {
        for (NSNumber *num in self.audioDic.allValues)
        {
            [[YSRoomInterface instance] stopPlayMediaFile:[num intValue]];
        }
    }
    
    [self.audioDic removeAllObjects];
}

- (void)setJsProperty:(id)aMessageBody
{
    if (![aMessageBody bm_isNotEmptyDictionary])
    {
        return;
    }
    
    NSString *tDataString = [aMessageBody bm_stringForKey:@"data"];
    if (!tDataString)
    {
        return;
    }
    
    NSDictionary *msgDic = [YSRoomUtil convertWithData:tDataString];

    NSString *peerId = [msgDic bm_stringForKey:@"id"];
    [[YSRoomInterface instance] changeUserProperty:peerId
                                        tellWhom:YSRoomPubMsgTellAll
                                            data:msgDic[@"properties"]
                                      completion:nil];
}

- (void)sendActionCommand:(id)messageName aMessageBody:(id)aMessageBody
{
    if (![aMessageBody bm_isNotEmptyDictionary])
    {
        return;
    }

    NSString *tDataString = [aMessageBody bm_stringForKey:@"data"];
    NSDictionary *msgDic = [YSRoomUtil convertWithData:tDataString];
    if (![msgDic bm_isNotEmptyDictionary])
    {
        return;
    }
    
    NSString *action = [msgDic bm_stringForKey:@"action"];
    NSDictionary *dic = [msgDic bm_dictionaryForKey:@"cmd"];
    
#pragma mark 文档状态更新
    // 文档状态更新
    if ([action isEqualToString:WBViewStateUpdate])
    {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(onWBWebViewManagerStateUpdate:)])
        {
            [self.delegate onWBWebViewManagerStateUpdate:dic];
        }
    }
    else if ([action isEqualToString:WBDocumentLoadSuccessOrFailure])
    {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(onWBWebViewManagerLoadedState:)])
        {
            [self.delegate onWBWebViewManagerLoadedState:dic];
        }
    }
    else if ([action isEqualToString:WBDocumentSlideLoadTimeout])
    {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(onWBWebViewManagerSlideLoadTimeout:)])
        {
            [self.delegate onWBWebViewManagerSlideLoadTimeout:dic];
        }
    }

#pragma mark preloadingFished 预加载文档结束
    
    // 预加载文档结束
    else if ([action isEqualToString:WBPreloadingFished])
    {
        WB_INFO(@"evaluateJS - preFinish - %@", msgDic);

//        if (self.delegate &&
//            [self.delegate respondsToSelector:@selector(onWBWebViewManagerPreloadingFished)])
//        {
//            [self.delegate onWBWebViewManagerPreloadingFished];
//        }
    }
}

- (void)saveVlueByKey:(id)aMessageBody
{
    if (![aMessageBody bm_isNotEmptyDictionary])
    {
        return;
    }

    NSDictionary *dic     = (NSDictionary *)aMessageBody;
    NSString *tDataString = [dic objectForKey:@"data"];
    
    NSDictionary *msgDic = [YSRoomUtil convertWithData:tDataString];
    
    NSString *key = [msgDic bm_stringForKey:@"key"];
    NSString *value = [msgDic bm_stringForKey:@"value"];
    if (key && value)
    {
        [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    }
}

- (void)getValueByKey:(id)aMessageBody
{
    if (![aMessageBody bm_isNotEmptyDictionary])
    {
        return;
    }

    NSDictionary *dic     = (NSDictionary *)aMessageBody;
    NSString *tDataString = [dic objectForKey:@"data"];
    
    NSDictionary *msgDic = [YSRoomUtil convertWithData:tDataString];

    NSString *callbackID = [msgDic bm_stringForKey:@"callbackID"];
    NSString *strM = nil;
    NSString *key = [msgDic bm_stringForKey:@"key"];
    if (key)
    {
        strM = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    }
    if (![strM bm_isNotEmpty])
    {
        return;
    }
    
    NSString *js = [NSString stringWithFormat:@"JsSocket.JsSocketCallback('%@',%@)", callbackID, strM];
    
    if (self.webView)
    {
        [self.webView evaluateJavaScript:js
                   completionHandler:^(id _Nullable response, NSError *_Nullable error){}];
    }
}

- (void)onJsPlay:(NSDictionary *)aMessageBody
{
    if (![aMessageBody bm_isNotEmptyDictionary])
    {
        return;
    }

    [self onJsPublishNetworkMedia:aMessageBody];
}


#pragma -
#pragma mark Function

- (void)sendSignalMessageToJS:(NSString *)signalingName message:(nullable id)message
{
    NSString *msgName = nil;
    NSDictionary *dataDic = nil;
    
    if ([signalingName isEqualToString:WBPubMsg] || [signalingName isEqualToString:WBDelMsg])
    {
        // 信令转发时大部分有message
        if ([message bm_isNotEmptyDictionary])
        {
            msgName = [message bm_stringForKey:@"name"];
            if (msgName != nil)
            {
                // 只转发 ClassBegin， ShowPage  和 H5DocumentAction， NewPptTriggerActionClick 四种信令
                if (![msgName isEqualToString:sYSSignalShowPage] && ![msgName isEqualToString:sYSSignalExtendShowPage] && ![msgName isEqualToString:sYSSignalH5DocumentAction] && ![msgName isEqualToString:sYSSignalNewPptTriggerActionClick] && ![msgName isEqualToString:sYSSignalClassBegin])
                {
                    return;
                }
                
                id data = [message objectForKey:@"data"];
                dataDic = [YSRoomUtil convertWithData:data];
                
                if ([signalingName isEqualToString:WBDelMsg])
                {
                    msgName = [NSString stringWithFormat:@"\"%@\"", msgName];
                    // WBDelMsg只发送信令名
                    NSString *jsReceivePhoneByTriggerEvent = [NSString stringWithFormat:@"JsSocket.%@(%@)", signalingName, msgName];
                    [self sendMessageToJS:jsReceivePhoneByTriggerEvent];
                    return;
                }
            }
        }
    }
    else if ([signalingName isEqualToString:WBSetProperty])
    {
        // 不再发送WBSetProperty，改变自己的sUserCandraw时发送WBUpdatePermission
        if ([message bm_isNotEmptyDictionary])
        {
            NSDictionary *properties = [message bm_dictionaryForKey:@"properties"];
            NSString *peerId = [message bm_stringForKey:@"id"];
            // sYSUserCandraw
            if ([properties bm_containsObjectForKey:sYSUserCandraw])
            {
                NSString *localUserPeerID = [YSRoomInterface instance].localUser.peerID;
                if ([peerId isEqualToString:localUserPeerID])
                {
                    BOOL canDraw = [properties bm_boolForKey:sYSUserCandraw];

                    signalingName = WBUpdatePermission;
                    message = canDraw ? @"1" : @"0";

                    NSString *jsReceivePhoneByTriggerEvent =
                        [NSString stringWithFormat:@"JsSocket.%@(%@)", signalingName, message];
                    [self sendMessageToJS:jsReceivePhoneByTriggerEvent];
                }
            }
        }
        return;
    }
    
    if (dataDic)
    {
        message = dataDic;
    }
    
    NSString *tJsonDataJsonString;
    if (message)
    {
        if ([message isKindOfClass:[NSString class]])
        {
            tJsonDataJsonString = message;
        }
        else
        {
            NSData *tJsonData = [NSJSONSerialization dataWithJSONObject:message
                                                                options:0
                                                                  error:nil];
            tJsonDataJsonString =
                [[NSString alloc] initWithData:tJsonData encoding:NSUTF8StringEncoding];
        }
    }
    else
    {
        tJsonDataJsonString = @"";
    }

    NSString *jsReceivePhoneByTriggerEvent = nil;
    if (msgName)
    {
        msgName = [NSString stringWithFormat:@"\"%@\"", msgName];
        if (message)
        {
            jsReceivePhoneByTriggerEvent = [NSString stringWithFormat:@"JsSocket.%@(%@,%@)", signalingName, msgName, tJsonDataJsonString];
        }
        else
        {
            jsReceivePhoneByTriggerEvent = [NSString stringWithFormat:@"JsSocket.%@(%@)", signalingName, msgName];
        }
    }
    else
    {
        jsReceivePhoneByTriggerEvent = [NSString stringWithFormat:@"JsSocket.%@(%@)", signalingName, tJsonDataJsonString];
    }

    [self sendMessageToJS:jsReceivePhoneByTriggerEvent];
}

- (void)sendMessageToJS:(NSString *)message
{
    WB_INFO(@"evaluateJS - msg - %@", message);
    [self.webView evaluateJavaScript:message
               completionHandler:^(id _Nullable id, NSError *_Nullable error){
               }];
}

- (void)sendAction:(NSString *)action command:(NSDictionary *)cmd
{
    NSString *tJsonDataJsonString;
    NSString *jsReceivePhoneByTriggerEvent;

    if (cmd)
    {
        NSData *tJsonData = [NSJSONSerialization dataWithJSONObject:cmd
                                                            options:0
                                                              error:nil];

        tJsonDataJsonString =
            [[NSString alloc] initWithData:tJsonData encoding:NSUTF8StringEncoding];

        jsReceivePhoneByTriggerEvent =
            [NSString stringWithFormat:@"JsSocket.%@('%@',%@)", sYSSignalReceiveActionCommand, action,
                                       tJsonDataJsonString];
    }
    else
    {
        jsReceivePhoneByTriggerEvent =
            [NSString stringWithFormat:@"JsSocket.%@('%@')", sYSSignalReceiveActionCommand, action];
    }

    WB_INFO(@"evaluateJS - Action - %@ - %@ - %@", action, cmd, jsReceivePhoneByTriggerEvent);
    [self.webView evaluateJavaScript:jsReceivePhoneByTriggerEvent
               completionHandler:^(id _Nullable id, NSError *_Nullable error){
               }];
}

#pragma mark - WKNavigationDelegate

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView
    API_AVAILABLE(macosx(10.11), ios(9.0))
{
    WB_INFO(@"WKWebView 总体内存占用过大，页面即将白屏");
    
    [self webViewreload];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return nil;
}

// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    WB_INFO(@"页面开始加载");
}

// 当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    WB_INFO(@"当内容开始返回时调用");
}

// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    WB_INFO(@"页面加载完成");
    
    // 禁止网页手势缩放
    NSString *injectionJSString = @"var script = document.createElement('meta');"
    "script.name = 'viewport';"
    "script.content=\"width=device-width, user-scalable=no\";"
    "document.getElementsByTagName('head')[0].appendChild(script);";
    [webView evaluateJavaScript:injectionJSString completionHandler:nil];
}

// 提交发生错误时调用
- (void)webView:(WKWebView *)webView
    didFailNavigation:(WKNavigation *)navigation
            withError:(NSError *)error
{
    WB_INFO(@"页面加载失败：%@", error.debugDescription);
}

// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation
{
    WB_INFO(@"页面加载失败时调用");
}

//  接收到服务器跳转请求之后调用
- (void)webView:(WKWebView *)webView
    didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation
{
    WB_INFO(@"接收到服务器跳转请求之后调用");
}

//  在收到响应后，决定是否跳转
- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
                      decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    WB_INFO(@"在收到响应后，决定是否跳转");
    decisionHandler(WKNavigationResponsePolicyAllow);
}

//  在发送请求之前，决定是否跳转
- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                    decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURL *url = navigationAction.request.URL;
    if ([url.absoluteString hasPrefix:@"about"]) {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
    WB_INFO(@"在发送请求之前，决定是否跳转");
}

// 允许证书
- (void)webView:(WKWebView *)webView
    didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
                    completionHandler:
                        (void (^)(NSURLSessionAuthChallengeDisposition disposition,
                                  NSURLCredential *__nullable credential))completionHandler
{
    WB_INFO(@"%s", __FUNCTION__);

    WB_INFO(@"Allow all");
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    CFDataRef exceptions    = SecTrustCopyExceptions(serverTrust);
    SecTrustSetExceptions(serverTrust, exceptions);
    CFRelease(exceptions);
    completionHandler(NSURLSessionAuthChallengeUseCredential,
                      [NSURLCredential credentialForTrust:serverTrust]);
}

- (void)refreshWhiteBoardWithFrame:(CGRect)frame
{
    self.webView.frame = frame;

    //给白板发送webview宽高
//    NSDictionary *tParamDic = @{
//        @"height" : @(CGRectGetHeight(self.webView.frame)), // DocumentFilePage_ShowPage
//        @"width" : @(CGRectGetWidth(self.webView.frame))
//    };
//
//    WB_INFO(@"refreshWhiteBoard : %@", NSStringFromCGRect(_webView.frame));
    
//    [self sendAction:WBChangeDynamicPptSize command:tParamDic];
    [self sendAction:WBDocResize command:@{}];
}

// 重新加载白板
- (void)webViewreload
{
    if (self.webViewTerminateBlock)
    {
        self.webViewTerminateBlock();
    }
    
    [self.webView reload];
}

- (void)destroy
{
    if (!self.webView)
    {
        return;
    }

    [self.webView stopLoading];
    
    //解决音频未销毁的问题
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"about:blank"]];
    [self.webView loadRequest:request];

    self.webView.scrollView.delegate = nil;
    [[self.webView configuration].userContentController removeScriptMessageHandlerForName:sYSSignalPubMsg];
    [[self.webView configuration].userContentController removeScriptMessageHandlerForName:sYSSignalDelMsg];
    [[self.webView configuration].userContentController
        removeScriptMessageHandlerForName:sYSSignalOnPageFinished];
    [[self.webView configuration].userContentController
        removeScriptMessageHandlerForName:sYSSignalPrintLogMessage];
    [[self.webView configuration].userContentController
        removeScriptMessageHandlerForName:sYSSignalPublishNetworkMedia];
    [[self.webView configuration].userContentController removeScriptMessageHandlerForName:sYSSignalSetProperty];
    [[self.webView configuration].userContentController
        removeScriptMessageHandlerForName:sYSSignalChangeWebPageFullScreen];
    [[self.webView configuration].userContentController
        removeScriptMessageHandlerForName:sYSSignalSendActionCommand];
    [[self.webView configuration].userContentController
        removeScriptMessageHandlerForName:sYSSignalSaveValueByKey];
    [[self.webView configuration].userContentController
        removeScriptMessageHandlerForName:sYSSignalGetValueByKey];
    [[self.webView configuration].userContentController removeScriptMessageHandlerForName:sYSSignalOnJsPlay];

    [self.webView removeFromSuperview];
    
    self.webView  = nil;
    self.delegate = nil;
}

@end
