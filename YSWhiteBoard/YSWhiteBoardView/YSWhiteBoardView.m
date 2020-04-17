//
//  YSWhiteBoardView.m
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/23.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import "YSWhiteBoardView.h"
#import "YSRoomUtil.h"
#import "YSFileModel.h"
#import <objc/message.h>

#define YSWhiteBoardId_Header   @"docModule_"

@interface YSWhiteBoardView ()
<
    YSWBWebViewManagerDelegate
>
{
    /// 预加载开始处理
    BOOL preloadDispose;
    /// 预加载失败
    BOOL predownloadError;
}

@property (nonatomic, strong) NSString *whiteBoardId;
@property (nonatomic, strong) NSString *fileId;

/// web文档
@property (nonatomic, strong) YSWBWebViewManager *webViewManager;
/// 普通文档
@property (nonatomic, strong) YSWBDrawViewManager *drawViewManager;

@property (nonatomic, weak) WKWebView *wbView;

/// 加载H5脚本结束
@property (nonatomic, assign) BOOL loadingH5Fished;

/// 课件加载成功
@property (nonatomic, assign) BOOL isLoadingFinish;

/// 信令缓存数据 H5脚本加载完成前，之后开始预加载
@property (nonatomic, strong) NSMutableArray *cacheMsgPool;

@end

@implementation YSWhiteBoardView

- (instancetype)initWithFrame:(CGRect)frame fileId:(NSString *)fileId loadFinishedBlock:(wbLoadFinishedBlock)loadFinishedBlock
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.fileId = fileId;
        self.whiteBoardId = [NSString stringWithFormat:@"%@%@", YSWhiteBoardId_Header, fileId];
        
        self.webViewManager = [[YSWBWebViewManager alloc] init];
        self.webViewManager.delegate = self;
        
        self.cacheMsgPool = [NSMutableArray array];

        self.isLoadingFinish = NO;
        
        self.wbView = [self.webViewManager createWhiteBoardWithFrame:frame loadFinishedBlock:loadFinishedBlock];
        [self addSubview:self.wbView];
        
        self.drawViewManager = [[YSWBDrawViewManager alloc] initWithBackView:self webView:self.wbView];
    }
    
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    [self.drawViewManager updateFrame];
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


#pragma mark - 监听课堂 底层通知消息

/// 断开连接
- (void)disconnect:(NSDictionary *)message
{
    if (!self.loadingH5Fished)
    {
        NSString *methodName = NSStringFromSelector(@selector(disconnect:));
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setValue:methodName forKey:kYSMethodNameKey];
        [dic setValue:@[message] forKey:kYSParameterKey];
        [self.cacheMsgPool addObject:dic];
        
        return;
    }

    if (self.webViewManager)
    {
        [self.webViewManager sendSignalMessageToJS:WBDisconnect message:message];
    }
    
     if (self.drawViewManager)
     {
         [self.drawViewManager clearAfterClass];
     }
}

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
    NSString *fromId = [message objectForKey:@"fromID"];
    NSObject *data = [message objectForKey:@"data"];
    NSDictionary *tDataDic = [YSRoomUtil convertWithData:data];

    if (self.webViewManager)
    {
        BOOL remotePub = YES;
        if (![msgName isEqualToString:sYSSignalShowPage] && ![msgName isEqualToString:sYSSignalH5DocumentAction] && ![msgName isEqualToString:sYSSignalNewPptTriggerActionClick] && ![msgName isEqualToString:sYSSignalClassBegin])
        {
            remotePub = NO;
        }

        if (remotePub)
        {
            // 关联媒体课件不响应
            if ([msgName isEqualToString:sYSSignalShowPage])
            {
                BOOL isMedia = [tDataDic bm_boolForKey:@"isMedia"];
                
                if (!isMedia)
                {
                    [self.webViewManager sendSignalMessageToJS:WBPubMsg message:message];
                }
            }
            else
            {
                [self.webViewManager sendSignalMessageToJS:WBPubMsg message:message];
            }
        }
        
        if ([msgName isEqualToString:sYSSignalShowPage] && ![fromId isEqualToString:[YSRoomInterface instance].localUser.peerID])
        {
            [self.webViewManager stopPlayMp3];
        }
    }
        
    if (self.drawViewManager)
    {
        [self.drawViewManager receiveWhiteBoardMessage:[NSMutableDictionary dictionaryWithDictionary:message] isDelMsg:NO];
    }
}

