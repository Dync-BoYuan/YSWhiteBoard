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

/// 断开连接
- (void)disconnect:(NSDictionary *)message
{
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

/// 收到远端delMsg消息的通知
- (void)remoteDelMsg:(NSDictionary *)message
{
    if (self.webViewManager)
    {
        [self.webViewManager sendSignalMessageToJS:WBDelMsg message:message];
    }

    if (self.drawViewManager)
    {
        [self.drawViewManager receiveWhiteBoardMessage:[NSMutableDictionary dictionaryWithDictionary:message] isDelMsg:YES];
    }
}

/// 连接教室成功的通知
- (void)whiteBoardOnRoomConnectedUserlist:(NSNumber *)code response:(NSDictionary *)response
{
    if (self.webViewManager)
    {
        [self.webViewManager whiteBoardOnRoomConnectedUserlist:code response:response];
    }

    if (self.drawViewManager)
    {
        [self.drawViewManager whiteBoardOnRoomConnectedUserlist:code response:response];
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
    if(![[YSWhiteBoardManager shareInstance] isPredownloadError] && [[NSFileManager defaultManager] fileExistsAtPath:[[NSTemporaryDirectory() stringByAppendingPathComponent:@"YSFile"] stringByAppendingPathComponent:aDefaultDocment.fileid]])
    {
        [filedata setObject:[NSURL fileURLWithPath:[[[NSTemporaryDirectory() stringByAppendingPathComponent:@"YSFile"] stringByAppendingPathComponent:aDefaultDocment.fileid] stringByAppendingPathComponent:type]].absoluteString forKey:@"baseurl"];
    }
    
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
