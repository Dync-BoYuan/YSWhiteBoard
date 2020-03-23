//
//  YSWhiteBoardManager.m
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/22.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import "YSWhiteBoardManager.h"
#import <objc/message.h>

#import "YSWBDrawViewManager.h"
#import "YSWBWebViewManager.h"

/// SDK版本
static NSString *YSWhiteBoardSDKVersionString   = @"2.0.0.0";


NSString *const YSWhiteBoardWebProtocolKey      = @"web_protocol";
NSString *const YSWhiteBoardWebHostKey          = @"web_host";
NSString *const YSWhiteBoardWebPortKey          = @"web_port";
NSString *const YSWhiteBoardPlayBackKey         = @"playback";

static YSWhiteBoardManager *whiteBoardManagerSingleton = nil;

@interface YSWhiteBoardManager ()

/// 房间数据
@property (nonatomic, strong) NSDictionary *roomDic;
/// 房间配置项
@property (nonatomic, strong) YSRoomConfiguration *roomConfig;

/// 记录UI层是否开始上课
@property (nonatomic, assign) BOOL isBeginClass;

/// 信令缓存数据 预加载完成前
@property (nonatomic, strong) NSMutableArray *preLoadingFileCacheMsgPool;
/// 信令缓存数据 预加载后页面加载完成前
@property (nonatomic, strong) NSMutableArray *cacheMsgPool;

@end

@implementation YSWhiteBoardManager

+ (instancetype)shareInstance
{
    @synchronized(self)
    {
        if (!whiteBoardManagerSingleton)
        {
            whiteBoardManagerSingleton = [[YSWhiteBoardManager alloc] init];
        }
    }
    return whiteBoardManagerSingleton;
}

+ (NSString *)whiteBoardVersion
{
    return YSWhiteBoardSDKVersionString;
}

- (instancetype)init
{
    if (self = [super init])
    {

#if DEBUG
        NSString *sdkVersion = [NSString stringWithFormat:@"%@", YSWhiteBoardSDKVersionString];
        BMLog(@"WhiteBoard Version :%@", sdkVersion);
#endif

        [self loadNotifiction];
    }
    
    return self;
}

/// 是否支持预加载 iOS13以上不支持
+ (BOOL)supportPreload
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 13.0)
    {
    //if (@available(iOS 13, *)){
        return NO;
    }
    
    return YES;
}

- (void)doMsgCachePool
{
    // 执行所有缓存的信令消息
    NSArray *array = self.cacheMsgPool;
    for (NSDictionary *dic in array)
    {
        NSString *func = dic[kYSMethodNameKey];
        SEL funcSel = NSSelectorFromString(func);

        NSMutableArray *params = [NSMutableArray array];
        if ([[dic allKeys] containsObject:kYSParameterKey])
        {
            params = dic[kYSParameterKey];
        }
        
        switch (params.count)
        {
            case 0:
                ((void (*)(id, SEL))objc_msgSend)(self, funcSel);
                break;
                
            case 1:
                ((void (*)(id, SEL, id))objc_msgSend)(self, funcSel, params.firstObject);
                break;
                
            case 2:
                ((void (*)(id, SEL, id, id))objc_msgSend)(
                    self, funcSel, params.firstObject, params.lastObject);
                break;

            default:
                break;
        }
    }
    
    [self.cacheMsgPool removeAllObjects];
}

- (void)doPreLoadingFileCacheMsgPool:(BOOL)removeAll
{
    // 执行所有缓存的信令消息
    NSArray *array = self.preLoadingFileCacheMsgPool;

    for (NSDictionary *dic in array)
    {
        NSString *func = dic[kYSMethodNameKey]; // YSCacheMsg_MethodName
        SEL funcSel    = NSSelectorFromString(func);

        NSMutableArray *params = [NSMutableArray array];
        if ([[dic allKeys] containsObject:kYSParameterKey])
        {
            params = dic[kYSParameterKey];
        }

        switch (params.count)
        {
            case 0:
                ((void (*)(id, SEL))objc_msgSend)(self, funcSel);
                break;

            case 1:
                ((void (*)(id, SEL, id))objc_msgSend)(self, funcSel, params.firstObject);
                break;

            case 2:
                if (![NSStringFromSelector(funcSel)
                        isEqualToString:NSStringFromSelector(
                                            @selector(receiveWhiteBoardMessage:isDelMsg:))])
                {
                    ((void (*)(id, SEL, id, id))objc_msgSend)(self, funcSel, params.firstObject,
                                                              params.lastObject);
                }
                break;

            default:
                break;
        }
    }

    if (removeAll)
    {
        [self.preLoadingFileCacheMsgPool removeAllObjects];
    }
}