/// 收到远端delMsg消息的通知
- (void)remoteDelMsg:(NSDictionary *)message
{
    NSString *msgName = [message bm_stringForKey:@"name"];

    if (self.webViewManager)
    {
        BOOL remotePub = YES;
        if (![msgName isEqualToString:sYSSignalClassBegin])
        {
            remotePub = NO;
        }
        
        if (remotePub)
        {
            [self.webViewManager sendSignalMessageToJS:WBDelMsg message:message];
        }
    }

    if (self.drawViewManager)
    {
        [self.drawViewManager receiveWhiteBoardMessage:[NSMutableDictionary dictionaryWithDictionary:message] isDelMsg:YES];
    }
}

/// 大并发房间用户上台通知
- (void)bigRoomUserPublished:(NSDictionary *)message
{
    if (self.webViewManager)
    {
        [self.webViewManager sendSignalMessageToJS:WBParticipantPublished message:message];
    }
}

/// 更新服务器地址
- (void)updateWebAddressInfo:(NSDictionary *)message
{
    if (self.webViewManager)
    {
        [self.webViewManager sendSignalMessageToJS:WBUpdateWebAddressInfo message:message];
    }
    
    if (self.drawViewManager)
    {
        self.drawViewManager.address = [message bm_stringForKey:YSWhiteBoardDocHostKey];
    }
}

- (void)receiveWhiteBoardMessage:(NSDictionary *)dictionary isDelMsg:(BOOL)isDel
{
    if (self.drawViewManager)
    {
        [self.drawViewManager receiveWhiteBoardMessage:dictionary isDelMsg:isDel];
    }
}


#pragma -
#pragma mark YSWBWebViewManagerDelegate

/// H5脚本文件加载初始化完成
- (void)onWBWebViewManagerPageFinshed
{
    self.loadingH5Fished = YES;
    
    // 更新地址
    [[YSWhiteBoardManager shareInstance] updateWebAddressInfo];
        
//    if (self.drawViewManager)
//    {
//        // 更新白板数据
//        self.drawViewManager.address = [YSWhiteBoardManager shareInstance].serverDocAddrKey;
//    }
}

/// Web课件翻页结果
- (void)onWBWebViewManagerStateUpdate:(NSDictionary *)dic
{
    NSLog(@"%s,message:%@", __func__, dic);
    if (self.drawViewManager)
    {
        // 设置页码
        if ([dic bm_containsObjectForKey:@"page"])
        {
             NSDictionary *dicPage = [dic bm_dictionaryForKey:@"page"];
            if ([dicPage bm_containsObjectForKey:@"currentPage"] && [dicPage bm_containsObjectForKey:@"totalPage"])
            {
                NSUInteger currentPage = [dicPage bm_uintForKey:@"currentPage"];
                NSUInteger totalPage   = [dicPage bm_uintForKey:@"totalPage"];
                
                NSString *fileId = self.fileId;
                if (!fileId)
                {
                     fileId = @"0";
                }
                
                YSFileModel *file = [[YSWhiteBoardManager shareInstance] getDocumentWithFileID:fileId];
                file.currpage = [dicPage objectForKey:@"currentPage"];
                file.pagenum = [dicPage objectForKey:@"totalPage"];

                // 肯定是showOnWeb
                if (self.drawViewManager.showOnWeb)
                {
                    if ([dicPage bm_containsObjectForKey:@"pptstep"])
                    {
                        file.pptstep = [dicPage bm_stringForKey:@"pptstep"];
                    }
                    if ([dicPage bm_containsObjectForKey:@"steptotal"])
                    {
                        file.steptotal = [dicPage bm_stringForKey:@"steptotal"];
                    }
                    #warning message
                    //[self.drawViewManager setTotalPage:totalPage currentPage:currentPage];
                }
            }
        }
        
        NSNumber *scale = [dic objectForKey:@"scale"];
        if ([scale isEqual:[NSNull null]])
        {
            return;
        }
        float ratio = 0;
        if (scale.intValue == 0)
        {
            ratio = 4.0f / 3;
        }
        else if (scale.intValue == 1)
        {
            ratio = 16.0f / 9;
        }
        else if (scale.intValue == 2)
        {
            NSNumber *irregular = [dic objectForKey:@"irregular"];
            if ([irregular isEqual:[NSNull null]])
            {
                return;
            }
            ratio = irregular.floatValue;
        }

        if (self.drawViewManager.showOnWeb)
        {
#warning message
            //[self.drawViewManager updateWBRatio:ratio];
        }
    }

#warning 刷新课件页码
    
}

