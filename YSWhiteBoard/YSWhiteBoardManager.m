//
//  YSWhiteBoardManager.m
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/22.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import "YSWhiteBoardManager.h"
#import <objc/message.h>
#import "YSDownloader.h"
#import "YSPreloadProgressView.h"
#import "YSWBLogger.h"

/// SDK版本
static NSString *YSWhiteBoardSDKVersionString   = @"2.0.0.0";


NSString *const YSWhiteBoardWebProtocolKey      = @"web_protocol";
NSString *const YSWhiteBoardWebHostKey          = @"web_host";
NSString *const YSWhiteBoardWebPortKey          = @"web_port";
NSString *const YSWhiteBoardPlayBackKey         = @"playback";

static YSWhiteBoardManager *whiteBoardManagerSingleton = nil;

@interface YSWhiteBoardManager ()
<
    YSWBWebViewManagerDelegate
>
{
    /// 预加载课件加载成功
    BOOL isLoadingFinish;
    /// 页面加载完成, 是否需要缓存标识
    BOOL UIDidAppear;

    /// 预加载开始处理
    BOOL preloadDispose;
    /// 预加载失败
    BOOL predownloadError;
}

@property (nonatomic, weak) id <YSWhiteBoardManagerDelegate> wbDelegate;
/// 配置项
@property (nonatomic, strong) NSDictionary *configration;

/// 房间数据
@property (nonatomic, strong) NSDictionary *roomDic;
/// 房间配置项
@property (nonatomic, strong) YSRoomConfiguration *roomConfig;

// 关于获取白板 服务器地址、备份地址、web地址相关通知
/// 文档服务器地址
@property (nonatomic, strong) NSString *serverDocAddrKey;
/// web地址
@property (nonatomic, strong) NSString *serverWebAddrKey;
/// 备份链路域名集合
@property (nonatomic, strong) NSArray *serverAddrBackupKey;
/// 完成获取文档服务器地址，web地址，备份地址 上传
@property (nonatomic, assign) BOOL isUpdateWebAddressInfo;

/// 预加载文档
@property (nonatomic, strong) NSDictionary *preloadFileDic;
@property (nonatomic, strong) YSDownloader *downloader;

// 消息列表
@property (nonatomic, strong) NSMutableArray <NSDictionary *> *msgList;


/// 记录UI层是否开始上课
@property (nonatomic, assign) BOOL isBeginClass;

/// 信令缓存数据 预加载完成前
@property (nonatomic, strong) NSMutableArray *preLoadingFileCacheMsgPool;
/// 信令缓存数据 预加载后页面加载完成前
@property (nonatomic, strong) NSMutableArray *cacheMsgPool;

/// 课件列表
@property (nonatomic, strong) NSMutableArray <YSFileModel *> *docmentList;
/// 课件Dic列表
@property (nonatomic, strong) NSMutableArray <NSDictionary *> *docmentDicist;

/// 当前激活文档id
@property (nonatomic, strong) NSString *currentFileId;

// UI

/// 主白板
@property (nonatomic, strong) YSWhiteBoardView *mainWhiteBoardView;
/// 预加载课件
@property (nonatomic, strong) YSWhiteBoardView *preLoadWhiteBoardView;
/// 课件窗口列表
@property (nonatomic, strong) NSMutableArray <YSWhiteBoardView *> *coursewareViewList;

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
        isLoadingFinish = NO;
        UIDidAppear = NO;
        self.preloadingFished = NO;
        self.isUpdateWebAddressInfo = NO;
        
        self.msgList = [NSMutableArray array];
        
        self.cacheMsgPool = [NSMutableArray array];
        self.preLoadingFileCacheMsgPool = [NSMutableArray array];
        
        self.coursewareViewList = [NSMutableArray array];

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


#pragma -
#pragma mark createWhiteBoard

- (void)registerDelegate:(id <YSWhiteBoardManagerDelegate>)delegate configration:(NSDictionary *)config
{
    self.wbDelegate = delegate;
    self.configration = config;
}

- (YSWhiteBoardView *)createMainWhiteBoardWithFrame:(CGRect)frame
                        loadFinishedBlock:(wbLoadFinishedBlock)loadFinishedBlock
{
    self.mainWhiteBoardView = [[YSWhiteBoardView alloc] initWithFrame:frame fileId:@"0" loadFinishedBlock:loadFinishedBlock];
    return self.mainWhiteBoardView;
}

- (YSWhiteBoardView *)createWhiteBoardWithFrame:(CGRect)frame fileId:(NSString *)fileId
                        loadFinishedBlock:(wbLoadFinishedBlock)loadFinishedBlock
{
    if (![fileId bm_isNotEmpty] || [fileId isEqualToString:@"0"])
    {
        return nil;
    }
    
    YSWhiteBoardView *whiteBoardView = [[YSWhiteBoardView alloc] initWithFrame:frame fileId:fileId loadFinishedBlock:loadFinishedBlock];
    return whiteBoardView;
}

