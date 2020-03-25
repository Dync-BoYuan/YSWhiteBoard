//
//  YSWhiteBoardView.m
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/23.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import "YSWhiteBoardView.h"
#import "YSRoomUtil.h"

@interface YSWhiteBoardView ()
<
    YSWBWebViewManagerDelegate
>

@property (nonatomic, strong) NSString *fileId;

/// web文档
@property (nonatomic, strong) YSWBWebViewManager *webViewManager;
/// 普通文档
@property (nonatomic, strong) YSWBDrawViewManager *drawViewManager;

@property (nonatomic, weak) WKWebView *wbView;


@end

@implementation YSWhiteBoardView

- (instancetype)initWithFrame:(CGRect)frame fileId:(NSString *)fileId loadFinishedBlock:(wbLoadFinishedBlock)loadFinishedBlock
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.fileId = fileId;
        self.webViewManager = [[YSWBWebViewManager alloc] init];
        self.webViewManager.delegate = self;
        
        self.wbView = [self.webViewManager createWhiteBoardWithFrame:frame loadFinishedBlock:loadFinishedBlock];
        [self addSubview:self.wbView];
        
        self.drawViewManager = [[YSWBDrawViewManager alloc] initWithBackView:self webView:self.wbView];
    }
    
    return self;
}

#pragma mark - 监听课堂 底层通知消息

/// 用户属性改变通知
- (void)userPropertyChanged:(NSDictionary *)message
{
    if (self.webViewManager)
    {
        [self.webViewManager sendSignalMessageToJS:WBSetProperty message:message];
    }
    
    if (self.drawViewManager)
    {
        [self.drawViewManager updateProperty:message];
    }
}

/// 用户离开通知
- (void)participantLeaved:(NSDictionary *)message
{
    if (self.webViewManager)
    {
        [self.webViewManager sendSignalMessageToJS:WBParticipantLeft message:message];
    }
}

/// 用户进入通知
- (void)participantJoin:(NSDictionary *)message
{
    if (self.webViewManager)
    {
        [self.webViewManager sendSignalMessageToJS:WBParticipantJoined message:message];
    }
}

/// 自己被踢出教室通知
- (void)participantEvicted:(NSDictionary *)message
{
    if (self.webViewManager)
    {
        [self.webViewManager sendSignalMessageToJS:WBParticipantEvicted message:message];
    }
}

/// 收到远端pubMsg消息通知
- (void)remotePubMsg:(NSDictionary *)message
{
    NSString *msgName = [message bm_stringForKey:@"name"];
    NSString *msgId = [message bm_stringForKey:@"id"];
    NSObject *data = [message objectForKey:@"data"];
    NSDictionary *tDataDic = [YSRoomUtil convertWithData:data];

    if (self.webViewManager)
    {
        BOOL isMedia = [tDataDic bm_boolForKey:@"isMedia"];
        
        // 关联媒体课件不响应
        if ([msgName isEqualToString:sYSSignalDocumentChange])
        {
            if (!isMedia)
            {
                [self.webViewManager sendSignalMessageToJS:WBPubMsg message:message];
            }
        }
        else if ([msgName isEqualToString:sYSSignalShowPage])
        {
            if (!isMedia)
            {
                NSString *fileID = [[tDataDic bm_dictionaryForKey:@"filedata"] bm_stringForKey:@"fileid"];
                
                //[self uploadLogWithText:[NSString stringWithFormat:@"WhiteBoard Loading Fileid:%@, DocAddress:%@", fileID, self.serverDocAddrKey]];
                
                //如果本地已经存在预加载文档则参数塞入  baseurl:file:///本地文档
                
                if ([YSWhiteBoardManager supportPreload] &&
                    [[NSFileManager defaultManager] fileExistsAtPath:[[NSTemporaryDirectory() stringByAppendingPathComponent:@"YSFile"] stringByAppendingPathComponent:fileID]])
                {
                    NSMutableDictionary *urlDic = [NSMutableDictionary dictionaryWithDictionary:tDataDic];
                    NSMutableDictionary *filedata = [NSMutableDictionary dictionaryWithDictionary:[urlDic objectForKey:@"filedata"]];
                    
                    NSString *baseurl = [NSURL fileURLWithPath:[[[NSTemporaryDirectory() stringByAppendingPathComponent:@"YSFile"] stringByAppendingPathComponent:fileID] stringByAppendingPathComponent:@"newppt.html"]].relativeString;
                    [filedata setObject:baseurl forKey:@"baseurl"];
                    [urlDic setObject:filedata forKey:@"filedata"];
                    NSMutableDictionary *newMessage = [NSMutableDictionary dictionaryWithDictionary:message];
                    NSString *dataString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:urlDic options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
                    dataString = [dataString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                    [newMessage setObject:dataString forKey:@"data"];
                    [self.webViewManager sendSignalMessageToJS:WBPubMsg message:newMessage];
                }
                else
                {
                    [self.webViewManager sendSignalMessageToJS:WBPubMsg message:message];
                }
            }
        }
        else
        {
            [self.webViewManager sendSignalMessageToJS:WBPubMsg message:message];
        }
    }
        
    if (self.drawViewManager)
    {
        [self.drawViewManager receiveWhiteBoardMessage:[NSMutableDictionary dictionaryWithDictionary:message] isDelMsg:NO];
    }
}


#pragma -
#pragma mark YSWBWebViewManagerDelegate

///// 文档控制按钮状态更新
//- (void)onWBWebViewManagerStateUpdate:(NSDictionary *)message;
///// 课件加载成功回调
//- (void)onWBWebViewManagerLoadSuccess:(NSDictionary *)dic;
///// 翻页超时
//- (void)onWBWebViewManagerSlideLoadTimeout:(NSDictionary *)dic;
///// 房间链接成功msglist回调
//- (void)onWBWebViewManagerOnRoomConnectedMsglist:(NSDictionary *)msgList;
///// 教室加载状态
//- (void)onWBWebViewManagerLoadedState:(NSDictionary *)message;
///// 白板初始化完成
//- (void)onWBWebViewManagerPageFinshed;
///// 预加载文档结束
//- (void)onWBWebViewManagerPreloadingFished;


// 页面刷新尺寸
- (void)refreshWhiteBoardWithFrame:(CGRect)frame;
{
    self.frame = frame;
    [self.webViewManager refreshWhiteBoardWithFrame:frame];
}

@end