/// 课件加载成功回调
- (void)onWBWebViewManagerLoadedState:(NSDictionary *)dic
{
    self.isLoadingFinish = [dic[@"notice"] isEqualToString:@"loadSuccess"];

    // 通知刷新白板
    [self refreshWhiteBoard];
    
    if (!self.isLoadingFinish && [dic objectForKey:@"data"] != nil)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:YSWhiteBoardEventLoadFileFail object:dic[@"data"]];
    }
    
    if ([YSWhiteBoardManager shareInstance].wbDelegate && [[YSWhiteBoardManager shareInstance].wbDelegate respondsToSelector:@selector(onWhiteBoardLoadedState:)])
    {
        [[YSWhiteBoardManager shareInstance].wbDelegate onWhiteBoardLoadedState:dic];
    }
}

/// 翻页超时
- (void)onWBWebViewManagerSlideLoadTimeout:(NSDictionary *)dic
{
    if ([dic objectForKey:@"data"] == nil)
    {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:YSWhiteBoardEventLoadSlideFail object:dic[@"data"]];
}

// 页面刷新尺寸
- (void)refreshWhiteBoardWithFrame:(CGRect)frame;
{
    self.frame = frame;
    [self.webViewManager refreshWhiteBoardWithFrame:frame];
}

- (void)refreshWhiteBoard
{
    [self refreshWhiteBoardWithFrame:self.frame];
}

#pragma -
#pragma mark 课件操作

// 翻页
- (void)showPageWithDictionary:(NSMutableDictionary *)dictionary
{
    [self showPageWithDictionary:dictionary isFreshCurrentCourse:NO];
}

- (void)showPageWithDictionary:(NSMutableDictionary *)dictionary isFreshCurrentCourse:(BOOL)freshCurrentCourse
{
    if (![dictionary bm_isNotEmptyDictionary])
    {
        return;
    }
    
    NSString *tellWho = [YSRoomInterface instance].localUser.peerID;
    BOOL save = NO;
    if (!freshCurrentCourse && [YSWhiteBoardManager shareInstance].isBeginClass)
    {
        if ([YSRoomInterface instance].localUser.canDraw || [YSRoomInterface instance].localUser.role == YSUserType_Teacher)
        {
            tellWho = YSRoomPubMsgTellAll;
            save = YES;
        }
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:nil];
    
    NSString *dataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [[YSRoomInterface instance] pubMsg:sYSSignalShowPage msgID:sYSSignalDocumentFilePage_ShowPage toID:tellWho data:dataString save:save extensionData:@{} associatedMsgID:nil associatedUserID:nil expires:0 completion:nil];
}

/// 刷新当前白板课件
- (void)freshCurrentCourse
{
    if (self.drawViewManager.showOnWeb)
    {
        [self.webViewManager sendSignalMessageToJS:WBReloadCurrentCourse message:@""];
    }
    else
    {
        NSMutableDictionary *filedata = [NSMutableDictionary dictionaryWithDictionary:[self.drawViewManager.fileDictionary objectForKey:@"filedata"]];
        [filedata setObject:@(self.drawViewManager.currentPage) forKey:@"currpage"];
        [self.drawViewManager.fileDictionary setObject:filedata forKey:@"filedata"];
        [self showPageWithDictionary:self.drawViewManager.fileDictionary isFreshCurrentCourse:YES];
    }
}