#pragma mark - 课件列表管理

#pragma mark  添加课件
- (void)addDocumentWithFile:(NSDictionary *)file
{
    NSNumber *isContentDocument = file[@"isContentDocument"];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:file];
    [dict setValue:isContentDocument forKey:@"isContentDocument"];
    
    YSFileModel *model = [YSFileModel new];
    if (dict[@"filedata"])
    {
        [model setValuesForKeysWithDictionary:dict];
        [model setValuesForKeysWithDictionary:dict[@"filedata"]];
    }
    else
    {
        [model setValuesForKeysWithDictionary:dict];
    }
    [self.docmentList addObject:model];
}

- (void)addOrReplaceDocumentFile:(NSDictionary *)file
{
    NSString *fileid = [file bm_stringForKey:@"fileid"];
    if (!fileid)
    {
        NSDictionary *filedata = [file bm_dictionaryForKey:@"filedata"];
        
        fileid = [filedata bm_stringForKey:@"fileid"];
        if (!fileid)
        {
            return;
        }
    }
    
    YSFileModel *model = [self getDocumentWithFileID:fileid];
    if (model)
    {
        [self.docmentList removeObject:model];
    }
    
    NSNumber *isContentDocument = file[@"isContentDocument"];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:file];
    [dict setValue:isContentDocument forKey:@"isContentDocument"];
    
    YSFileModel *fileModel = [YSFileModel new];
    [fileModel setValuesForKeysWithDictionary:dict];
    NSDictionary *fileData = dict[@"filedata"];
    if (fileData.count > 0)
    {
        [fileModel setValuesForKeysWithDictionary:fileData];
    }
    
    if ([[dict allKeys] containsObject:@"fileprop"])
    {
        fileModel.fileprop = dict[@"fileprop"];
        fileModel.isGeneralFile = @"1";
        if (fileModel.fileprop.integerValue == 1 || fileModel.fileprop.integerValue == 2)
        {
            fileModel.isDynamicPPT = @"1";
            fileModel.isGeneralFile = @"0";
        }
        else
        {
            fileModel.isDynamicPPT = @"0";
        }
        if (fileModel.fileprop.integerValue == 3)
        {
            fileModel.isH5Document = @"1";
            fileModel.isGeneralFile = @"0";
        }
        else
        {
            fileModel.isH5Document = @"0";
        }
    }
    else
    {
        NSNumber *isDynamicPPT = dict[@"isDynamicPPT"];
        NSNumber *isH5Document = dict[@"isH5Document"];
        if (isDynamicPPT.intValue == 1)
        {
            fileModel.fileprop = @(1);
        }
        if (isH5Document.intValue == 1)
        {
            fileModel.fileprop = @(3);
        }
    }
    
    [self.docmentList addObject:fileModel];
}

#pragma mark  获取课件
- (YSFileModel *)getDocumentWithFileID:(NSString *)fileId
{
    if (![fileId bm_isNotEmpty])
    {
        return nil;
    }

    YSFileModel *file = nil;
    @synchronized (self.docmentList)
    {
        for (YSFileModel *model in self.docmentList)
        {
            if ([model.fileid isEqualToString:fileId])
            {
                file = model;
                break;
            }
        }
    }
    
    return file;
}

#pragma mark  删除课件
- (void)deleteDocumentWithFileID:(NSString *)fileId
{
    if (![fileId bm_isNotEmpty])
    {
        return;
    }
    
    @synchronized (self.docmentList)
    {
        NSArray *tmp = [self.docmentList copy];
        for (int i = 0; i < tmp.count; i++)
        {
            YSFileModel *model = tmp[i];
            if ([model.fileid isEqualToString:fileId])
            {
                [self.docmentList removeObjectAtIndex:i];
                break;
            }
        }
    }
}

- (void)setTheCurrentDocumentFileID:(NSString *)fileId
{
    self.currentFileId = fileId;
}

- (YSFileModel *)currentFile
{
    NSString *fileId = self.currentFileId;
    if (!fileId)
    {
        fileId = @"0";
    }
    
    YSFileModel *file = nil;
    for (YSFileModel *model in self.docmentList)
    {
        if ([model.fileid isEqualToString:fileId])
        {
            file = model;
            break;
        }
    }
    
    return file;
}

#pragma mark - 课件窗口列表管理

