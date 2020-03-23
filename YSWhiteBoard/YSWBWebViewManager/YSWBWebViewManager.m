//
//  YSWBWebViewManager.m
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/22.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import "YSWBWebViewManager.h"
#import "YSWKWebViewWeakDelegate.h"

@interface YSWBWebViewManager ()
<
    WKNavigationDelegate,
    WKScriptMessageHandler,
    UIScrollViewDelegate
>

@property (nonatomic, strong) WKWebView *webView;

@property (nonatomic, copy) wbLoadFinishedBlock loadFinishedBlock;
@property (nonatomic, strong) NSString *wbWebUrl;

/// webview崩溃标识
@property (nonatomic, assign) BOOL isWebViewCrash;


@end

@implementation YSWBWebViewManager

- (WKWebView *)createWhiteBoardWithFrame:(CGRect)frame
                       loadFinishedBlock:(wbLoadFinishedBlock)loadFinishedBlock
{
    self.isWebViewCrash    = NO;
    self.loadFinishedBlock = loadFinishedBlock;
    self.wbWebUrl = @"/publish/index.html#/mobileApp?languageType=ch";

    [self createWKWebViewWithFrame:frame];

    return _webView;
}

- (void)createWKWebViewWithFrame:(CGRect)frame
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
        [WBBUNDLE URLForResource:@"react_mobile_new_publishdir/index" withExtension:@"html"];
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

    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView loadRequest:request];
}

- (void)clearcookie:(WKWebView *)webView
{
    NSString *version = [UIDevice currentDevice].systemVersion;

    if (version.doubleValue >= 8.0 && version.doubleValue < 9.0) { return; }
    
    // 清除cookies
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [storage cookies])
    {
        [storage deleteCookie:cookie];
    }

    // 清除UIWebView的缓存
    NSURLCache *cache = [NSURLCache sharedURLCache];
    [cache removeAllCachedResponses];
    [cache setDiskCapacity:0];
    [cache setMemoryCapacity:0];

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
    config.processPool = [[WKProcessPool alloc] init];
    
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
    
#if 0
    if ([message.name isEqualToString:sYSSignalPubMsg]) {
        [self onPubMsg:message.body];

    } else if ([message.name isEqualToString:sDelMsg]) {
        [self onDelMsg:message.body];

    }
    // 页面加载完成
    else if ([message.name isEqualToString:sOnPageFinished]) {
        [self onPageFinished];

    } else if ([message.name isEqualToString:sPrintLogMessage]) {
        [self printLogMessage:message.name aMessageBody:message.body];

    } else if ([message.name isEqualToString:sPublishNetworkMedia]) {
        [self onPublishNetworkMedia:message.body];
    } else if ([message.name isEqualToString:sUnpublishNetworkMedia]) {

    }
    // 全屏
    else if ([message.name isEqualToString:sChangeWebPageFullScreen]) {
        [self ChangeWebPageFullScreen:message.name aMessageBody:message.body];

    } else if ([message.name isEqualToString:sSetProperty]) {
        [self setProperty:message.body];

    } else if ([message.name isEqualToString:sSendActionCommand]) {

        [self sendActionCommand:message.name aMessageBody:message.body];

    } else if ([message.name isEqualToString:sSaveValueByKey]) {

        [self saveVlueByKey:message.body];

    } else if ([message.name isEqualToString:sGetValueByKey]) {

        [self getValueByKey:message.body];

    } else if ([message.name isEqualToString:sOnJsPlay]) {
        [self onJsPlay:message.body];
    }
#endif
}

@end