- (NSDictionary *)makeSlideOrStepDicWithFileModel:(YSFileModel *)model isNext:(BOOL)isNext
{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];

    [dic setObject:model.isDynamicPPT forKey:@"isDynamicPPT"];
    [dic setObject:model.isGeneralFile forKey:@"isGeneralFile"];
    [dic setObject:model.isH5Document forKey:@"isH5Document"];

    NSMutableDictionary *filedata = [[NSMutableDictionary alloc] init];
    [filedata setObject:model.fileid forKey:@"fileid"];
    if (isNext)
    {
        [dic setObject:@1 forKey:@"localActionIncr"];
    }
    else
    {
        [dic setObject:@(-1) forKey:@"localActionIncr"];
    }

    if (model.isMedia)
    {
        [dic setObject:model.isMedia forKey:@"isMedia"];
    }

    if (!model.currpage)
    {
        [dic setObject:filedata forKey:@"filedata"];
        return dic;
    }
    [filedata setObject:model.currpage forKey:@"currpage"];
    
    if (model.pagenum)
    {
        [filedata setObject:model.pagenum forKey:@"pagenum"];
    }
    
    if (!model.pptslide)
    {
        model.pptslide = @"1";
    }
    [filedata setObject:model.pptslide forKey:@"pptslide"];
    
    if (!model.pptstep)
    {
        model.pptstep = @"0";
    }
    [filedata setObject:model.pptstep forKey:@"pptstep"];
    
    if (model.steptotal)
    {
        [filedata setObject:model.steptotal forKey:@"steptotal"];
    }

    [dic setObject:filedata forKey:@"filedata"];

    return dic;
    
//    cmd: {
//        filedata: {
//            currpage: 1,
//            fileid: 554,
//            pagenum: 1,
//            pptslide: 1,
//            pptstep: 0,
//            steptotal: 0,
//        },
//        isDynamicPPT: false,
//        isGeneralFile: false,
//        isH5Document: true,
//        isMedia: false,
//        localActionIncr: 1, // 值为1或者-1为当前步进的帧数或者页数
//    }
}

- (YSWhiteBoardErrorCode)prePage
{
    if (![self.fileId bm_isNotEmpty])
    {
        return YSError_Bad_Parameters;
    }
    
    YSFileModel *file = [[YSWhiteBoardManager shareInstance] getDocumentWithFileID:self.fileId];
    if (file)
    {
        [self.webViewManager stopPlayMp3];

        NSDictionary *dic = [self makeSlideOrStepDicWithFileModel:file isNext:NO];
        [self.webViewManager sendAction:WBSlideOrStep command:@{@"cmd":dic}];

        return YSError_OK;
    }
        
    return YSError_Bad_Parameters;
}

/// 课件 上一页
- (void)whiteBoardPrePage
{
    if (self.drawViewManager.showOnWeb)
    {
        [self prePage];
        return;
    }

    self.drawViewManager.currentPage--;
    if (self.drawViewManager.currentPage < 1)
    {
        self.drawViewManager.currentPage = 1;
        return;
    }
    
    NSMutableDictionary *filedata = [NSMutableDictionary dictionaryWithDictionary:[self.drawViewManager.fileDictionary objectForKey:@"filedata"]];
    [filedata setObject:@(self.drawViewManager.currentPage) forKey:@"currpage"];
    [filedata setObject:@(self.drawViewManager.pagecount) forKey:@"pagenum"];
    [self.drawViewManager.fileDictionary setObject:filedata forKey:@"filedata"];
    
    [self showPageWithDictionary:self.drawViewManager.fileDictionary];
}