#pragma mark  添加课件窗口
- (void)addWhiteBoardViewWithFileId:(NSString *)fileId
{
    YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithFileId:fileId];
    if (whiteBoardView)
    {
        [whiteBoardView bm_bringToFront];
        whiteBoardView;
        return;
    }
    
    CGRect frame = CGRectMake(0, 0, 100, 100);
    whiteBoardView = [self createWhiteBoardWithFrame:frame fileId:fileId loadFinishedBlock:^{
    }];
    
    [self.coursewareViewList addObject:whiteBoardView];
    [self.mainWhiteBoardView addSubview:whiteBoardView];
    
    return;
}

- (void)addWhiteBoardViewWithWhiteBoardView:(YSWhiteBoardView *)whiteBoardView
{
    if (whiteBoardView)
    {
        [whiteBoardView bm_bringToFront];
        whiteBoardView;
    }
    
    if ([self.coursewareViewList containsObject:whiteBoardView])
    {
        return;
    }
        
    [self.coursewareViewList addObject:whiteBoardView];
    [self.mainWhiteBoardView addSubview:whiteBoardView];
    
    return;
}

#pragma mark  获取课件窗口

- (YSWhiteBoardView *)getWhiteBoardViewWithFileId:(NSString *)fileId
{
    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        if ([whiteBoardView.fileId isEqualToString:fileId])
        {
            return whiteBoardView;
        }
    }
    return nil;
}

#pragma mark  删除课件窗口

- (void)delWhiteBoardViewWithFileId:(NSString *)fileId
{
    YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithFileId:fileId];
    if (whiteBoardView)
    {
        [self.coursewareViewList removeObject:whiteBoardView];
    }
}

#pragma mark  删除所有课件窗口
- (void)removeWhiteBoardView
{
    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        whiteBoardView;
    }
    
    [self.coursewareViewList removeAllObjects];
}




#pragma -
#pragma mark PreLoadingFile

- (void)checkPreLoadingFile
{
    // 如果开启了课件预加载会先下载课件,在向白板发送预加载
    if ([YSWhiteBoardManager shareInstance].roomConfig.coursewarePreload == YES)
    {
        return;
    }

    // 地址
    if (self.isUpdateWebAddressInfo == NO)
    {
        return;
    }
    
    [self sendPreLoadingFile];
}

// 发送预加载的文档
- (void)sendPreLoadingFile
{
    // 页面加载完成
    if (UIDidAppear == NO)
    {
        return;
    }
    
    // 是否有 需要加载的文件
    YSFileModel *file = nil;
    for (YSFileModel *model in self.docmentList)
    {
        if (model.type.intValue == 1)
        {
            file = model;
            break;
        }
    }
    if (!file || ![YSWhiteBoardManager supportPreload])
    {
        // 不需要本地加载
        self.preloadingFished = YES;
        [self onWhiteBoardHandlePreloadingFished];
        return;
    }
    
    // 添加预加载课件
    if (!self.preLoadWhiteBoardView && ![file.fileid isEqualToString:@"0"])
    {
        CGRect frame = CGRectMake(0, 0, 100, 100);
        self.preLoadWhiteBoardView = [self createWhiteBoardWithFrame:frame fileId:file.fileid loadFinishedBlock:^{
        }];

        [self addWhiteBoardViewWithWhiteBoardView:self.preLoadWhiteBoardView];
    }
    
    // 0:表示普通文档　１－２动态ppt(1: 第一版动态ppt 2: 新版动态ppt ）  3:h5文档
    BOOL isPPT_H5 = [file.fileprop integerValue] == 1 || [file.fileprop integerValue] == 2 || [file.fileprop integerValue] == 3;
    if (isPPT_H5)
    {
        if (self.roomConfig.coursewarePreload == YES && file.preloadingzip.length > 0)
        {
            if (predownloadError)
            {
                NSDictionary *dic = [YSFileModel fileDataDocDic:file predownloadError:predownloadError];
                [self.preLoadWhiteBoardView.webViewManager sendAction:WBPreLoadingFile command:@{@"cmd":dic}];
            }
            else
            {
                if ([[NSFileManager defaultManager] fileExistsAtPath:[[NSTemporaryDirectory() stringByAppendingPathComponent:@"YSFile"] stringByAppendingPathComponent:file.fileid]])
                {
                    NSDictionary *dic = [YSFileModel fileDataDocDic:file predownloadError:predownloadError];
                    [self.preLoadWhiteBoardView.webViewManager sendAction:WBPreLoadingFile command:@{@"cmd":dic}];
                }
            }
        }
        else
        {
            NSDictionary *dic = [YSFileModel fileDataDocDic:file predownloadError:predownloadError];
            [self.preLoadWhiteBoardView.webViewManager sendAction:WBPreLoadingFile command:@{@"cmd":dic}];
        }
    }
    else
    {
        if (self.preLoadWhiteBoardView)
        {
            [self.preLoadWhiteBoardView.webViewManager sendAction:WBPreLoadingFile command:@{@"cmd":@""}];
        }
    }
}