#pragma mark - 监听课堂 底层通知消息

- (void)loadNotifiction
{
    // checkRoom相关通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnCheckRoom:) name:YSWhiteBoardOnCheckRoomNotification object:nil];
    // 用户属性改变通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnRoomUserPropertyChanged:) name:YSWhiteBoardOnRoomUserPropertyChangedNotification object:nil];
    // 用户离开通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnRoomParticipantLeaved:) name:YSWhiteBoardOnRoomUserLeavedNotification object:nil];
    // 用户进入通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnRoomParticipantJoin:) name:YSWhiteBoardOnRoomUserJoinedNotification object:nil];
    // 自己被踢出教室通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnParticipantEvicted:) name:YSWhiteBoardOnSelfEvictedNotification object:nil];
    // 收到远端pubMsg消息通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnRemotePubMsg:) name:YSWhiteBoardOnRemotePubMsgNotification object:nil];
    // 收到远端delMsg消息的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnRemoteDelMsg:) name:YSWhiteBoardOnRemoteDelMsgNotification object:nil];
    // 连接教室成功的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnRoomConnectedUserlist:) name:YSWhiteBoardOnRoomConnectedNotification object:nil];
    // 断开链接的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnDisconnect:) name:YSWhiteBoardOnRoomDisconnectNotification object:nil];
    // 教室文件列表的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardFileList:) name:YSWhiteBoardFileListNotification object:nil];
    // 教室消息列表的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnRemoteMsgList:) name:YSWhiteBoardOnRemoteMsgListNotification object:nil];
    // 大并发房间用户上台通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnBigRoomUserPublished:) name:YSWhiteBoardOnBigRoomUserPublishedNotification object:nil];
    // 白板崩溃 重新加载 重新获取msgList
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetWhiteBoard:) name:YSWhiteBoardMsgListACKNotification object:nil];
    // 获取服务器地址
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomGetWhiteBoardOnServerAddrs:) name:YSWhiteBoardOnServerAddrsNotification object:nil];
    // 预加载
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhitePreloadFile:) name:YSWhiteBoardPreloadFileNotification object:nil];
    
    // 关于画笔消息列表的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnMsgList:) name:YSWhiteBoardOnMsgListNotification object:nil];
}

/// checkRoom相关通知
- (void)roomWhiteBoardOnCheckRoom:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    NSDictionary *message = [dict bm_dictionaryForKey:YSWhiteBoardNotificationUserInfoKey];
    
    if (message)
    {
        NSDictionary *roomDic = [message bm_dictionaryForKey:@"room"];
        self.roomDic = roomDic;
        // 房间配置项
        NSString *chairmancontrol = [roomDic bm_stringTrimForKey:@"chairmancontrol"];
        if ([chairmancontrol bm_isNotEmpty])
        {
            self.roomConfig = [[YSRoomConfiguration alloc] initWithConfigurationString:chairmancontrol];
        }
    }
}

// 用户属性改变通知
- (void)roomWhiteBoardOnRoomUserPropertyChanged:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    NSDictionary *message = [dict bm_dictionaryForKey:YSWhiteBoardNotificationUserInfoKey];
    
//    if ([message bm_containsObjectForKey:sYSUserProperties])
//    {
//        NSDictionary *userProperties = [message bm_dictionaryForKey:sYSUserProperties];
//        
//        if ([userProperties bm_containsObjectForKey:sYSUserCandraw])
//        {
//            
//        }
//    }

/*
    if (message)
    {
        if (self.preloadingFished == YES)
        {
            if (self.documentBoard)
            {
                [self.documentBoard sendSignalMessageToJS:WBSetProperty message:message];
            }
            
            if (_nativeWBController)
            {
                [_nativeWBController updateProperty:message];
            }
        }
        else
        {
            NSString *methodName = NSStringFromSelector(@selector(sendSignalMessageToJS:message:));
            
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            [dic setValue:methodName forKey:kYSMethodNameKey];
            [dic setValue:@[WBSetProperty, message] forKey:kYSParameterKey];
        
            [self.preLoadingFileCacheMsgPool addObject:dic];
        }
    }
 */
}


@end