- (YSWhiteBoardErrorCode)nextPage
{
    if (![self.fileId bm_isNotEmpty])
    {
        return YSError_Bad_Parameters;
    }
    
    YSFileModel *file = [[YSWhiteBoardManager shareInstance] getDocumentWithFileID:self.fileId];
    if (file)
    {
        [self.webViewManager stopPlayMp3];

        NSDictionary *dic = [self makeSlideOrStepDicWithFileModel:file isNext:YES];
        [self.webViewManager sendAction:WBSlideOrStep command:@{@"cmd":dic}];
        
        return YSError_OK;
    }
    else
    {
        return YSError_Bad_Parameters;
    }

}

/// 课件 下一页
- (void)whiteBoardNextPage
{
    //白板课件
    if (self.fileId.intValue == 0)
    {
        // 老师可以白板加页
        if ([YSRoomInterface instance].localUser.role == YSUserType_Teacher)
        {
            self.drawViewManager.currentPage++;
            if (self.drawViewManager.currentPage > self.drawViewManager.pagecount)
            {
                NSMutableDictionary *filedata = [NSMutableDictionary dictionaryWithDictionary:[self.drawViewManager.fileDictionary objectForKey:@"filedata"]];
                [filedata setObject:@(self.drawViewManager.currentPage) forKey:@"currpage"];
                [filedata setObject:@(self.drawViewManager.currentPage) forKey:@"pagenum"];
                [self.drawViewManager.fileDictionary setObject:filedata forKey:@"filedata"];
                
                // 白板加页需发送
                NSString *json = [YSRoomUtil jsonStringWithDictionary:@{@"totalPage":@(self.drawViewManager.currentPage),
                                                                  @"fileid":@(0),
                                                                  @"sourceInstanceId":@"default"
                                                                  }];
                [[YSRoomInterface instance] pubMsg:sYSSignalWBPageCount msgID:sYSSignalWBPageCount toID:YSRoomPubMsgTellAll data:json save:YES completion:nil];
            }
            else
            {
                NSMutableDictionary *filedata = [NSMutableDictionary dictionaryWithDictionary:[self.drawViewManager.fileDictionary objectForKey:@"filedata"]];
                [filedata setObject:@(self.drawViewManager.currentPage) forKey:@"currpage"];
                [filedata setObject:@(self.drawViewManager.pagecount) forKey:@"pagenum"];
                [self.drawViewManager.fileDictionary setObject:filedata forKey:@"filedata"];
            }
        }
        else if ([YSRoomInterface instance].localUser.role == YSUserType_Student)
        {
            // 学生不加页
            self.drawViewManager.currentPage++;
            if (self.drawViewManager.currentPage <= self.drawViewManager.pagecount)
            {
                NSMutableDictionary *filedata = [NSMutableDictionary dictionaryWithDictionary:[self.drawViewManager.fileDictionary objectForKey:@"filedata"]];
                [filedata setObject:@(self.drawViewManager.currentPage) forKey:@"currpage"];
                [filedata setObject:@(self.drawViewManager.pagecount) forKey:@"pagenum"];
                [self.drawViewManager.fileDictionary setObject:filedata forKey:@"filedata"];
            }
            else
            {
                self.drawViewManager.currentPage--;
                return;
            }
        }
        [self showPageWithDictionary:self.drawViewManager.fileDictionary];
    }
    else
    {
        if (self.drawViewManager.showOnWeb)
        {
            [self nextPage];
            return;
        }

        self.drawViewManager.currentPage++;
        if (self.drawViewManager.currentPage > self.drawViewManager.pagecount)
        {
            self.drawViewManager.currentPage = self.drawViewManager.pagecount;
            return;
        }
    
        NSMutableDictionary *filedata = [NSMutableDictionary dictionaryWithDictionary:[self.drawViewManager.fileDictionary objectForKey:@"filedata"]];
        [filedata setObject:@(self.drawViewManager.currentPage) forKey:@"currpage"];
        [self.drawViewManager.fileDictionary setObject:filedata forKey:@"filedata"];
        
        [self showPageWithDictionary:self.drawViewManager.fileDictionary];
    }
}