- (void)onWhiteBoardHandlePreloadingFished
{
#warning afterConnectToRoomAndPreloadingFished
//    if (self.documentBoard)
//    {
//        [self.documentBoard afterConnectToRoomAndPreloadingFished];
//    }
//    // 进教室复位
//    if (_nativeWBController)
//    {
//        [_nativeWBController afterConnectToRoomAndPreloadingFished];
//    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:YSWhiteBoardDocPreloadFinishNotification object:nil];
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
{   // ok
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

// 获取服务器地址
- (void)roomGetWhiteBoardOnServerAddrs:(NSNotification *) notification
{
    // 2
    NSDictionary *dict = [notification.userInfo objectForKey:YSWhiteBoardNotificationUserInfoKey];
    
    self.serverDocAddrKey = [dict objectForKey:YSWhiteBoardGetServerAddrKey] ?: self.serverDocAddrKey;
    self.serverAddrBackupKey = [dict objectForKey:YSWhiteBoardGetServerAddrBackupKey] ?: self.serverAddrBackupKey;
    self.serverWebAddrKey = [dict objectForKey:YSWhiteBoardGetWebAddrKey] ?: self.serverWebAddrKey;
    
    // 更新地址
    [self updateWebAddressInfo];

    // 预加载
    [self checkPreLoadingFile];
    
    // 根据serverWebAddrKey下载备注
    //[self loadCoursewareMarkData];
}

- (void)updateWebAddressInfo
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    
    NSString *phpAddr = self.configration[YSWhiteBoardWebHostKey];
    if (![phpAddr bm_isNotEmpty])
    {
        return;
    }
    
    // 文档服务器地址
    NSString *docServerAddr = self.serverDocAddrKey;
    if(![docServerAddr bm_isNotEmpty])
    {
        docServerAddr = phpAddr;
    }
    
    // 备份链路域名集合
    NSArray *classDocServerAddrBackup = [self.serverAddrBackupKey mutableCopy];
    NSString *docServerAddrBackup = classDocServerAddrBackup.firstObject;
    // web地址
    NSString *webServerAddr = self.serverWebAddrKey;
    
    [dic setValue:YSWBHTTPS forKey:YSWhiteBoardWebProtocolKey];
    [dic setValue:webServerAddr forKey:YSWhiteBoardWebHostKey];
    [dic setValue:YSWBPort forKey:YSWhiteBoardWebPortKey];
    
    [dic setValue:YSWBHTTPS forKey:YSWhiteBoardDocProtocolKey];
    [dic setValue:docServerAddr forKey:YSWhiteBoardDocHostKey];
    [dic setValue:YSWBPort forKey:YSWhiteBoardDocPortKey];
    
    [dic setValue:YSWBHTTPS forKey:YSWhiteBoardBackupDocProtocolKey];
    [dic setValue:docServerAddrBackup forKey:YSWhiteBoardBackupDocHostKey];
    [dic setValue:YSWBPort forKey:YSWhiteBoardBackupDocPortKey];
    
    [dic setValue:classDocServerAddrBackup forKey:YSWhiteBoardBackupDocHostListKey];
    
//    if (self.mainWhiteBoardView)
//    {
//        [self.mainWhiteBoardView updateWebAddressInfo:dic];
//    }
    
    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        [whiteBoardView updateWebAddressInfo:dic];
    }

    self.isUpdateWebAddressInfo = YES;
}

// 教室文件列表的通知
- (void)roomWhiteBoardFileList:(NSNotification *)notification
{
    // 3
    NSDictionary *dict = notification.userInfo;
    NSArray *fileList = [dict objectForKey:YSWhiteBoardNotificationUserInfoKey] ;
    NSMutableArray *mFileList = [NSMutableArray arrayWithArray:fileList];
    
    self.preloadFileDic = nil;
    
    [self.docmentList removeAllObjects];
    self.docmentDicist = [NSMutableArray arrayWithArray:fileList];

    // 第一个课堂课件
    NSString *firstClassModelFileId = nil;
    // 第一个系统课件
    NSString *firstSysModelFileId = nil;

    for (NSDictionary *dic in mFileList)
    {
        [self addOrReplaceDocumentFile:dic];
        NSNumber *type = [dic objectForKey:@"type"];
        if (type.intValue == 1)
        {
            self.preloadFileDic = dic;
        }
        
        NSString *filecategory = [dic objectForKey:@"filecategory"];
        BOOL isSysFile = [filecategory isEqualToString:@"1"];
        if (!firstClassModelFileId && filecategory && !isSysFile)
        {
            firstClassModelFileId = [dic objectForKey:@"fileid"];
        }
        if (!firstSysModelFileId && filecategory && isSysFile)
        {
            firstSysModelFileId = [dic objectForKey:@"fileid"];
        }
    }
    
    if (self.wbDelegate)
    {
        [self.wbDelegate onWhiteBroadFileList:mFileList];
    }
    
    // 设置默认文档
    //设置默认文档 （规则）
    /* 1.先看是否有后台关联或接口设置过的默认文档，如果有，显示如果没有，
     2.显示课堂文件夹里第一个上传的课件，如果再没有，
     3.显示系统文件夹里第一个上传的课件；
     4.都没有，则选择白板
     */
    NSString *fileId = nil;
    if (self.preloadFileDic)
    {
        fileId = [self.preloadFileDic objectForKey:@"fileid"];
    }
    if (!fileId)
    {
        fileId = firstClassModelFileId;
    }
    if (!fileId)
    {
        fileId = firstSysModelFileId;
    }
    if (!fileId)
    {
        fileId = @"0";
    }
    [self setTheCurrentDocumentFileID:fileId];
    
    // 预加载
    [self checkPreLoadingFile];
}

// 链接教室成功
- (void)roomWhiteBoardOnRoomConnectedUserlist:(NSNotification *)notification
{
    // 4
    NSDictionary *dict = notification.userInfo;
    NSNumber *code = [dict objectForKey:YSWhiteBoardOnRoomConnectedCodeKey];
    NSDictionary *response = [dict objectForKey:YSWhiteBoardOnRoomConnectedRoomMsgKey];
    
    if (isLoadingFinish == NO)
    {
        [self sendPreLoadingFile];
    }
    
    [self roomWhiteBoardOnRoomConnectedUserlist:code response:response];
}

- (void)roomWhiteBoardOnRoomConnectedUserlist:(NSNumber *)code response:(NSDictionary *)response
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:response];
    
    NSMutableDictionary *myselfDict = [NSMutableDictionary dictionary];
    [myselfDict setValue:[YSRoomInterface instance].localUser.properties forKey:@"properties"];
    [myselfDict setValue:[YSRoomInterface instance].localUser.peerID forKey:@"id"];
    
    [dict setValue:myselfDict forKey:@"myself"];
    
    if (self.preloadingFished == YES)
    {
        // 断线重连复位
        if (self.mainWhiteBoardView)
        {
            [self.mainWhiteBoardView whiteBoardOnRoomConnectedUserlist:code response:dict];
        }
        
        for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
        {
            [whiteBoardView whiteBoardOnRoomConnectedUserlist:code response:dict];
        }
    }
    else
    {
        NSString *methodName = NSStringFromSelector(@selector(whiteBoardOnRoomConnectedUserlist:response:));
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setValue:methodName forKey:kYSMethodNameKey];
        [dic setValue:@[code,dict] forKey:kYSParameterKey];
        // 放在首位 于showpage前发送，动态ppt备注需要
        //[self.preLoadingFileCacheMsgPool addObject:dic];
        [self.preLoadingFileCacheMsgPool insertObject:dic atIndex:0];
    }
}

// 断开链接的通知
- (void)roomWhiteBoardOnDisconnect:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    NSString *reason = [dict objectForKey:YSWhiteBoardNotificationUserInfoKey];
    
    [self disconnect:reason];
    
    [self.downloader cancelDownload];
}

// 断开连接
- (void)disconnect:(NSString *)reason
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (reason)
    {
        [dict setObject:reason forKey:@"reason"];
    }
    else
    {
        [dict setObject:@"" forKey:@"reason"];
    }
    
    if (!UIDidAppear)
    {
        NSString *methodName = NSStringFromSelector(@selector(sendSignalMessageToJS:message:));
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setValue:methodName forKey:kYSMethodNameKey];
        [dic setValue:@[WBDisconnect, dict] forKey:kYSParameterKey];
        [self.cacheMsgPool addObject:dic];
        
        return;
    }
    
    if (self.mainWhiteBoardView)
    {
        [self.mainWhiteBoardView disconnect:dict];
    }
    
    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        [whiteBoardView disconnect:dict];
    }
}

- (void)resetWhiteBoard:(NSNotification *)notification
{
    [[YSRoomInterface instance] pubMsg:sYSSignalUpdateTime msgID:sYSSignalUpdateTime toID:[YSRoomInterface instance].localUser.peerID data:@"" save:NO associatedMsgID:nil associatedUserID:nil expires:0 completion:nil];
    
    NSDictionary *msgList = [notification.userInfo objectForKey:YSWhiteBoardNotificationUserInfoKey];
    NSDictionary *roominfo = [[YSRoomInterface instance] getRoomProperty];
    //NSMutableArray *userlist = _userListArray;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:msgList forKey:@"msglist"];
    [dict setValue:roominfo forKey:@"roominfo"];
    //[dict setValue:userlist forKey:@"userlist"];
    
    [self roomWhiteBoardOnRoomConnectedUserlist:@(0) response:dict];
}