- (NSDictionary *)fileDataDocDic:(YSFileModel *)aDefaultDocment currentPage:(NSUInteger)currentPage
{
    if (!aDefaultDocment)
    {
        //白板
        NSDictionary *tDataDic = @{
                                   @"isGeneralFile":@(true),
                                   @"isDynamicPPT":@(false),
                                   @"isH5Document":@(false),
                                   @"action":@"",
                                   @"fileid":@(0),
                                   @"mediaType":@"",
                                   @"isMedia":@(false),
                                   @"filedata":@{
                                           @"fileid"   :@(0),
                                           @"filename" :@"whiteboard",//MTLocalized(@"Title.whiteBoard"),
                                           //                                           @"filetype" :MTLocalized(@"Title.whiteBoard"),
                                           @"filetype" :@"whiteboard",
                                           @"currpage" :@(1),
                                           @"pagenum"  :@(1),
                                           @"pptslide" :@(1),
                                           @"pptstep"  :@(0),
                                           @"steptotal":@(0),
                                           @"isContentDocument":@(0),
                                           @"swfpath"  :@""
                                           }
                                   };
        return tDataDic;
    }
    
    //isH5Document isH5Docment
    //0:表示普通文档　１－２动态ppt(1: 第一版动态ppt 2: 新版动态ppt ）  3:h5文档
    NSString *prop = nil;
    if (!aDefaultDocment.fileprop || [aDefaultDocment isEqual:[NSNull null]])
    {
        prop = @"0";
    }
    else
    {
        prop = [NSString stringWithFormat:@"%@", aDefaultDocment.fileprop];
    }
//    NSString *tFileProp = [NSString stringWithFormat:@"%@",[aDefaultDocment.fileprop isEqual:[NSNull null]] ? @"0" : aDefaultDocment.fileprop];

    BOOL isGeneralFile = [prop isEqualToString:@"0"] ? true : false;
    BOOL isDynamicPPT  = ([prop isEqualToString:@"1"] ||[prop isEqualToString:@"2"] ) ? true : false ;
    BOOL isH5Document  = [prop isEqualToString:@"3"] ? true : false ;
    NSString *action   =  isH5Document ? sYSSignalActionShow : @"";
    NSString *downloadpath = aDefaultDocment.downloadpath ? aDefaultDocment.downloadpath : @"";
    
    NSString *mediaType     =  @"";
    NSMutableDictionary *filedata = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                    @"fileid":aDefaultDocment.fileid?aDefaultDocment.fileid:@(0),
                                                                                    @"filename":aDefaultDocment.filename?aDefaultDocment.filename:@"",
                                                                                    @"filetype": aDefaultDocment.filetype?aDefaultDocment.filetype:@"",
                                                                                    
                                                                                    @"currpage": aDefaultDocment.currpage?aDefaultDocment.currpage:@(1),
                                                                                    @"pagenum"  : aDefaultDocment.pagenum?aDefaultDocment.pagenum:@"",
                                                                                    @"pptslide": aDefaultDocment.pptslide?aDefaultDocment.pptslide:@(1),
                                                                                    @"pptstep":aDefaultDocment.pptstep?aDefaultDocment.pptstep:@(0),
                                                                                    @"steptotal":aDefaultDocment.steptotal?aDefaultDocment.steptotal:@(0),
                                                                                    @"isContentDocument":aDefaultDocment.isContentDocument?aDefaultDocment.isContentDocument:@(0),
                                                                                    @"swfpath"  :  aDefaultDocment.swfpath?aDefaultDocment.swfpath:@""
                                                                                    }];
    if (currentPage > 0)
    {
        [filedata setObject:@(currentPage) forKey:@"currpage"];
        [filedata setObject:@(currentPage) forKey:@"pptslide"];
    }
    NSString *type = nil;
    if(isH5Document)
    {
        type = @"/index.html";
    }
    if(isDynamicPPT)
    {
        type = @"/newppt.html";
    }