// 预加载
- (void)roomWhitePreloadFile:(NSNotification *)noti
{
//#if DEBUG
//    [[YSDownloader sharedInstance] removeLastPreloadFile];
//#endif
    BOOL isNeedPreload = [noti.userInfo[@"isNeedPreload"] boolValue];
    if (![YSWhiteBoardManager supportPreload])
    {
        isNeedPreload = NO;
        predownloadError = YES;
        preloadDispose = YES;
    }
    
    BMWeakSelf
    // 预加载文档下载
    NSString *downloadpath = [self.preloadFileDic objectForKey:@"preloadingzip"];
    NSString *fileId = [self.preloadFileDic bm_stringForKey:@"fileid"];
    if (downloadpath.length > 0 && isNeedPreload)
    {
        if (self.downloader.task && self.downloader.task.state == NSURLSessionTaskStateRunning)
        {
            return;
        }
        
        // 需要本地加载
        if (![[NSFileManager defaultManager] fileExistsAtPath:[[NSTemporaryDirectory() stringByAppendingPathComponent:@"YSFile"] stringByAppendingPathComponent:fileId]])
        {
            // 但是还未下载，开始下载
            YSPreloadProgressView *progressView = [[YSPreloadProgressView alloc] initWithSkipBlock:^{
                self->predownloadError = YES;
                self->preloadDispose = YES;
                [weakSelf sendPreLoadingFile];
            }];
            if (!self.downloader)
            {
                self.downloader = [[YSDownloader alloc] init];
                
                [[UIApplication sharedApplication].keyWindow addSubview:progressView];
                [progressView bmmas_makeConstraints:^(BMMASConstraintMaker *make) {
                    make.left.bmmas_equalTo([UIApplication sharedApplication].keyWindow.bmmas_left);
                    make.right.bmmas_equalTo([UIApplication sharedApplication].keyWindow.bmmas_right);
                    make.top.bmmas_equalTo([UIApplication sharedApplication].keyWindow.bmmas_top);
                    make.bottom.bmmas_equalTo([UIApplication sharedApplication].keyWindow.bmmas_bottom);
                }];
            }
            [self.downloader downloadWithURL:[NSURL URLWithString:downloadpath] fileID:fileId progressBlock:^(float downloadProgress, float unzipProgress, NSString *location, NSError *error) {
//                NSLog(@"下载进度：%f  解压进度：%f  文档地址：%@  错误：%@",downloadProgress, unzipProgress, location, error);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [progressView setDownloadProgress:downloadProgress unzipProgress:unzipProgress];
                    if (location)
                    {
                        self->predownloadError = NO;
                        self->preloadDispose = YES;
                    }
                    
                    if (error)
                    {
                        self->predownloadError = YES;
                        self->preloadDispose = YES;
                    }
                    
                    [progressView removeFromSuperview];
                    [weakSelf sendPreLoadingFile];
                });
            }];
        }
        else
        {
            // 本地已经解压好了文档
            predownloadError = NO;
            preloadDispose = YES;
            [self sendPreLoadingFile];
        }
    }
    else
    {
        preloadDispose = YES;
        [self sendPreLoadingFile];
    }
}

// 回放下消息列表
 - (void)roomWhiteBoardOnMsgList:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    NSArray *dicArray = [dict bm_arrayForKey:YSWhiteBoardNotificationUserInfoKey];
    
    for (NSDictionary *dic in dicArray)
    {
        if (dic && [dic isKindOfClass:NSDictionary.class])
        {
            if (self.mainWhiteBoardView)
            {
                [self.mainWhiteBoardView receiveWhiteBoardMessage:dic isDelMsg:NO];
            }
            
            for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
            {
                [whiteBoardView receiveWhiteBoardMessage:dic isDelMsg:NO];
            }
        }
    }
}

// 教室消息列表的通知
- (void)roomWhiteBoardOnRemoteMsgList:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    BOOL add = [[dict objectForKey:YSWhiteBoardOnRemoteMsgListAddKey] boolValue];
    id params = [dict objectForKey:YSWhiteBoardOnRemoteMsgListKey];
    
    [self roomWhiteBoardOnRemoteMsgList:add params:params];
}

- (void)roomWhiteBoardOnRemoteMsgList:(BOOL)add params:(id)params
{
    WB_INFO(@"YSWB roomWhiteBoardOnRemoteMsgList-----%@", [NSString stringWithFormat:@"add:%@, params:%@",@(add), params]);

    NSDictionary *tDataDic =[YSRoomUtil convertWithData:params];
    if (tDataDic)
    {
        [self.msgList addObject:tDataDic];
    }
}

// 大并发房间用户上台通知
- (void)roomWhiteBoardOnBigRoomUserPublished:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    NSDictionary *message = [dict objectForKey:YSWhiteBoardNotificationUserInfoKey];
    
    if (self.preloadingFished == YES)
    {
        if (self.mainWhiteBoardView)
        {
            [self.mainWhiteBoardView bigRoomUserPublished:message];
        }
        
        for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
        {
            [whiteBoardView  bigRoomUserPublished:message];
        }
    }
    else
    {
        NSString *methodName = NSStringFromSelector(@selector(sendSignalMessageToJS:message:));
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setValue:methodName forKey:kYSMethodNameKey];
        [dic setValue:@[WBParticipantPublished, message] forKey:kYSParameterKey];
        [self.preLoadingFileCacheMsgPool addObject:dic];
    }
}

// 用户属性改变通知
- (void)roomWhiteBoardOnRoomUserPropertyChanged:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    NSDictionary *message = [dict bm_dictionaryForKey:YSWhiteBoardNotificationUserInfoKey];
    
    // 用户属性改变通知，只接收自己的candraw属性
    if (![message bm_isNotEmptyDictionary])
    {
        return;
    }

    NSString *toID = [message bm_stringForKey:@"id"];
    if (![toID isEqualToString:[YSRoomInterface instance].localUser.peerID])
    {
        return;
    }
    
    NSDictionary *properties = [message bm_dictionaryForKey:@"properties"];
    if (![properties bm_containsObjectForKey:sYSUserCandraw])
    {
        return;
    }

    if (self.preloadingFished == YES)
    {
        if (self.mainWhiteBoardView)
        {
            [self.mainWhiteBoardView userPropertyChanged:message];
        }
        
        for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
        {
            [whiteBoardView userPropertyChanged:message];
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

- (void)roomWhiteBoardOnRoomParticipantLeaved:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    NSDictionary *message = [dict objectForKey:YSWhiteBoardNotificationUserInfoKey];
    
    if (self.preloadingFished == YES)
    {
//        if (self.mainWhiteBoardView)
//        {
//            [self.mainWhiteBoardView participantLeaved:message];
//        }
        
        for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
        {
            [whiteBoardView participantLeaved:message];
        }
    }
    else
    {
        NSString *methodName = NSStringFromSelector(@selector(sendSignalMessageToJS:message:));
        
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setValue:methodName forKey:kYSMethodNameKey];
        [dic setValue:@[WBParticipantLeft, message] forKey:kYSParameterKey];
        [self.preLoadingFileCacheMsgPool addObject:dic];
    }
}

- (void)roomWhiteBoardOnRoomParticipantJoin:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    NSDictionary *message = [dict objectForKey:YSWhiteBoardNotificationUserInfoKey];
    
    if (self.preloadingFished == YES)
    {
//        if (self.mainWhiteBoardView)
//        {
//            [self.mainWhiteBoardView participantJoin:message];
//        }
        
        for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
        {
            [whiteBoardView participantJoin:message];
        }
    }
    else
    {
        NSString *methodName = NSStringFromSelector(@selector(sendSignalMessageToJS:message:));
        
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setValue:methodName forKey:kYSMethodNameKey];
        [dic setValue:@[WBParticipantJoined, message] forKey:kYSParameterKey];
        [self.preLoadingFileCacheMsgPool addObject:dic];
    }
}

- (void)roomWhiteBoardOnParticipantEvicted:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    NSDictionary *reason = [dict objectForKey:YSWhiteBoardNotificationUserInfoKey];
    
    if (self.preloadingFished == YES)
    {
//        if (self.mainWhiteBoardView)
//        {
//            [self.mainWhiteBoardView participantEvicted:reason];
//        }
        
        for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
        {
            [whiteBoardView participantEvicted:reason];
        }
    }
    else
    {
        NSString *methodName = NSStringFromSelector(@selector(sendSignalMessageToJS:message:));
        
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setValue:methodName forKey:kYSMethodNameKey];
        [dic setValue:@[WBParticipantEvicted, reason] forKey:kYSParameterKey];
        [self.preLoadingFileCacheMsgPool addObject:dic];
    }
}