//    if([self isPredownload] && [[NSFileManager defaultManager] fileExistsAtPath:[[NSTemporaryDirectory() stringByAppendingPathComponent:@"YSFile"] stringByAppendingPathComponent:aDefaultDocment.fileid]])
//    {
//        [filedata setObject:[NSURL fileURLWithPath:[[[NSTemporaryDirectory() stringByAppendingPathComponent:@"YSFile"] stringByAppendingPathComponent:aDefaultDocment.fileid] stringByAppendingPathComponent:type]].absoluteString forKey:@"baseurl"];
//    }
    
    NSDictionary *tDataDic = @{
                               @"isGeneralFile":@(isGeneralFile),
                               @"isDynamicPPT":@(isDynamicPPT),
                               @"isH5Document":@(isH5Document),
                               @"action":action,
                               @"downloadpath":downloadpath,
                               @"fileid":aDefaultDocment.fileid?aDefaultDocment.fileid:@(0),
                               @"mediaType":mediaType,
                               @"isMedia":@(false),
                               @"filedata":filedata
                               };
    return tDataDic;
}

- (YSWhiteBoardErrorCode)skipToPageNum:(NSUInteger)pageNum
{
    if (![self.fileId bm_isNotEmpty])
    {
        return YSError_Bad_Parameters;
    }
    
    YSFileModel *file = [[YSWhiteBoardManager shareInstance] getDocumentWithFileID:self.fileId];
    if (file)
    {
        [self.webViewManager stopPlayMp3];

        NSDictionary *dic = [self fileDataDocDic:file currentPage:pageNum];
        NSDictionary *tParamDicDefault = @{
                                           @"id":sYSSignalDocumentFilePage_ShowPage,
                                           @"ts":@(0),
                                           @"data":dic ? dic : [NSNull null],
                                           @"name":sYSSignalShowPage
                                           };
        [self.webViewManager sendSignalMessageToJS:WBPubMsg message:tParamDicDefault];

        return YSError_OK;
    }
    else
    {
        return YSError_Bad_Parameters;
    }
}

/// 课件 跳转页
- (void)whiteBoardTurnToPage:(NSUInteger)pageNum
{
    if (self.drawViewManager.showOnWeb)
    {
        [self skipToPageNum:pageNum];
    }
    else
    {
        self.drawViewManager.currentPage = pageNum;
        
        NSMutableDictionary *filedata = [NSMutableDictionary dictionaryWithDictionary:[self.drawViewManager.fileDictionary objectForKey:@"filedata"]];
        [filedata setObject:@(self.drawViewManager.currentPage) forKey:@"currpage"];
        [self.drawViewManager.fileDictionary setObject:filedata forKey:@"filedata"];
        [self showPageWithDictionary:self.drawViewManager.fileDictionary];
    }
}

- (void)enlargeWhiteboard
{
    NSDictionary *dict = @{ @"type" : @"enlarge" };
    [self.webViewManager sendAction:WBDocResize command:@{@"cmd":dict}];
    [self refreshWebWhiteBoard];
}

- (void)narrowWhiteboard
{
    NSDictionary *dict = @{ @"type" : @"narrow" };
    [self.webViewManager sendAction:WBDocResize command:@{@"cmd":dict}];
    [self refreshWebWhiteBoard];
}

/// 白板 放大
- (void)whiteBoardEnlarge
{
    if (self.drawViewManager.showOnWeb)
    {
        [self enlargeWhiteboard];
    }
    else
    {
        //[self.drawViewManager enlarge];
    }
}

/// 白板 缩小
- (void)whiteBoardNarrow
{
    if (self.drawViewManager.showOnWeb)
    {
        [self narrowWhiteboard];
    }
    else
    {
        //[self.drawViewManager narrow];
    }
}

/// 白板 放大重置
- (void)whiteBoardResetEnlarge
{
    if (!self.drawViewManager.showOnWeb)
    {
        //[self.drawViewManager resetEnlargeValue:YSWHITEBOARD_MINZOOMSCALE animated:YES];
    }
}

- (void)refreshWebWhiteBoard
{
    [self.webViewManager refreshWhiteBoardWithFrame:self.frame];
}

@end