- (void)roomWhiteBoardOnRemotePubMsg:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    NSDictionary *message = [dict objectForKey:YSWhiteBoardNotificationUserInfoKey];
    
    if (![message bm_isNotEmptyDictionary])
    {
        return;
    }
    
    NSString *msgName = [message bm_stringForKey:@"name"];
    if ([msgName bm_isNotEmpty])
    {
        return;
    }
    NSString *msgId = [message bm_stringForKey:@"id"];
    if ([msgId bm_isNotEmpty])
    {
        return;
    }

    if (![msgName isEqualToString:sYSSignalUpdateTime])
    {
        WB_INFO(@"%s %@", __func__, message);
    }
    
    // 不处理大房间
    if ([msgName isEqualToString:sYSSignalNotice_BigRoom_Usernum])
    {
        return;
    }

    long ts = (long)[message bm_uintForKey:@"ts"];
    NSString *fromId = [message objectForKey:@"fromID"];
    NSObject *data = [message objectForKey:@"data"];
    if (self.wbDelegate && [self.wbDelegate respondsToSelector:@selector(onWhiteBroadPubMsgWithMsgID:msgName:data:fromID:inList:ts:)])
    {
        [self.wbDelegate onWhiteBroadPubMsgWithMsgID:msgId msgName:msgName data:data fromID:fromId inList:YES ts:ts];
    }
    
    NSDictionary *tDataDic = [YSRoomUtil convertWithData:data];
    if (![tDataDic bm_isNotEmptyDictionary])
    {
        return;
    }
    
    if ([msgName isEqualToString:sYSSignalDocumentChange])
    {
        BOOL isDelete = [tDataDic bm_boolForKey:@"isDel"];
        if (isDelete)
        {
            NSString *fileid = [tDataDic bm_stringForKey:@"fileid"];
            if (!fileid)
            {
                NSDictionary *filedata = [tDataDic bm_dictionaryForKey:@"filedata"];
                fileid = [filedata bm_stringForKey:@"fileid"];
            }

            [self deleteDocumentWithFileID:fileid];
        }
        else
        {
            [self addOrReplaceDocumentFile:tDataDic];
        }
    }
    else if ([msgName isEqualToString:sYSSignalShowPage])
    {
        NSString *fileid = [tDataDic bm_stringForKey:@"fileid"];
        [self.docmentList enumerateObjectsUsingBlock:^(YSFileModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([fileid isEqualToString:obj.fileid])
            {
                NSDictionary *filedata = [tDataDic bm_dictionaryForKey:@"filedata"];
                obj.currpage = [filedata bm_stringForKey:@"currpage"];
            }
        }];
        [self addOrReplaceDocumentFile:tDataDic];
    }
    
    if (self.preloadingFished == NO)
    {
        NSString *methodName = NSStringFromSelector(@selector(sendSignalMessageToJS:message:));
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setValue:methodName forKey:kYSMethodNameKey];
        [dic setValue:@[WBPubMsg, message] forKey:kYSParameterKey];
        [self.preLoadingFileCacheMsgPool addObject:dic];
        
        NSString *methorForNative = NSStringFromSelector(@selector(receiveWhiteBoardMessage:isDelMsg:));
        NSMutableDictionary *dicForNative = [NSMutableDictionary dictionary];
        [dicForNative setObject:methorForNative forKey:kYSMethodNameKey];
        [dicForNative setObject:@[[NSMutableDictionary dictionaryWithDictionary:message], @(YES)] forKey:kYSParameterKey];
        [self.preLoadingFileCacheMsgPool addObject:dicForNative];
    }
    else
    {
        if (self.mainWhiteBoardView)
        {
            [self.mainWhiteBoardView remotePubMsg:message];
        }
        
        for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
        {
            [whiteBoardView remotePubMsg:message];
        }
    }
}

- (void)roomWhiteBoardOnRemoteDelMsg:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    NSDictionary *message = [dict objectForKey:YSWhiteBoardNotificationUserInfoKey];
    
    if (self.preloadingFished == NO)
    {
        NSString *methodName = NSStringFromSelector(@selector(sendSignalMessageToJS:message:));
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setValue:methodName forKey:kYSMethodNameKey];
        [dic setValue:@[WBDelMsg, message] forKey:kYSParameterKey];
        [self.preLoadingFileCacheMsgPool addObject:dic];
        
        NSString *methorForNative = NSStringFromSelector(@selector(receiveWhiteBoardMessage:isDelMsg:));
        NSMutableDictionary *dicForNative = [NSMutableDictionary dictionary];
        [dicForNative setObject:methorForNative forKey:kYSMethodNameKey];
        [dicForNative setObject:@[[NSMutableDictionary dictionaryWithDictionary:message], @(YES)] forKey:kYSParameterKey];
        [self.preLoadingFileCacheMsgPool addObject:dicForNative];
        
        return;
    }
    
    if (self.mainWhiteBoardView)
    {
        [self.mainWhiteBoardView remoteDelMsg:message];
    }
    
    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        [whiteBoardView remoteDelMsg:message];
    }
}



@end
