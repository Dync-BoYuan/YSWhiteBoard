//
//  YSWhiteBoardManager.m
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/22.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import "YSWhiteBoardManager.h"
#import "YSWBLogger.h"
#import "YSWhiteBoardTopBar.h"

#if YSWHITEBOARD_USEHTTPDNS
#import "YSWhiteBordHttpDNSUtil.h"
#import "YSWhiteBordNSURLProtocol.h"
#import "NSURLProtocol+YSWhiteBoard.h"
#endif

#define YSWhiteBoardDefaultFrame        CGRectMake(0, 0, 100, 100)
#define YSWhiteBoardDefaultLeft         10.0f
#define YSWhiteBoardDefaultTop          10.0f
#define YSWhiteBoardDefaultSOffset      10.0f
#define YSWhiteBoardDefaultLeftOffset   50.0f
#define YSWhiteBoardDefaultTopOffset    40.0f

/// SDK版本
static NSString *YSWhiteBoardSDKVersionString   = @"2.0.0.0";


NSString *const YSWhiteBoardWebProtocolKey      = @"web_protocol";
NSString *const YSWhiteBoardWebHostKey          = @"web_host";
NSString *const YSWhiteBoardWebPortKey          = @"web_port";
NSString *const YSWhiteBoardPlayBackKey         = @"playback";

static YSWhiteBoardManager *whiteBoardManagerSingleton = nil;

@interface YSWhiteBoardManager ()
<
    YSWhiteBoardViewDelegate,
    YSWhiteBoardTopBarDelegate
>
{
//    /// 页面加载完成, 是否需要缓存标识
//    BOOL UIDidAppear;
//
//    /// 预加载开始处理
//    BOOL preloadDispose;
//    /// 预加载失败
//    BOOL predownloadError;
    
    CGFloat whiteBoardViewCurrentLeft;
    CGFloat whiteBoardViewCurrentTop;
}

@property (nonatomic, weak) id <YSWhiteBoardManagerDelegate> wbDelegate;
/// 配置项
@property (nonatomic, strong) NSDictionary *configration;

/// 房间数据
@property (nonatomic, strong) NSDictionary *roomDic;
/// 房间配置项
@property (nonatomic, strong) YSRoomConfiguration *roomConfig;
/// 房间类型
@property (nonatomic, assign) YSRoomUseType roomUseType;

// 关于获取白板 服务器地址、备份地址、web地址相关通知
/// 文档服务器地址
@property (nonatomic, strong) NSString *serverDocAddrKey;
/// web地址
@property (nonatomic, strong) NSString *serverWebAddrKey;
/// 备份链路域名集合
@property (nonatomic, strong) NSArray *serverAddrBackupKey;
/// 完成获取文档服务器地址，web地址，备份地址 上传
@property (nonatomic, assign) BOOL isUpdateWebAddressInfo;
@property (nonatomic, strong) NSDictionary *serverAddressInfoDic;


/// 记录UI层是否开始上课
@property (nonatomic, assign) BOOL isBeginClass;
@property (nonatomic, strong) NSDictionary *beginClassMessage;

/// 课件列表
@property (nonatomic, strong) NSMutableArray <YSFileModel *> *docmentList;

/// 当前激活文档id
@property (nonatomic, strong, setter=setTheCurrentDocumentFileID:) NSString *currentFileId;

/// 默认文档id
@property (nonatomic, strong) NSString *defaultFileId;

/// 当前播放的媒体课件
@property (nonatomic, strong) YSMediaFileModel *mediaFileModel;
/// 当前播放的媒体课件发送者peerId
@property (nonatomic, strong) NSString *mediaFileSenderPeerId;


// UI
@property (nonatomic, assign) CGSize whiteBoardViewDefaultSize;

/// 主白板
@property (nonatomic, strong) YSWhiteBoardView *mainWhiteBoardView;

/// 画笔控制
@property (nonatomic, strong) YSBrushToolsManager *brushToolsManager;

/// 拖出视频view时的模拟移动图
@property (nonatomic, strong) UIImageView *dragImageView;

/// 小白板是否正在拖动
@property (nonatomic, assign) BOOL isDraging;

/// 小白板是否正在拖动缩放
@property (nonatomic, assign) BOOL isDragZooming;


/// 视频窗口
@property (nonatomic, strong) YSWhiteBoardView *mp4WhiteBoardView;
/// 音频窗口
@property (nonatomic, strong) YSWhiteBoardView *mp3WhiteBoardView;

/// 判断音视频进度是否在拖动
@property (nonatomic, assign) BOOL isMediaDrag;

/// 每个课件收到的位置
@property (nonatomic, strong) NSMutableDictionary * allPositionDict;

/// H5课件附加url参数
@property (nonatomic, strong) NSMutableDictionary *connectH5CoursewareUrlParameters;
/// H5课件cookie
@property (nonatomic, strong) NSArray <NSDictionary *> *connectH5CoursewareUrlCookies;

/// 涂鸦数据
@property (nonatomic, strong) NSMutableArray *sharpChangeArray;

@end

@implementation YSWhiteBoardManager

#pragma mark - dealloc

- (void)dealloc
{
    [self clearAllData];
}

- (void)clearAllData
{
    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        [whiteBoardView destroy];
    }
    [self.coursewareViewList removeAllObjects];
    self.coursewareViewList = nil;
    
    [self.sharpChangeArray removeAllObjects];
    self.sharpChangeArray = nil;

    [self.mainWhiteBoardView bm_removeAllSubviews];
    [self.mainWhiteBoardView destroy];
    
    self.docmentList = nil;
    self.wbDelegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (void)destroy
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
        
    if (whiteBoardManagerSingleton)
    {
        [whiteBoardManagerSingleton clearAllData];
        [whiteBoardManagerSingleton registerURLProtocol:NO];
        whiteBoardManagerSingleton = nil;
    }
}

// 拦截网络请求
- (void)registerURLProtocol:(BOOL)isRegister
{
#if YSWHITEBOARD_USEHTTPDNS
    if (isRegister)
    {
        [NSURLProtocol registerClass:[YSWhiteBordNSURLProtocol class]];
        for (NSString* scheme in @[@"http", @"https"])
        {
            [NSURLProtocol ys_registerScheme:scheme];
        }
        [YSWhiteBordHttpDNSUtil sharedInstance];
    }
    else
    {
        [NSURLProtocol unregisterClass:[YSWhiteBordNSURLProtocol class]];
        for (NSString* scheme in @[@"http", @"https"])
        {
            [NSURLProtocol ys_unregisterScheme:scheme];
        }
        [YSWhiteBordHttpDNSUtil destroy];
    }
#endif
}

+ (instancetype)shareInstance
{
    @synchronized(self)
    {
        if (!whiteBoardManagerSingleton)
        {
            whiteBoardManagerSingleton = [[YSWhiteBoardManager alloc] init];
            //[whiteBoardManagerSingleton registerURLProtocol:YES];
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
        self.isUpdateWebAddressInfo = NO;
        
        self.docmentList = [NSMutableArray array];
        
        self.serverAddrBackupKey = [NSMutableArray array];
        
        self.coursewareViewList = [NSMutableArray array];
        
        self.sharpChangeArray = [[NSMutableArray alloc] init];
        
        self.brushToolsManager = [YSBrushToolsManager shareInstance];
        
        whiteBoardViewCurrentLeft = YSWhiteBoardDefaultLeft;
        whiteBoardViewCurrentTop = YSWhiteBoardDefaultTop;
        
        self.defaultFileId = nil;

#if DEBUG
        NSString *sdkVersion = [NSString stringWithFormat:@"%@", YSWhiteBoardSDKVersionString];
        BMLog(@"WhiteBoard Version :%@", sdkVersion);
#endif

        [self loadNotifiction];
    }
    
    return self;
}


#pragma -
#pragma mark createWhiteBoard

- (void)registerDelegate:(id<YSWhiteBoardManagerDelegate>)delegate configration:(NSDictionary *)config
{
    [self registerDelegate:delegate configration:config useHttpDNS:YES];
}

- (void)registerDelegate:(id <YSWhiteBoardManagerDelegate>)delegate configration:(NSDictionary *)config useHttpDNS:(BOOL)useHttpDNS
{
    self.wbDelegate = delegate;
    self.configration = config;
    
    if (useHttpDNS)
    {
        [self registerURLProtocol:YES];
    }

//    NSDictionary *whiteBoardConfig = @{
//        YSWhiteBoardWebProtocolKey : YSLive_Http,
//        YSWhiteBoardWebHostKey : host,
//        YSWhiteBoardWebPortKey : @(port),
//        YSWhiteBoardPlayBackKey : @(NO),
//    };

}

- (YSWhiteBoardView *)createMainWhiteBoardWithFrame:(CGRect)frame
                        loadFinishedBlock:(wbLoadFinishedBlock)loadFinishedBlock
{
//    CGFloat height = frame.size.height * 0.6f;
//    CGFloat width = height / 3.0f * 5.0f;
    CGFloat scale = frame.size.width / frame.size.height;
       
       CGFloat height = 0;
       CGFloat width = 0;
       if (scale > 5.0/3.0)
       {
           height = frame.size.height * 0.6f;
           width = height * 5.0/3.0;
       }
       else
       {
           width = frame.size.width * 0.6f;
           height = width * 3.0/5.0;
       }
    
    self.whiteBoardViewDefaultSize = CGSizeMake(width, height);
    
    self.mainWhiteBoardView = [[YSWhiteBoardView alloc] initWithFrame:frame fileId:@"0" loadFinishedBlock:loadFinishedBlock];
    self.mainWhiteBoardView.delegate = self;
    [self.mainWhiteBoardView changeWhiteBoardBackgroudColor:YSWhiteBoard_MainBackGroudColor];

    return self.mainWhiteBoardView;
}

- (YSWhiteBoardView *)createWhiteBoardWithFileId:(NSString *)fileId
                             isFromLocalUser:(BOOL)isFromMe
                               loadFinishedBlock:(wbLoadFinishedBlock)loadFinishedBlock
{
    return [self createWhiteBoardWithFileId:fileId isFromLocalUser:isFromMe isMedia:NO mediaType:0 loadFinishedBlock:loadFinishedBlock];
}

- (YSWhiteBoardView *)createMp3WhiteBoardWithFileId:(NSString *)fileId
                                isFromLocalUser:(BOOL)isFromMe
                                  loadFinishedBlock:(wbLoadFinishedBlock)loadFinishedBlock
{
    return [self createWhiteBoardWithFileId:fileId isFromLocalUser:isFromMe isMedia:YES mediaType:YSWhiteBordMediaType_Audio loadFinishedBlock:loadFinishedBlock];
}

- (YSWhiteBoardView *)createMp4WhiteBoardWithFileId:(NSString *)fileId
                                    isFromLocalUser:(BOOL)isFromMe
                                  loadFinishedBlock:(wbLoadFinishedBlock)loadFinishedBlock
{
    return [self createWhiteBoardWithFileId:fileId isFromLocalUser:isFromMe isMedia:YES mediaType:YSWhiteBordMediaType_Video loadFinishedBlock:loadFinishedBlock];
}

- (YSWhiteBoardView *)createWhiteBoardWithFileId:(NSString *)fileId
                                 isFromLocalUser:(BOOL)isFromMe
                                         isMedia:(BOOL)isMedia
                                       mediaType:(YSWhiteBordMediaType)mediaType
                               loadFinishedBlock:(wbLoadFinishedBlock)loadFinishedBlock
{
    if (![fileId bm_isNotEmpty] || [fileId isEqualToString:@"0"])
    {
        return nil;
    }
    CGRect frame = CGRectMake(whiteBoardViewCurrentLeft, whiteBoardViewCurrentTop, self.whiteBoardViewDefaultSize.width, self.whiteBoardViewDefaultSize.height);
            
    YSWhiteBoardView *whiteBoardView = [[YSWhiteBoardView alloc] initWithFrame:frame fileId:fileId isMedia:isMedia mediaType:mediaType loadFinishedBlock:loadFinishedBlock];
    
    whiteBoardView.delegate = self;
    
    if (mediaType == YSWhiteBordMediaType_Audio)
    {
        frame = whiteBoardView.frame;
    }
    if (isFromMe)
    {
        if (!whiteBoardView.positionData && [self isCanControlWhiteBoardView])
        {
            CGFloat x = whiteBoardViewCurrentLeft / (self.mainWhiteBoardView.bm_width - whiteBoardView.bm_width);
            CGFloat y = whiteBoardViewCurrentTop / (self.mainWhiteBoardView.bm_height - whiteBoardView.bm_height);
            CGFloat scaleWidth = whiteBoardView.bm_width / self.mainWhiteBoardView.bm_width;
            CGFloat scaleHeight = whiteBoardView.bm_height / self.mainWhiteBoardView.bm_height;
            
            NSDictionary * positionData = @{@"x":@(x),@"y":@(y),@"width":@(scaleWidth),@"height":@(scaleHeight),@"small":@NO,@"full":@NO,@"type":@"init",@"instanceId":whiteBoardView.whiteBoardId};
            whiteBoardView.positionData = positionData;
            
            NSString * msgID = [NSString stringWithFormat:@"MoreWhiteboardState_%@", whiteBoardView.whiteBoardId];
            
            NSString * associatedMsgID = [NSString stringWithFormat:@"DocumentFilePage_ExtendShowPage_%@", whiteBoardView.whiteBoardId];
            
            [YSRoomUtil pubWhiteBoardMsg:sYSSignalMoreWhiteboardState msgID:msgID data:positionData extensionData:nil associatedMsgID:associatedMsgID expires:0 completion:nil];
        }
    }
    whiteBoardView.mainWhiteBoard = self.mainWhiteBoardView;
    
    if (self.isBeginClass)
    {
        [whiteBoardView remotePubMsg:self.beginClassMessage];
    }
    
    if ([self isUserCanDraw])
    {
        NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
        [message bm_setString:[YSRoomInterface instance].localUser.peerID forKey:@"id"];
        [message setObject:@{ @"candraw" : @(YES) } forKey:@"properties"];
        [whiteBoardView userPropertyChanged:message];
        
        [whiteBoardView brushToolsDidSelect:[YSBrushToolsManager shareInstance].currentBrushToolType];
    }

    if (self.connectH5CoursewareUrlParameters)
    {
        [whiteBoardView changeConnectH5CoursewareUrlParameters:self.connectH5CoursewareUrlParameters];
    }
    
    if (self.connectH5CoursewareUrlCookies)
    {
        [whiteBoardView setConnectH5CoursewareUrlCookies:self.connectH5CoursewareUrlCookies];
    }
    
    [whiteBoardView refreshWhiteBoard];

    [self makeCurrentWhiteBoardViewPoint];

    for (NSDictionary *dictionary in self.sharpChangeArray)
    {
        NSObject *data = [dictionary objectForKey:@"data"];
        NSDictionary *tDataDic = [YSRoomUtil convertWithData:data];
        NSString *whiteboardID = [tDataDic objectForKey:@"whiteboardID"];
        
        if ([whiteboardID isEqualToString:whiteBoardView.whiteBoardId])
        {
            [whiteBoardView remotePubMsg:dictionary];
        }
    }
    
    return whiteBoardView;
}

- (void)makeCurrentWhiteBoardViewPoint
{
    [self makeCurrentWhiteBoardViewPointReset:NO];
}

- (void)makeCurrentWhiteBoardViewPointReset:(BOOL)reset
{
    static NSUInteger loopCount = 0;
    static NSUInteger lineCount = 0;

    if (reset)
    {
        loopCount = 0;
        lineCount = 0;
        whiteBoardViewCurrentLeft = YSWhiteBoardDefaultLeft;
        whiteBoardViewCurrentTop = YSWhiteBoardDefaultTop;
        
        return;
    }
    
    whiteBoardViewCurrentTop += YSWhiteBoardDefaultTopOffset;

    CGSize size = self.whiteBoardViewDefaultSize;

    if ((whiteBoardViewCurrentTop + size.height) >= self.mainWhiteBoardView.bm_height)
    {
        lineCount++;
        whiteBoardViewCurrentLeft += YSWhiteBoardDefaultLeftOffset;
        whiteBoardViewCurrentTop = YSWhiteBoardDefaultTop*lineCount;
    }
    else
    {
        whiteBoardViewCurrentLeft += YSWhiteBoardDefaultSOffset;
    }

    if ((whiteBoardViewCurrentLeft + size.width) >= self.mainWhiteBoardView.bm_width)
    {
        loopCount++;
        lineCount = 0;
        whiteBoardViewCurrentLeft = YSWhiteBoardDefaultLeft;
        whiteBoardViewCurrentTop = YSWhiteBoardDefaultTop*(loopCount+0.5);
    }
    
    if (((whiteBoardViewCurrentTop + size.height) >= self.mainWhiteBoardView.bm_height) || ((whiteBoardViewCurrentLeft + size.width) >= self.mainWhiteBoardView.bm_width))
    {
        loopCount = 0;
        lineCount = 0;
        whiteBoardViewCurrentLeft = YSWhiteBoardDefaultLeft;
        whiteBoardViewCurrentTop = YSWhiteBoardDefaultTop;
    }
}

- (void)clickToBringVideoToFront:(UIView *)whiteBoard
{
    YSWhiteBoardView *whiteBoardView = (YSWhiteBoardView *)whiteBoard;
    [self setTheCurrentDocumentFileID:whiteBoardView.fileId];
}

#pragma mark 拖拽手势

- (void)panToMoveWhiteBoardView:(UIView *)whiteBoard withGestureRecognizer:(UIPanGestureRecognizer *)pan
{
    YSWhiteBoardView * whiteBoardView = (YSWhiteBoardView *)whiteBoard;
    
    if (whiteBoardView.pageControlView.isAllScreen)
    {
        return;
    }
    
    if (!self.isDraging)
    {
        if ([whiteBoardView isEqual:self.mainWhiteBoardView])
        {
            [self.dragImageView removeFromSuperview];
            self.dragImageView = nil;
            return;
        }
        CGPoint point = [pan locationInView:pan.view];
        if (point.y<30)
        {
            self.isDraging = YES;
        }
        else
        {
            [self.dragImageView removeFromSuperview];
            self.dragImageView = nil;
            return;
        }
    }
    
    CGPoint endPoint = [pan translationInView:whiteBoardView];
    
    if (!self.dragImageView)
    {
        UIImage * img = [whiteBoardView bm_screenshot];
        self.dragImageView = [[UIImageView alloc]initWithImage:img];
        [self.mainWhiteBoardView addSubview:self.dragImageView];
    }

        CGFloat dragImageViewX = whiteBoardView.bm_originX + endPoint.x;
        CGFloat dragImageViewY = whiteBoardView.bm_originY + endPoint.y;
        
        if (dragImageViewX + whiteBoardView.bm_width >= self.mainWhiteBoardView.bm_width-1)
        {
            dragImageViewX = self.mainWhiteBoardView.bm_width - 1 - whiteBoardView.bm_width;
        }
        else if (dragImageViewX <= 1)
        {
            dragImageViewX = 1;
        }
        
        if (dragImageViewY + whiteBoardView.bm_height >= self.mainWhiteBoardView.bm_height - 1)
        {
            dragImageViewY = self.mainWhiteBoardView.bm_height - 1 - whiteBoardView.bm_height;
        }
        else if (dragImageViewY <= 1)
        {
            dragImageViewY = 1;
        }
        
        self.dragImageView.frame = CGRectMake(dragImageViewX, dragImageViewY, whiteBoardView.bm_width, whiteBoardView.bm_height);
        
    if (pan.state == UIGestureRecognizerStateEnded)
    {
        whiteBoardView.frame = self.dragImageView.frame;
        
        // x,y值在主白板上的比例
        CGFloat scaleLeft = whiteBoardView.bm_originX / (self.mainWhiteBoardView.bm_width - whiteBoardView.bm_width);
        CGFloat scaleTop = whiteBoardView.bm_originY / (self.mainWhiteBoardView.bm_height - whiteBoardView.bm_height);
        // 宽，高值在主白板上的比例
        CGFloat scaleWidth = whiteBoardView.bm_width / self.mainWhiteBoardView.bm_width;
        CGFloat scaleHeight = whiteBoardView.bm_height / self.mainWhiteBoardView.bm_height;
        
        NSString *msgID = [NSString stringWithFormat:@"MoreWhiteboardState_%@", whiteBoardView.whiteBoardId];
        NSDictionary * data = @{@"x":@(scaleLeft),@"y":@(scaleTop),@"width":@(scaleWidth),@"height":@(scaleHeight),@"small":@NO,@"full":@NO,@"type":@"drag",@"instanceId":whiteBoardView.whiteBoardId};
        NSString *associatedMsgID = [NSString stringWithFormat:@"DocumentFilePage_ExtendShowPage_%@", whiteBoardView.whiteBoardId];
        
        [YSRoomUtil pubWhiteBoardMsg:sYSSignalMoreWhiteboardState msgID:msgID data:data extensionData:nil associatedMsgID:associatedMsgID expires:0 completion:nil];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.dragImageView removeFromSuperview];
            self.dragImageView = nil;
            self.isDraging = NO;
        });
    }
    else if (pan.state == UIGestureRecognizerStateCancelled)
    {
        [self.dragImageView removeFromSuperview];
        self.dragImageView = nil;
    }
    
}

#pragma mark 拖拽手势事件  拖拽右下角缩放View

- (void)panToZoomWhiteBoardView:(YSWhiteBoardView *)whiteBoard withGestureRecognizer:(UIPanGestureRecognizer *)pan
{
    if (!self.isDragZooming)
    {
        if ([whiteBoard isEqual:self.mainWhiteBoardView])
        {
            [self.dragImageView removeFromSuperview];
            self.dragImageView = nil;
            return;
        }

        CGPoint point = [pan locationInView:pan.view.superview];
        if (point.x>whiteBoard.bm_width-50 && point.y>whiteBoard.bm_height-50)
        {
            self.isDragZooming = YES;
        }
        else
        {
            [self.dragImageView removeFromSuperview];
            self.dragImageView = nil;
            return;
        }
    }
    CGPoint endPoint = [pan translationInView:whiteBoard];
    if (!self.dragImageView)
    {
        UIImage * img = [whiteBoard bm_screenshot];
        self.dragImageView = [[UIImageView alloc]initWithImage:img];
        [self.mainWhiteBoardView addSubview:self.dragImageView];
    }
    
    //拖动时小白板的尺寸
    CGFloat dragImageViewW = 0;
    CGFloat dragImageViewH = 0;
    
    if (endPoint.x >= endPoint.y)
    {
        dragImageViewW = whiteBoard.bm_width + endPoint.x;
        dragImageViewH = dragImageViewW / 5.0f * 3.0f;
    }
    else
    {
        dragImageViewH = whiteBoard.bm_height + endPoint.y;
        dragImageViewW = dragImageViewH / 3.0f * 5.0f;
    }
    
    //超出边界时
    if (whiteBoard.bm_originX + dragImageViewW >= self.mainWhiteBoardView.bm_width - 1)
    {
        dragImageViewW = self.mainWhiteBoardView.bm_width - 1 - whiteBoard.bm_originX;
        dragImageViewH = dragImageViewW / 5.0f * 3.0f;
    }
    else if (whiteBoard.bm_originY + dragImageViewH >= self.mainWhiteBoardView.bm_height - 1)
    {
        dragImageViewH = self.mainWhiteBoardView.bm_height - 1 - whiteBoard.bm_originY;
        dragImageViewW = dragImageViewH / 3.0f * 5.0f;
    }
    
    //小于默认时
    if (dragImageViewW <= self.whiteBoardViewDefaultSize.width || dragImageViewH <= self.whiteBoardViewDefaultSize.height)
    {
        dragImageViewW = self.whiteBoardViewDefaultSize.width;
        dragImageViewH = self.whiteBoardViewDefaultSize.height;
    }
    
    self.dragImageView.frame = CGRectMake(whiteBoard.bm_originX, whiteBoard.bm_originY, dragImageViewW, dragImageViewH);
            
    if (pan.state == UIGestureRecognizerStateEnded)
    {
        whiteBoard.frame =  self.dragImageView.frame;
        [whiteBoard refreshWhiteBoard];
        
        //x,y值在主白板上的比例
        CGFloat scaleLeft = whiteBoard.bm_originX / (self.mainWhiteBoardView.bm_width - dragImageViewW);
        CGFloat scaleTop = whiteBoard.bm_originY / (self.mainWhiteBoardView.bm_height - dragImageViewH);
        
        //宽，高值在主白板上的比例
        CGFloat scaleWidth = dragImageViewW / self.mainWhiteBoardView.bm_width;
        CGFloat scaleHeight = dragImageViewH / self.mainWhiteBoardView.bm_height;
        
        NSString *msgID = [NSString stringWithFormat:@"MoreWhiteboardState_%@", whiteBoard.whiteBoardId];
        NSDictionary * data = @{@"x":@(scaleLeft),@"y":@(scaleTop),@"width":@(scaleWidth),@"height":@(scaleHeight),@"small":@NO,@"full":@NO,@"type":@"resize",@"instanceId":whiteBoard.whiteBoardId};
        NSString *associatedMsgID = [NSString stringWithFormat:@"DocumentFilePage_ExtendShowPage_%@", whiteBoard.whiteBoardId];
        
        [YSRoomUtil pubWhiteBoardMsg:sYSSignalMoreWhiteboardState msgID:msgID data:data extensionData:nil associatedMsgID:associatedMsgID expires:0 completion:nil];
        
        [self.dragImageView removeFromSuperview];
        self.dragImageView = nil;
        self.isDragZooming = NO;
    }
}

///接收信令进行拖拽和缩放

- (void)receiveMessageToMoveAndZoomWith:(NSDictionary *)message WithInlist:(BOOL)inlist
{
    NSString *instanceId = [message bm_stringForKey:@"instanceId"];
    NSString *fileId = [YSRoomUtil getFileIdFromSourceInstanceId:instanceId];
    if (!fileId || [fileId isEqualToString:YSDefaultWhiteBoardId])
    {
        return;
    }
    
    if (fileId)
    {
        if (!self.allPositionDict)
        {
            self.allPositionDict = [[NSMutableDictionary alloc] init];
        }
        [self.allPositionDict setObject:message forKey:fileId];
    }
    
    YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithFileId:fileId];
    if (!whiteBoardView)
    {
        return;
    }
    
    if (inlist)
    {
        whiteBoardView.positionData = message;
        if ([message bm_boolForKey:@"small"])
        {//最小化
            whiteBoardView.hidden = YES;
            self.mainWhiteBoardView.collectBtn.selected = YES;
        }
        
        [whiteBoardView refreshWhiteBoard];
    }
    else
    {
        NSString * type = [message bm_stringForKey:@"type"];
        
        if ([type isEqualToString:@"drag"] || [type isEqualToString:@"resize"])
        {
            whiteBoardView.positionData = message;
            [whiteBoardView refreshWhiteBoard];
        }
        else if ([type isEqualToString:@"small"])
        {//最小化

            whiteBoardView.hidden = [message bm_boolForKey:@"small"];
            return;
         }
        else if ([type isEqualToString:@"full"] || [type isEqualToString:@"init"])
        {//最大化
 
            whiteBoardView.positionData = message;
            [whiteBoardView refreshWhiteBoard];
            
            if ( [message bm_boolForKey:@"full"])
            {
                [whiteBoardView bm_bringToFront];
            }
        }
    }
    
    [self setTheCurrentDocumentFileID:fileId];
}

#pragma mark - 课件列表管理

/// 变更白板窗口背景色
- (void)changeMainWhiteBoardBackgroudColor:(UIColor *)color
{
    [self.mainWhiteBoardView changeWhiteBoardBackgroudColor:color];
}

/// 变更白板画板背景色
- (void)changeMainCourseViewBackgroudColor:(UIColor *)color
{
    [self.mainWhiteBoardView changeCourseViewBackgroudColor:color];
}

/// 变更白板背景图
- (void)changeMainWhiteBoardBackImage:(UIImage *)image;
{
    [self.mainWhiteBoardView changeMainWhiteBoardBackImage:image];
}

/// 变更白板窗口背景色
- (void)changeAllWhiteBoardBackgroudColor:(UIColor *)color
{
    [self changeMainWhiteBoardBackgroudColor:color];
    
    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        [whiteBoardView changeWhiteBoardBackgroudColor:color];
    }
}

/// 变更白板画板背景色
- (void)changeAllCourseViewBackgroudColor:(UIColor *)color
{
    [self changeMainCourseViewBackgroudColor:color];
    
    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        [whiteBoardView changeCourseViewBackgroudColor:color];
    }
}

/// 变更白板背景图
- (void)changeAllWhiteBoardBackImage:(nullable UIImage *)image
{
    [self changeMainWhiteBoardBackImage:image];
    
    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        [whiteBoardView changeMainWhiteBoardBackImage:image];
    }
}

/// 变更H5课件地址参数，此方法会刷新当前H5课件以变更新参数
- (void)changeConnectH5CoursewareUrlParameters:(NSDictionary *)parameters
{
    if ([parameters bm_isNotEmptyDictionary])
    {
        self.connectH5CoursewareUrlParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    }
    else
    {
        self.connectH5CoursewareUrlParameters = [NSMutableDictionary dictionary];
    }
    
    [self.mainWhiteBoardView changeConnectH5CoursewareUrlParameters:self.connectH5CoursewareUrlParameters];
    
    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        [whiteBoardView changeConnectH5CoursewareUrlParameters:self.connectH5CoursewareUrlParameters];
    }
}

- (void)setConnectH5CoursewareUrlCookies:(nullable NSArray <NSDictionary *> *)cookies;
{
    _connectH5CoursewareUrlCookies = [NSArray arrayWithArray:cookies];
}

- (void)refreshWhiteBoard
{
    CGFloat scale = self.mainWhiteBoardView.bm_width / self.mainWhiteBoardView.bm_height;
    
    CGFloat height = 0;
    CGFloat width = 0;
    if (scale > 5.0/3.0)
    {
        height = self.mainWhiteBoardView.bm_height * 0.6f;
        width = height * 5.0/3.0;
    }
    else
    {
        width = self.mainWhiteBoardView.bm_width * 0.6f;
        height = width * 3.0/5.0;
    }
    
    
    self.whiteBoardViewDefaultSize = CGSizeMake(width, height);
    
    [self.mainWhiteBoardView refreshWhiteBoard];
        
    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        [whiteBoardView refreshWhiteBoard];
    }
}

- (void)freshCurrentCourse
{
}


#pragma -
#pragma mark 课件管理

- (NSDictionary *)createWhiteBoard:(NSString *)companyid
{
    //创建白板
    NSNumber * fileprop = @(0);
    NSNumber * size =@(0);
    NSNumber * status = @(1);
    NSString * type = @"0";
    NSString * uploadtime = @"2017-08-31 16:41:23";
    NSString * uploaduserid = [YSRoomInterface instance].localUser.peerID;
    NSString * uploadusername = [YSRoomInterface instance].localUser.nickName;
    
    NSDictionary *tDic =  @{
                            @"active" :@(1),
                            @"companyid":companyid,
                            @"fileprop" :fileprop,
                            @"size" :(size != nil) ? size : @(0),
                            @"status":(status != nil) ? status : @(1),
                            @"type":type?type:@"0",
                            @"uploadtime":uploadtime,
                            @"uploaduserid" :uploaduserid?uploaduserid:@"",
                            @"uploadusername" :uploadusername?uploadusername:@"",
                            @"downloadpath":@"",
                            @"dynamicppt" :@(false),
                            @"fileid" :@"0",
                            @"filename":@"whiteboard",//@"白板",
                            @"filepath":@"",
                            @"fileserverid":@(0),
                            @"filetype" :@"whiteboard",//MTLocalized(@"Title.whiteBoard"),//@"whiteboard",
                            @"isconvert" :@(1),
                            @"newfilename":@"whiteboard",//@"白板",
                            @"pagenum" :@(1),
                            @"pdfpath":@"",
                            @"swfpath" :@"",
                            @"isContentDocument":@(0),
                            @"currpage":@(1)
                            };
    
    [self addOrReplaceDocumentFile:tDic];
    
    return tDic;
}

#pragma mark  添加课件
- (void)addDocumentWithFileDic:(NSDictionary *)file
{
    NSNumber *isContentDocument = file[@"isContentDocument"];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:file];
    [dict setValue:isContentDocument forKey:@"isContentDocument"];
    
    YSFileModel *model = [[YSFileModel alloc] init];
    if (dict[@"filedata"])
    {
        //[model setValuesForKeysWithDictionary:dict];
        //[model setValuesForKeysWithDictionary:dict[@"filedata"]];
        [model updateWithServerDic:dict];
        [model updateWithServerDic:dict[@"filedata"]];
    }
    else
    {
        //[model setValuesForKeysWithDictionary:dict];
        [model updateWithServerDic:dict];
    }
    [self.docmentList addObject:model];
}

- (BOOL)addOrReplaceDocumentFile:(NSDictionary *)file
{
    NSString *fileid = [file bm_stringForKey:@"fileid"];
    if (!fileid)
    {
        NSDictionary *filedata = [file bm_dictionaryForKey:@"filedata"];
        
        fileid = [filedata bm_stringForKey:@"fileid"];
        if (!fileid)
        {
            return NO;
        }
    }
    
    YSFileModel *model = [self getDocumentWithFileID:fileid];
    
    NSNumber *isContentDocument = file[@"isContentDocument"];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:file];
    [dict setValue:isContentDocument forKey:@"isContentDocument"];
    
    YSFileModel *fileModel = model;
    if (!model)
    {
        fileModel = [[YSFileModel alloc] init];
        [self.docmentList addObject:fileModel];
    }
    
    //[fileModel setValuesForKeysWithDictionary:dict];
    [fileModel updateWithServerDic:dict];
    NSDictionary *fileData = dict[@"filedata"];
    if (fileData.count > 0)
    {
        //[fileModel setValuesForKeysWithDictionary:fileData];
        [fileModel updateWithServerDic:fileData];
    }
    
    if ([[dict allKeys] containsObject:@"fileprop"])
    {
        fileModel.fileprop = [dict bm_uintForKey:@"fileprop"];
        fileModel.isGeneralFile = YES;
        if (fileModel.fileprop == 1 || fileModel.fileprop == 2)
        {
            fileModel.isDynamicPPT = YES;
            fileModel.isGeneralFile = NO;
        }
        else
        {
            fileModel.isDynamicPPT = NO;
        }
        if (fileModel.fileprop == 3)
        {
            fileModel.isH5Document = YES;
            fileModel.isGeneralFile = NO;
        }
        else
        {
            fileModel.isH5Document = NO;
        }
    }
    else
    {
        BOOL isDynamicPPT = [dict bm_boolForKey:@"isDynamicPPT"];
        BOOL isH5Document = [dict bm_boolForKey:@"isH5Document"];
        if (isDynamicPPT)
        {
            fileModel.fileprop = 1;
        }
        if (isH5Document)
        {
            fileModel.fileprop = 3;
        }
    }

    return YES;
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
    
    if (![self isOneWhiteBoardView])
    {
        [self removeWhiteBoardViewWithFileId:fileId];
    }
}

- (void)setTheCurrentDocumentFileID:(NSString *)fileId
{
    
    [self setTheCurrentDocumentFileID:fileId sendArrange:YES];
}

- (void)setTheCurrentDocumentFileID:(NSString *)fileId sendArrange:(BOOL)sendArrange
{
    
    if ([self isOneWhiteBoardView])
    {
        _currentFileId = fileId;
        return;
    }
    
    if ([fileId isEqualToString:_currentFileId])
    {
        [self.mainWhiteBoardView.collectBtn bm_bringToFront];
        return;
    }
    UIView *firstResponder = [self.mainWhiteBoardView bm_firstResponder];
    
    if (firstResponder.tag == YSWHITEBOARD_TEXTVIEWTAG)
    {
        [self.mainWhiteBoardView endEditing:YES];
    }
    _currentFileId = fileId;
    
    YSWhiteBoardView *whiteBoardView = self.mainWhiteBoardView;
    if (![fileId isEqualToString:@"0"])
    {
        whiteBoardView = [self getWhiteBoardViewWithFileId:fileId];
        if (whiteBoardView)
        {
            [whiteBoardView bm_bringToFront];
        }
    }
    
    if (sendArrange && [[YSWhiteBoardManager shareInstance] isCanControlWhiteBoardView])
    {
        [self sendArrangeWhiteBoardView];
    }
    
    for (YSWhiteBoardView *whiteBoard in self.coursewareViewList)
    {
        if (whiteBoard.mediaType == YSWhiteBordMediaType_Audio)
        {
            continue;
        }
                
        YSRoomUser * localUser = [YSRoomInterface instance].localUser;
        
        if ([whiteBoard.fileId isEqualToString:fileId])
        {
            whiteBoard.isCurrent = YES;
            whiteBoard.topBar.backgroundColor = YSWhiteBoard_TopBarBackGroudColor;
            [whiteBoard bm_addShadow:3.0f Radius:0.0f BorderColor:YSWhiteBoard_BorderColor ShadowColor:YSWhiteBoard_BackGroudColor Offset:CGSizeMake(1, 2) Opacity:0.6f];
            whiteBoard.topBar.isCurrent = YES;
            if (localUser.role == YSUserType_Student)
            {
                if ([localUser.properties bm_containsObjectForKey:@"candraw"])
                {
                    BOOL candraw = [localUser.properties bm_boolForKey:@"candraw"];
                    
                    if (candraw && self.roomConfig.canPageTurningFlag)
                    {
                        whiteBoard.pageControlView.allowTurnPage = YES;
                    }
                    else
                    {
                        whiteBoard.pageControlView.allowTurnPage = NO;
                    }
                }
            }
        }
        else
        {
            whiteBoard.isCurrent = NO;
            whiteBoard.topBar.backgroundColor = YSWhiteBoard_UnTopBarBackGroudColor;
            [whiteBoard bm_addShadow:3.0f Radius:0.0f BorderColor:YSWhiteBoard_UnBorderColor ShadowColor:YSWhiteBoard_BackGroudColor Offset:CGSizeMake(1, 2) Opacity:0.6f];
            whiteBoard.topBar.isCurrent = NO;
            if (whiteBoard.pageControlView.isAllScreen)
            {
                whiteBoard.pageControlView.isAllScreen = NO;
            }
            
            if (localUser.role == YSUserType_Student)
            {
                whiteBoard.pageControlView.allowTurnPage = NO;
            }
        }
    }
    
    [self.mainWhiteBoardView.collectBtn bm_bringToFront];
}

///多窗口排序后的whiteBoardId列表
- (NSArray *)getWhiteBoardViewIdArrangeList
{
    NSArray *subviews = self.mainWhiteBoardView.subviews;
    NSMutableArray *whiteboardIdList = [[NSMutableArray alloc] init];
    for (UIView *view in subviews)
    {
        if ([view isKindOfClass:[YSWhiteBoardView class]])
        {
            YSWhiteBoardView *whiteBoardView1 = (YSWhiteBoardView *)view;
            [whiteboardIdList addObject:whiteBoardView1.whiteBoardId];
        }
    }
    
    return whiteboardIdList;
}

///多窗口排序后的窗口列表
- (NSArray *)getWhiteBoardViewArrangeList
{
    NSArray *subviews = self.mainWhiteBoardView.subviews;
    NSMutableArray *whiteboardList = [[NSMutableArray alloc] init];
    for (UIView *view in subviews)
    {
        if ([view isKindOfClass:[YSWhiteBoardView class]])
        {
            YSWhiteBoardView *whiteBoardView1 = (YSWhiteBoardView *)view;
            [whiteboardList addObject:whiteBoardView1];
        }
    }
    
    return whiteboardList;
}

- (void)sendArrangeWhiteBoardView
{
    NSArray *arrangeList = [self getWhiteBoardViewIdArrangeList];
    [self sendArrangeWhiteBoardViewWithArrangeList:arrangeList];
}

- (void)sendArrangeWhiteBoardViewWithArrangeList:(NSArray *)arrangeWhiteboardIdList
{
    if ([arrangeWhiteboardIdList bm_isNotEmpty])
    {
        YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithFileId:self.currentFileId];
        NSString *instanceId = whiteBoardView.whiteBoardId;
        if (![instanceId bm_isNotEmpty])
        {
            instanceId = @"";
        }
        NSDictionary *data = @{ @"type" : @"sort", @"instanceId" : instanceId, @"sort" : arrangeWhiteboardIdList, @"hideAll" : @(NO)};
        NSString *associatedMsgID = [NSString stringWithFormat:@"DocumentFilePage_ExtendShowPage_%@", whiteBoardView.whiteBoardId];

        [YSRoomUtil pubWhiteBoardMsg:sYSSignalMoreWhiteboardGlobalState msgID:sYSSignalMoreWhiteboardGlobalState data:data extensionData:nil associatedMsgID:associatedMsgID expires:0 completion:nil];
    }
}


- (YSFileModel *)currentFile
{
    NSString *fileId = self.currentFileId;
    if (!fileId)
    {
        fileId = @"0";
    }
    
    YSFileModel *file = [self getDocumentWithFileID:fileId];
    
    return file;
}


#pragma mark - 课件窗口列表管理

#pragma mark  添加课件窗口
/// 创建新窗口并添加
//- (void)addWhiteBoardViewWithFileId:(NSString *)fileId
//{
//    YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithFileId:fileId];
//    if (whiteBoardView)
//    {
//        [whiteBoardView bm_bringToFront];
//        whiteBoardView;
//        return;
//    }
//
//    whiteBoardView = [self createWhiteBoardWithFileId:fileId loadFinishedBlock:^{
//    }];
//
//    [self.coursewareViewList addObject:whiteBoardView];
//    [self.mainWhiteBoardView addSubview:whiteBoardView];
//
//    whiteBoardView.backgroundColor = [UIColor bm_randomColor];
//
//    return;
//}

/// 添加新窗口不创建
- (void)addWhiteBoardViewWithWhiteBoardView:(YSWhiteBoardView *)whiteBoardView
{
    if (whiteBoardView)
    {
        [whiteBoardView bm_bringToFront];
    }
    
    if ([self.coursewareViewList containsObject:whiteBoardView])
    {
        return;
    }
        
    [self.coursewareViewList addObject:whiteBoardView];
    [self.mainWhiteBoardView addSubview:whiteBoardView];
    
    if (self.wbDelegate && [self.wbDelegate respondsToSelector:@selector(onWhiteBoardChangedFileWithFileList:)])
    {
        NSMutableArray *fileList = [[NSMutableArray alloc] init];
        for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
        {
            if (!whiteBoardView.isMediaView)
            {
                [fileList addObject:whiteBoardView.fileId];
            }
        }
        
        if (![fileList containsObject:self.mainWhiteBoardView.fileId])
        {
            [fileList addObject:self.mainWhiteBoardView.fileId];
        }
        
        [self.wbDelegate onWhiteBoardChangedFileWithFileList:fileList];
    }
    
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
    if ([self.mainWhiteBoardView.fileId isEqualToString:fileId])
    {
        return self.mainWhiteBoardView;
    }
    // 未判断 default
    if ([fileId isEqualToString:@"0"])
    {
        return self.mainWhiteBoardView;
    }
    return nil;
}

- (YSWhiteBoardView *)getWhiteBoardViewWithWhiteBoardId:(NSString *)whiteBoardId
{
    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        if ([whiteBoardView.whiteBoardId isEqualToString:whiteBoardId])
        {
            return whiteBoardView;
        }
    }
    return nil;
}



#pragma mark  删除课件窗口
- (void)removeWhiteBoardViewWithFileId:(NSString *)fileId
{
    YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithFileId:fileId];
    if (whiteBoardView)
    {
        [self removeWhiteBoardViewWithWhiteBoardView:whiteBoardView];
    }
}

- (void)removeWhiteBoardViewWithWhiteBoardView:(YSWhiteBoardView *)whiteBoardView
{
    if (whiteBoardView)
    {
        [self.coursewareViewList removeObject:whiteBoardView];
        
        if (whiteBoardView.superview)
        {
            [whiteBoardView removeFromSuperview];
        }
        
        if ([self isCanControlWhiteBoardView])
        {
            if ([whiteBoardView.fileId isEqualToString:self.currentFileId])
            {
                YSWhiteBoardView *lastWhiteBoardView = self.coursewareViewList.lastObject;
                if (lastWhiteBoardView)
                {
                    [self setTheCurrentDocumentFileID:lastWhiteBoardView.fileId];
                }
                else
                {
                    [self setTheCurrentDocumentFileID:self.mainWhiteBoardView.fileId];
                }
            }
        }

        [whiteBoardView destroy];
        whiteBoardView = nil;
        
        if (self.wbDelegate && [self.wbDelegate respondsToSelector:@selector(onWhiteBoardChangedFileWithFileList:)])
        {
            NSMutableArray *fileList = [[NSMutableArray alloc] init];
            for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
            {
                [fileList addObject:whiteBoardView.fileId];
            }
            
            if (![fileList containsObject:self.mainWhiteBoardView.fileId])
            {
                [fileList addObject:self.mainWhiteBoardView.fileId];
            }
            
            [self.wbDelegate onWhiteBoardChangedFileWithFileList:fileList];
        }
    }
}

#pragma mark  删除所有课件窗口
- (void)removeAllWhiteBoardView
{
    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        if (whiteBoardView.superview)
        {
            [whiteBoardView removeFromSuperview];
        }
        
        [whiteBoardView destroy];
    }
    
    [self.coursewareViewList removeAllObjects];
    
    if (self.wbDelegate && [self.wbDelegate respondsToSelector:@selector(onWhiteBoardChangedFileWithFileList:)])
    {
        NSMutableArray *fileList = [[NSMutableArray alloc] init];
        if (![fileList containsObject:self.mainWhiteBoardView.fileId])
        {
            [fileList addObject:self.mainWhiteBoardView.fileId];
        }
        
        [self.wbDelegate onWhiteBoardChangedFileWithFileList:fileList];
    }
}


#pragma -
#pragma mark 课件操作

/// 刷新白板课件
- (void)freshCurrentCourseWithFileId:(NSString *)fileId
{
    YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithFileId:fileId];
    
    if (whiteBoardView)
    {
        [whiteBoardView freshCurrentCourse];
    }
}

/// 切换课件
- (void)changeCourseWithFileId:(NSString *)fileId
{
    YSFileModel *fileModel = [self getDocumentWithFileID:fileId];
    if (!fileModel)
    {
        return;
    }
    
    if ([YSRoomUtil checkIsMedia:fileModel.filetype])
    {
        BOOL isVideo = [YSRoomUtil checkIsVideo:fileModel.filetype];
        
        NSString *instanceId = [YSRoomUtil getSourceInstanceIdFromFileId:fileModel.fileid];
        NSDictionary *sendDic = @{@"filename": fileModel.filename,
                                  @"fileid": fileModel.fileid,
                                  @"pauseWhenOver": @(true),
                                  @"type": @"media",
                                  @"source": @"mediaFileList",
                                  @"whiteboardId":instanceId
                                };
        
        NSString *url = [YSRoomUtil absoluteFileUrl:fileModel.swfpath withServerDic:self.serverAddressInfoDic];
        
        if (self.mediaFileModel)
        {
            // 切换相同媒体时，暂停或继续播放
            if ([self.mediaFileModel.fileid isEqualToString:fileModel.fileid])
            {
                BOOL isPause = self.mediaFileModel.isPause;
                [[YSRoomInterface instance] pauseMediaFile:!isPause];
                
                return;
            }

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
                    [[YSRoomInterface instance] startShareMediaFile:url isVideo:isVideo toID:toID attributes:sendDic block:nil];
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
            [[YSRoomInterface instance] startShareMediaFile:url isVideo:isVideo toID:toID attributes:sendDic block:nil];
        }
        
        return;
    }
    
    if ([self isOneWhiteBoardView])
    {
        NSString *sourceInstanceId = YSDefaultWhiteBoardId;
        NSDictionary *fileDic = [YSFileModel fileDataDocDic:fileModel sourceInstanceId:sourceInstanceId];
        
        [YSRoomUtil pubWhiteBoardMsg:sYSSignalShowPage msgID:sYSSignalDocumentFilePage_ShowPage data:fileDic extensionData:nil associatedMsgID:nil expires:0 completion:nil];
    }
    else
    {
        NSString *sourceInstanceId = [YSRoomUtil getSourceInstanceIdFromFileId:fileId];
        NSDictionary *fileDic = [YSFileModel fileDataDocDic:fileModel sourceInstanceId:sourceInstanceId];
        
        NSString *msgID = [NSString stringWithFormat:@"%@%@", sYSSignalDocumentFilePage_ExtendShowPage, [YSRoomUtil getwhiteboardIDFromFileId:fileId]];

        [YSRoomUtil pubWhiteBoardMsg:sYSSignalExtendShowPage msgID:msgID data:fileDic extensionData:nil associatedMsgID:nil expires:0 completion:nil];
    }
}

- (void)changeCourseWithFileId:(NSString *)fileId toID:(NSString *)toID save:(BOOL)save
{
    YSFileModel *fileModel = [self getDocumentWithFileID:fileId];
    if (!fileModel)
    {
        return;
    }
    
    if ([self isOneWhiteBoardView])
    {
        NSString *sourceInstanceId = YSDefaultWhiteBoardId;
        NSDictionary *fileDic = [YSFileModel fileDataDocDic:fileModel sourceInstanceId:sourceInstanceId];
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:fileDic];
        [dic bm_setBool:YES forKey:@"initiative"];
        fileDic = dic;

        [[YSRoomInterface instance] pubMsg:sYSSignalShowPage
                                     msgID:sYSSignalDocumentFilePage_ShowPage
                                      toID:toID
                                      data:fileDic
                                      save:save
                             extensionData:nil
                           associatedMsgID:nil
                          associatedUserID:toID
                                   expires:0
                                completion:nil];
    }
    else
    {
        self.defaultFileId = fileId;
        NSString *sourceInstanceId = [YSRoomUtil getSourceInstanceIdFromFileId:fileId];
        NSDictionary *fileDic = [YSFileModel fileDataDocDic:fileModel sourceInstanceId:sourceInstanceId];
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:fileDic];
        [dic bm_setBool:YES forKey:@"initiative"];
        fileDic = dic;

        NSString *msgID = [NSString stringWithFormat:@"%@%@", sYSSignalDocumentFilePage_ExtendShowPage, [YSRoomUtil getwhiteboardIDFromFileId:fileId]];

        [[YSRoomInterface instance] pubMsg:sYSSignalExtendShowPage
                                     msgID:msgID
                                      toID:toID
                                      data:fileDic
                                      save:save
                             extensionData:nil
                           associatedMsgID:nil
                          associatedUserID:toID
                                   expires:0
                                completion:nil];
    }
}

- (void)addWhiteBordImageCourseWithDic:(NSDictionary *)uplaodDic
{
    NSMutableDictionary *docDic = [[NSMutableDictionary alloc] initWithDictionary:uplaodDic];
    
    // 0:表示普通文档　１－２动态ppt(1: 第一版动态ppt 2: 新版动态ppt ）  3:h5文档
    NSUInteger fileprop = [docDic bm_uintForKey:@"fileprop"];
    BOOL isGeneralFile = fileprop == 0 ? YES : NO;
    BOOL isDynamicPPT = fileprop == 1 || fileprop == 2 ? YES : NO;
    BOOL isH5Document = fileprop == 3 ? YES : NO;
    NSString *mediaType = @"";
    NSString *filetype = @"jpg";
    
    [docDic setObject:filetype forKey:@"filetype"];
    
    [self addDocumentWithFileDic:docDic];
    
    NSString *fileid = [docDic bm_stringTrimForKey:@"fileid" withDefault:@""];
    NSString *filename = [docDic bm_stringTrimForKey:@"filename" withDefault:@""];
    NSUInteger pagenum = [docDic bm_uintForKey:@"pagenum"];
    NSString *swfpath = [docDic bm_stringTrimForKey:@"swfpath" withDefault:@""];
    
    NSString *sourceInstanceId = [YSRoomUtil getSourceInstanceIdFromFileId:fileid];
    NSInteger isContentDocument = [docDic bm_intForKey:@"isContentDocument"];
    
    NSDictionary *tDataDic = @{
        @"sourceInstanceId":sourceInstanceId,
        @"isDel" : @(false),
        @"isGeneralFile" : @(isGeneralFile),
        @"isDynamicPPT" : @(isDynamicPPT),
        @"isH5Document" : @(isH5Document),
        @"mediaType" : mediaType,
        @"isMedia" : @(false),
        @"filedata" : @{
                @"fileid" : fileid,
                @"currpage" : @(1),
                @"pagenum" : @(pagenum),
                @"filetype" : filetype,
                @"filename" : filename,
                @"swfpath" : swfpath,
                @"pptslide" : @(1),
                @"pptstep" : @(0),
                @"steptotal" : @(0),
                @"filecategory":@(0),
                @"isContentDocument" : @(isContentDocument)
        }
    };


    if ([self isOneWhiteBoardView])
    {
        [YSRoomUtil pubWhiteBoardMsg:sYSSignalShowPage msgID:sYSSignalDocumentFilePage_ShowPage data:tDataDic extensionData:nil associatedMsgID:nil expires:0 completion:nil];
        [[YSRoomInterface instance] pubMsg:sYSSignalDocumentChange msgID:sYSSignalDocumentChange toID:YSRoomPubMsgTellAllExceptSender data:tDataDic save:NO completion:nil];
    }
    else
    {
        NSString *msgID = [NSString stringWithFormat:@"%@%@", sYSSignalDocumentFilePage_ExtendShowPage, sourceInstanceId];
        [YSRoomUtil pubWhiteBoardMsg:sYSSignalExtendShowPage msgID:msgID data:tDataDic extensionData:nil associatedMsgID:nil expires:0 completion:nil];
        
        [[YSRoomInterface instance] pubMsg:sYSSignalDocumentChange msgID:sYSSignalDocumentChange toID:YSRoomPubMsgTellAllExceptSender data:tDataDic save:NO completion:nil];
        
        NSString *whiteBoardId = [YSRoomUtil getwhiteboardIDFromFileId:fileid];
        NSString *tempMsgID = [NSString stringWithFormat:@"MoreWhiteboardState_%@", whiteBoardId];
        
        CGFloat scaleLeft = whiteBoardViewCurrentLeft / (self.mainWhiteBoardView.bm_width - self.whiteBoardViewDefaultSize.width);
        CGFloat scaleTop = whiteBoardViewCurrentTop / (self.mainWhiteBoardView.bm_height - self.whiteBoardViewDefaultSize.height);
        CGFloat scaleWidth = self.whiteBoardViewDefaultSize.width / self.mainWhiteBoardView.bm_width;
        CGFloat scaleHeight = self.whiteBoardViewDefaultSize.height / self.mainWhiteBoardView.bm_height;
        
        NSDictionary * data = @{@"x":@(scaleLeft),@"y":@(scaleTop),@"width":@(scaleWidth),@"height":@(scaleHeight),@"small":@NO,@"full":@NO,@"type":@"init",@"instanceId":whiteBoardId};
        NSString *associatedMsgID = [NSString stringWithFormat:@"DocumentFilePage_ExtendShowPage_%@", whiteBoardId];
        
        [YSRoomUtil pubWhiteBoardMsg:sYSSignalMoreWhiteboardState msgID:tempMsgID data:data extensionData:nil associatedMsgID:associatedMsgID expires:0 completion:nil];
        
    }
}

- (void)deleteCourseWithFileId:(NSString *)fileId
{
    YSFileModel *fileModel = [self getDocumentWithFileID:fileId];
    
    if (![fileModel bm_isNotEmpty])
    {
        return;
    }
    
    [self deleteCourseWithFile:fileModel];
}

- (void)deleteCourseWithFile:(YSFileModel *)fileModel
{
    if (![fileModel bm_isNotEmpty])
    {
        return;
    }
    
    if (![self isOneWhiteBoardView])
    {
        YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithFileId:fileModel.fileid];
        if (whiteBoardView)
        {
            NSString *sourceInstanceId = [YSRoomUtil getSourceInstanceIdFromFileId:fileModel.fileid];
            NSDictionary *fileDic1 = [YSFileModel fileDataDocDic:fileModel sourceInstanceId:sourceInstanceId];
            
            NSString *msgID = [NSString stringWithFormat:@"%@%@", sYSSignalDocumentFilePage_ExtendShowPage, [YSRoomUtil getwhiteboardIDFromFileId:fileModel.fileid]];
            
            [YSRoomUtil delWhiteBoardMsg:sYSSignalExtendShowPage msgID:msgID data:fileDic1 completion:nil];
        }
    }
    else
    {
        if ([self isOneWhiteBoardView] && [fileModel.fileid isEqualToString:self.currentFileId])
        {
            NSMutableArray *fileList = [[NSMutableArray alloc] init];
            for (YSFileModel *fileModel1 in self.docmentList)
            {
                if ([fileModel1.fileid isEqualToString:fileModel.fileid])
                {
                    break;
                }
                [fileList addObject:fileModel1];
            }
            
            YSFileModel *newFileModel = [self getDocumentWithFileID:@"0"];
            if ([fileList bm_isNotEmpty])
            {
                fileList = [NSMutableArray arrayWithArray:[fileList bm_reversedArray]];
                
                for (YSFileModel *fileModel1 in fileList)
                {
                    if (!fileModel1.isMedia)
                    {
                        if (![YSRoomUtil checkIsMedia:fileModel1.filetype])
                        {
                            newFileModel = fileModel1;
                            break;
                        }
                    }
                }
            }
            
            if (newFileModel)
            {
                NSString *sourceInstanceId = YSDefaultWhiteBoardId;
                NSDictionary *fileDic = [YSFileModel fileDataDocDic:newFileModel sourceInstanceId:sourceInstanceId];
                
                [YSRoomUtil pubWhiteBoardMsg:sYSSignalShowPage msgID:sYSSignalDocumentFilePage_ShowPage data:fileDic extensionData:nil associatedMsgID:nil expires:0 completion:nil];
            }
        }
    }

    NSDictionary *fileDic = [YSFileModel fileDataDocDic:fileModel sourceInstanceId:nil];
    NSMutableDictionary *sendDic = [NSMutableDictionary dictionaryWithDictionary:fileDic];
    [sendDic bm_setBool:YES forKey:@"isDel"];
    [[YSRoomInterface instance] pubMsg:sYSSignalDocumentChange msgID:sYSSignalDocumentChange toID:YSRoomPubMsgTellAll data:fileDic save:NO completion:nil];
}


/// 课件 上一页
- (void)whiteBoardPrePage
{
    [self whiteBoardPrePageWithFileId:self.currentFileId];
}

- (void)whiteBoardPrePageWithFileId:(NSString *)fileId
{
    YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithFileId:fileId];
    
    if (whiteBoardView)
    {
        [whiteBoardView whiteBoardPrePage];
    }
}

/// 课件 下一页
- (void)whiteBoardNextPage
{
    [self whiteBoardNextPageWithFileId:self.currentFileId];
}

- (void)whiteBoardNextPageWithFileId:(NSString *)fileId
{
    YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithFileId:fileId];
    
    if (whiteBoardView)
    {
        [whiteBoardView whiteBoardNextPage];
    }
}

/// 课件 跳转页
- (void)whiteBoardTurnToPage:(NSUInteger)pageNum
{
    [self whiteBoardTurnToPage:pageNum withFileId:self.currentFileId];
}

- (void)whiteBoardTurnToPage:(NSUInteger)pageNum withFileId:(NSString *)fileId
{
    YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithFileId:fileId];
    
    if (whiteBoardView)
    {
        [whiteBoardView whiteBoardTurnToPage:pageNum];
    }
}

/// 白板 放大
- (void)whiteBoardEnlarge
{
    [self whiteBoardEnlargeWithFileId:self.currentFileId];
}

- (void)whiteBoardEnlargeWithFileId:(NSString *)fileId
{
    YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithFileId:fileId];
    
    if (whiteBoardView)
    {
        [whiteBoardView whiteBoardEnlarge];
    }
}

/// 白板 缩小
- (void)whiteBoardNarrow
{
    [self whiteBoardNarrowWithFileId:self.currentFileId];
}

- (void)whiteBoardNarrowWithFileId:(NSString *)fileId
{
    YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithFileId:fileId];
    
    if (whiteBoardView)
    {
        [whiteBoardView whiteBoardNarrow];
    }
}

/// 白板 放大重置
- (void)whiteBoardResetEnlarge
{
    [self whiteBoardResetEnlargeWithFileId:self.currentFileId];
}

- (void)whiteBoardResetEnlargeWithFileId:(NSString *)fileId
{
    YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithFileId:fileId];
    
    if (whiteBoardView)
    {
        [whiteBoardView whiteBoardResetEnlarge];
    }
}


- (CGFloat)currentDocumentZoomScale
{
    return [self documentZoomScaleWithFileId:self.currentFileId];
}

- (CGFloat)documentZoomScaleWithFileId:(NSString *)fileId
{
    YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithFileId:fileId];
    return [whiteBoardView documentZoomScale];
}

#pragma -
#pragma mark 是否多课件窗口

- (BOOL)isOneWhiteBoardView
{
    if (self.roomUseType == YSRoomUseTypeLiveRoom)
    {
        return YES;
    }
    else if (self.roomConfig.isMultiCourseware)
    {
        return NO;
    }
    
    return YES;
}

#pragma -
#pragma mark 课件窗口控制权限

- (BOOL)isCanControlWhiteBoardView
{
    YSRoomUser *localUser = [YSRoomInterface instance].localUser;
    if (localUser.role == YSUserType_Teacher)
    {
        return YES;
    }
    
    if (!self.isBeginClass && localUser.role == YSUserType_Student)
    {
        return YES;
    }
    
    return NO;
}

#pragma -
#pragma mark 画笔权限

- (BOOL)isUserCanDraw
{
    YSRoomUser *localUser = [YSRoomInterface instance].localUser;
    
    if (localUser.role == YSUserType_Student)
    {
        BOOL canDraw = localUser.canDraw;
        if (canDraw)
        {
            if (self.isBeginClass)
            {
                if (self.brushToolsManager.currentBrushToolType != YSBrushToolTypeMouse)
                {
                    return YES;
                }
            }
        }

        return NO;
    }
    else if (localUser.role == YSUserType_Teacher)
    {
        return YES;
    }
    else
    { // 巡课
        return NO;
    }
}


#pragma -
#pragma mark 画笔控制

- (void)brushToolsDidSelect:(YSBrushToolType)BrushToolType
{
    [self.brushToolsManager brushToolsDidSelect:BrushToolType];
    
    if (self.mainWhiteBoardView)
    {
        [self.mainWhiteBoardView brushToolsDidSelect:BrushToolType];
    }

    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        [whiteBoardView brushToolsDidSelect:BrushToolType];
    }
}

- (void)didSelectDrawType:(YSDrawType)type color:(NSString *)hexColor widthProgress:(CGFloat)progress
{
    [self.brushToolsManager didSelectDrawType:type color:hexColor widthProgress:progress];
    
    if (type == YSDrawTypeClear)
    {
        YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithFileId:self.currentFileId];
        [whiteBoardView didSelectDrawType:type color:hexColor widthProgress:progress];
        return;
    }

    if (self.mainWhiteBoardView)
    {
        [self.mainWhiteBoardView didSelectDrawType:type color:hexColor widthProgress:progress];
    }

    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        [whiteBoardView didSelectDrawType:type color:hexColor widthProgress:progress];
    }
}

// 恢复默认工具配置设置
- (void)freshBrushToolConfig
{
    [self.brushToolsManager freshDefaultBrushToolConfigs];
    
    if (self.mainWhiteBoardView)
    {
        [self.mainWhiteBoardView freshBrushToolConfigs];
    }

    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        [whiteBoardView freshBrushToolConfigs];
    }
}

// 获取当前工具配置设置 drawType: YSBrushToolType类型  colorHex: RGB颜色  progress: 值
- (YSBrushToolsConfigs *)getCurrentBrushToolConfig
{
    return self.brushToolsManager.currentConfig;
}

// 改变默认画笔颜色
- (void)changePrimaryColorHex:(NSString *)colorHex
{
    [self.brushToolsManager changePrimaryColorHex:colorHex];
}

// 画笔颜色
- (NSString *)getPrimaryColorHex
{
    return self.brushToolsManager.primaryColorHex;

}


#pragma mark - 监听课堂 底层通知消息

- (void)loadNotifiction
{
    // checkRoom相关通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnCheckRoom:) name:YSWhiteBoardOnCheckRoomNotification object:nil];
    // 获取服务器地址
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnServerAddrs:) name:YSWhiteBoardOnServerAddrsNotification object:nil];
    // 教室文件列表的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnFileList:) name:YSWhiteBoardFileListNotification object:nil];
    // 用户属性改变通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnRoomUserPropertyChanged:) name:YSWhiteBoardOnRoomUserPropertyChangedNotification object:nil];
//    // 用户离开通知
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnRoomParticipantLeaved:) name:YSWhiteBoardOnRoomUserLeavedNotification object:nil];
//    // 用户进入通知
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnRoomParticipantJoin:) name:YSWhiteBoardOnRoomUserJoinedNotification object:nil];
//    // 自己被踢出教室通知
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnParticipantEvicted:) name:YSWhiteBoardOnSelfEvictedNotification object:nil];
    // 收到远端pubMsg消息通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnRemotePubMsg:) name:YSWhiteBoardOnRemotePubMsgNotification object:nil];
    // 收到远端delMsg消息的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnRemoteDelMsg:) name:YSWhiteBoardOnRemoteDelMsgNotification object:nil];
    // 连接教室成功的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnRoomConnectedUserlist:) name:YSWhiteBoardOnRoomConnectedNotification object:nil];
    // 断开链接的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnDisconnect:) name:YSWhiteBoardOnRoomDisconnectNotification object:nil];
    // 教室消息列表的通知
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnRemoteMsgList:) name:YSWhiteBoardOnRemoteMsgListNotification object:nil];
    // 大并发房间用户上台通知
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnBigRoomUserPublished:) name:YSWhiteBoardOnBigRoomUserPublishedNotification object:nil];
    // 白板崩溃 重新加载 重新获取msgList
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetWhiteBoard:) name:YSWhiteBoardMsgListACKNotification object:nil];
    // 预加载
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhitePreloadFile:) name:YSWhiteBoardPreloadFileNotification object:nil];
    
    // 关于画笔消息列表的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnMsgList:) name:YSWhiteBoardOnMsgListNotification object:nil];
    
    // 媒体课件相关
    // 媒体流发布状态
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnShareMediaState:) name:YSWhiteBoardOnShareMediaStateNotification object:nil];
    // 更新媒体流的信息
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnUpdateMediaStream:) name:YSWhiteBoardUpdateMediaStreamNotification object:nil];
}

/// checkRoom相关通知
- (void)roomWhiteBoardOnCheckRoom:(NSNotification *)notification
{   // 1
    NSDictionary *dict = notification.userInfo;
    NSDictionary *message = [dict bm_dictionaryForKey:YSWhiteBoardNotificationUserInfoKey];
    
    if (message)
    {
        NSDictionary *roomDic = [message bm_dictionaryForKey:@"room"];
        self.roomDic = roomDic;
        
        self.roomUseType = [self.roomDic bm_uintForKey:@"roomtype"];
        
        // 房间配置项
        NSString *chairmancontrol = [roomDic bm_stringTrimForKey:@"chairmancontrol"];
        if ([chairmancontrol bm_isNotEmpty])
        {
            self.roomConfig = [[YSRoomConfiguration alloc] initWithConfigurationString:chairmancontrol];
        }
        
        if ([[YSWhiteBoardManager shareInstance] isOneWhiteBoardView])
        {
            self.mainWhiteBoardView.collectBtn.hidden = YES;
            self.mainWhiteBoardView.whiteBoardControlView.hidden = YES;
        }
        
        if ([YSRoomInterface instance].localUser.role != YSUserType_Teacher)
        {
            self.mainWhiteBoardView.collectBtn.hidden = YES;
        }
        
        
        if (![[YSWhiteBoardManager shareInstance] isCanControlWhiteBoardView])
        {
            BOOL canDraw = [YSRoomInterface instance].localUser.canDraw;
            
            self.mainWhiteBoardView.pageControlView.allowTurnPage = canDraw;
        }
    }
}

// 获取服务器地址
- (void)roomWhiteBoardOnServerAddrs:(NSNotification *)notification
{   // 2
    NSDictionary *dict = [notification.userInfo objectForKey:YSWhiteBoardNotificationUserInfoKey];
    
    self.serverDocAddrKey = [dict objectForKey:YSWhiteBoardGetServerAddrKey] ?: self.serverDocAddrKey;
    self.serverAddrBackupKey = [dict objectForKey:YSWhiteBoardGetServerAddrBackupKey] ?: self.serverAddrBackupKey;
    self.serverWebAddrKey = [dict objectForKey:YSWhiteBoardGetWebAddrKey] ?: self.serverWebAddrKey;
    
    // 更新地址
    [self updateWebAddressInfo];
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
    
    if (self.mainWhiteBoardView)
    {
        [self.mainWhiteBoardView updateWebAddressInfo:dic];
    }
    
    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        [whiteBoardView updateWebAddressInfo:dic];
    }

    self.serverAddressInfoDic = dic;
    self.isUpdateWebAddressInfo = YES;
}

// 教室文件列表的通知
- (void)roomWhiteBoardOnFileList:(NSNotification *)notification
{   // 3
    NSDictionary *dict = notification.userInfo;
    NSArray *fileList = [dict objectForKey:YSWhiteBoardNotificationUserInfoKey] ;
    NSMutableArray *mFileList = [NSMutableArray arrayWithArray:fileList];
    
    NSDictionary *preloadFileDic = nil;
    
    [self.docmentList removeAllObjects];

    // 第一个课堂课件
    NSString *firstClassModelFileId = nil;
    // 第一个系统课件
    NSString *firstSysModelFileId = nil;

    for (NSDictionary *dic in mFileList)
    {
        if ([self addOrReplaceDocumentFile:dic])
        {
            NSNumber *type = [dic objectForKey:@"type"];
            if (type.intValue == 1)
            {
                preloadFileDic = dic;
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
    }
    
    //if ([YSRoomInterface instance].localUser.role == YSUserType_Teacher)
    {
        NSDictionary *roomDic = [[YSRoomInterface instance] getRoomProperty];
        NSString *companyid = [roomDic bm_stringTrimForKey:@"companyid"];
        [self createWhiteBoard:companyid];
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
    if (preloadFileDic)
    {
        fileId = [preloadFileDic objectForKey:@"fileid"];
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:YSWhiteBoardDocPreloadFinishNotification object:nil];
}

// 预加载
- (void)roomWhitePreloadFile:(NSNotification *)noti
{   // 4
    BOOL isNeedPreload = [noti.userInfo[@"isNeedPreload"] boolValue];
    if (isNeedPreload)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:YSWhiteBoardDocPreloadFinishNotification object:nil];
    }
}

// 链接教室成功
- (void)roomWhiteBoardOnRoomConnectedUserlist:(NSNotification *)notification
{   // 5
    NSDictionary *dict = notification.userInfo;
    NSNumber *code = [dict objectForKey:YSWhiteBoardOnRoomConnectedCodeKey];
    NSDictionary *response = [dict objectForKey:YSWhiteBoardOnRoomConnectedRoomMsgKey];
    
    [[YSRoomInterface instance] pubMsg:sYSSignalUpdateTime
                               msgID:sYSSignalUpdateTime
                                toID:[YSRoomInterface instance].localUser.peerID
                                data:@""
                                save:NO
                     associatedMsgID:nil
                    associatedUserID:nil
                             expires:0
                          completion:nil];
    
    [self roomWhiteBoardOnRoomConnectedUserlist:code response:response];
}

#pragma mark 信令排序
- (void)roomWhiteBoardOnRoomConnectedUserlist:(NSNumber *)code response:(NSDictionary *)response
{
    if (![response bm_isNotEmptyDictionary])
    {
        return;
    }

    if (![self isOneWhiteBoardView] && ![self.currentFileId isEqualToString:@"0"])
    {
        NSString *fileId = self.currentFileId;
        
        NSDictionary * dict = @{@"data":[YSFileModel fileDataDocDic:nil sourceInstanceId:nil],
                                @"fromID":[YSRoomInterface instance].localUser.peerID,
                                @"id":sYSSignalExtendShowPage,
                                @"name":sYSSignalExtendShowPage,
                                @"toID":[YSRoomInterface instance].localUser.peerID,
                                @"ts":@(0)};
        
        [self roomWhiteBoardOnRemotePubMsgWithMessage:dict inList:YES];
        [self setTheCurrentDocumentFileID:fileId];
    }
        
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:response];

    NSMutableDictionary *myselfDict = [NSMutableDictionary dictionary];
    [myselfDict setValue:[YSRoomInterface instance].localUser.properties forKey:@"properties"];
    [myselfDict setValue:[YSRoomInterface instance].localUser.peerID forKey:@"id"];
    
    [dict setValue:myselfDict forKey:@"myself"];
    //信令排序
    BOOL show = NO;
    NSDictionary *msgList = [dict objectForKey:@"msglist"];
    NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:@"seq" ascending:YES];
    NSArray *msgArray = [[msgList allValues] sortedArrayUsingDescriptors:@[ desc ]];
    
    NSMutableArray *newMsgArray = [[NSMutableArray alloc] init];
    NSMutableArray *showMsgArray = [[NSMutableArray alloc] init];
//    sYSSignalShowPage
//    sYSSignalVideoWhiteboard
//    sYSSignalSharpsChange
//    sYSSignalMoreWhiteboardState
//    sYSSignalMoreWhiteboardGlobalState
    
    NSUInteger index = 0;
    for (NSUInteger msgIndex =0; msgIndex<msgArray.count; msgIndex++)
    {
        NSDictionary *msgDic = msgArray[msgIndex];
        NSString *msgName = [msgDic bm_stringForKey:@"name"];
        if ([msgName isEqualToString:sYSSignalShowPage] || [msgName isEqualToString:sYSSignalExtendShowPage])
        {
            [showMsgArray addObject:msgDic];
            if (!index)
            {
                index = msgIndex;
            }
        }
        else if ([msgName isEqualToString:sYSSignalVideoWhiteboard] || [msgName isEqualToString:sYSSignalSharpsChange] || [msgName isEqualToString:sYSSignalMoreWhiteboardState] || [msgName isEqualToString:sYSSignalMoreWhiteboardGlobalState])
        {
            [newMsgArray addObject:msgDic];
            
            if (!index)
            {
                index = msgIndex;
            }
        }
        else
        {
            [newMsgArray addObject:msgDic];
        }
    }
    
    if (index && [showMsgArray bm_isNotEmpty])
    {
        [newMsgArray bm_insertArray:showMsgArray atIndex:index];
    }
    
    for (NSDictionary *msgDic in newMsgArray)
    {
        [self roomWhiteBoardOnRemotePubMsgWithMessage:msgDic inList:YES];
        
        // 历史msgList如果有ShowPage信令，需要主动发给H5去刷新当前课件
        if ([[msgDic objectForKey:@"name"] isEqualToString:sYSSignalShowPage] || [[msgDic objectForKey:@"name"] isEqualToString:sYSSignalExtendShowPage])
        {
            show = YES;
            NSDictionary *filedata = [msgDic bm_dictionaryForKey:@"filedata"];
            if (!filedata)
            {
                id dataObject = [msgDic objectForKey:@"data"];
                NSDictionary *dataDic = [YSRoomUtil convertWithData:dataObject];
                filedata = [dataDic bm_dictionaryForKey:@"filedata"];
            }
            NSString *fileid = [filedata bm_stringForKey:@"fileid"];
            if (!fileid)
            {
                fileid = @"0";
            }
            [self setTheCurrentDocumentFileID:fileid];
        }
    }
    
    if (!show && !self.isBeginClass)
    {
        [self changeCourseWithFileId:self.currentFileId toID:[YSRoomInterface instance].localUser.peerID save:NO];
    }
}

// 断开链接的通知
- (void)roomWhiteBoardOnDisconnect:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    NSString *reason = [dict objectForKey:YSWhiteBoardNotificationUserInfoKey];
    
    [self disconnect:reason];
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

// 回放下消息列表
 - (void)roomWhiteBoardOnMsgList:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    NSArray *dicArray = [dict bm_arrayForKey:YSWhiteBoardNotificationUserInfoKey];

    for (NSDictionary *dic in dicArray)
    {
        if (dic && [dic isKindOfClass:NSDictionary.class])
        {
            [self roomWhiteBoardOnRemotePubMsgWithMessage:dic inList:YES];
        }
    }
}

// 教室消息列表的通知
//- (void)roomWhiteBoardOnRemoteMsgList:(NSNotification *)notification
//{
//}

// 大并发房间用户上台通知
- (void)roomWhiteBoardOnBigRoomUserPublished:(NSNotification *)notification
{
//    NSDictionary *dict = notification.userInfo;
//    NSDictionary *message = [dict objectForKey:YSWhiteBoardNotificationUserInfoKey];
}

// 用户属性改变通知
- (void)roomWhiteBoardOnRoomUserPropertyChanged:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    NSDictionary *message = [dict bm_dictionaryForKey:YSWhiteBoardNotificationUserInfoKey];
    
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
    // 用户属性改变通知，只接收自己的candraw属性，PrimaryColor画笔颜色属性
    if (![properties bm_containsObjectForKey:sYSUserCandraw] && ![properties bm_containsObjectForKey:sYSUserPrimaryColor])
    {
        return;
    }

    if ([properties bm_containsObjectForKey:sYSUserPrimaryColor])
    {
        NSString *colorHex = [properties bm_stringForKey:sYSUserPrimaryColor];
        [self.brushToolsManager changePrimaryColorHex:colorHex];
    }

    if (self.mainWhiteBoardView)
    {
        [self.mainWhiteBoardView userPropertyChanged:message];
    }
    
    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        [whiteBoardView userPropertyChanged:message];
    }
}

#if 0
- (void)roomWhiteBoardOnRoomParticipantLeaved:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    NSDictionary *message = [dict objectForKey:YSWhiteBoardNotificationUserInfoKey];
    
    if (self.mainWhiteBoardView)
    {
        [self.mainWhiteBoardView participantLeaved:message];
    }
    
    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        [whiteBoardView participantLeaved:message];
    }
}

- (void)roomWhiteBoardOnRoomParticipantJoin:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    NSDictionary *message = [dict objectForKey:YSWhiteBoardNotificationUserInfoKey];
    
    if (self.mainWhiteBoardView)
    {
        [self.mainWhiteBoardView participantJoin:message];
    }
    
    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        [whiteBoardView participantJoin:message];
    }
}

- (void)roomWhiteBoardOnParticipantEvicted:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    NSDictionary *reason = [dict objectForKey:YSWhiteBoardNotificationUserInfoKey];
    
    if (self.mainWhiteBoardView)
    {
        [self.mainWhiteBoardView participantEvicted:reason];
    }
    
    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        [whiteBoardView participantEvicted:reason];
    }
}
#endif

- (void)roomWhiteBoardOnRemotePubMsg:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    NSDictionary *message = [dict objectForKey:YSWhiteBoardNotificationUserInfoKey];
    
    if (![message bm_isNotEmptyDictionary])
    {
        return;
    }
    
    [self roomWhiteBoardOnRemotePubMsgWithMessage:message inList:NO];
}

- (void)roomWhiteBoardOnRemotePubMsgWithMessage:(NSDictionary *)message inList:(BOOL)inlist
{
    if (![message bm_isNotEmptyDictionary])
    {
        return;
    }
    
    NSString *msgName = [message bm_stringForKey:@"name"];
    if (![msgName bm_isNotEmpty])
    {
        return;
    }
    NSString *msgId = [message bm_stringForKey:@"id"];
    if (![msgId bm_isNotEmpty])
    {
        return;
    }

    if (![msgName isEqualToString:sYSSignalUpdateTime])
    {
        WB_INFO(@"%s %@", __func__, message);
    }
    
    // 不处理大房间, 时间
    if ([msgName isEqualToString:sYSSignalNotice_BigRoom_Usernum] || [msgName isEqualToString:sYSSignalUpdateTime])
    {
        return;
    }

    if ([msgName isEqualToString:sYSSignalClassBegin])
    {
        self.isBeginClass = YES;
        self.beginClassMessage = message;
        
        if ([self isOneWhiteBoardView])
        {
            if (!inlist)
            {
                if ([[YSWhiteBoardManager shareInstance] isCanControlWhiteBoardView])
                {
                    [self changeCourseWithFileId:self.currentFileId];
                }
            }
        }
        else
        {
            if (!inlist)
            {
                if ([[YSWhiteBoardManager shareInstance] isCanControlWhiteBoardView])
                {
                    [self makeCurrentWhiteBoardViewPointReset:YES];
                    
                    NSArray *arrangeList = [self getWhiteBoardViewIdArrangeList];
                    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
                    {
                        // 上课不发送音视频流
                        if (whiteBoardView == self.mp3WhiteBoardView || whiteBoardView == self.mp4WhiteBoardView)
                        {
                            continue;
                        }
                        
                        [self changeCourseWithFileId:whiteBoardView.fileId];
                        
                        NSString *msgID = [NSString stringWithFormat:@"MoreWhiteboardState_%@", whiteBoardView.whiteBoardId];
                        NSString *associatedMsgID = [NSString stringWithFormat:@"DocumentFilePage_ExtendShowPage_%@", whiteBoardView.whiteBoardId];
                        
                        [YSRoomUtil pubWhiteBoardMsg:sYSSignalMoreWhiteboardState msgID:msgID data:whiteBoardView.positionData extensionData:nil associatedMsgID:associatedMsgID expires:0 completion:nil];
                    }
                    
                    if (self.mediaFileModel)
                    {
                        // 上课关闭所有音视频流，关闭窗口后会发送层级
                        [[YSRoomInterface instance] stopShareMediaFile:nil];
                    }
                    else
                    {
                        [self sendArrangeWhiteBoardViewWithArrangeList:arrangeList];
                    }
                }
                else
                {
                    [self removeAllWhiteBoardView];
                }
            }
        }
    }
    
    long ts = (long)[message bm_uintForKey:@"ts"];
    NSString *fromId = [message objectForKey:@"fromID"];
    NSObject *data = [message objectForKey:@"data"];
    
    //NSString *fromId11 = [YSRoomInterface instance].localUser.peerID;
    
//    if (self.wbDelegate && [self.wbDelegate respondsToSelector:@selector(onWhiteBroadPubMsgWithMsgID:msgName:data:fromID:inList:ts:)])
//    {
//        [self.wbDelegate onWhiteBroadPubMsgWithMsgID:msgId msgName:msgName data:data fromID:fromId inList:inlist ts:ts];
//    }
    
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
            NSString *fileId = [tDataDic bm_stringForKey:@"fileid"];
            if (!fileId)
            {
                NSDictionary *filedata = [tDataDic bm_dictionaryForKey:@"filedata"];
                fileId = [filedata bm_stringForKey:@"fileid"];
                if (![fileId bm_isNotEmpty])
                {
                    return;
                }
            }

            [self deleteDocumentWithFileID:fileId];
        }
        else
        {
            [self addOrReplaceDocumentFile:tDataDic];
        }
    }
    else if ([msgName isEqualToString:sYSSignalShowPage] || [msgName isEqualToString:sYSSignalExtendShowPage])
    {
        NSString *fileId = [tDataDic bm_stringForKey:@"fileid"];
        if (!fileId)
        {
            NSDictionary *filedata = [tDataDic bm_dictionaryForKey:@"filedata"];
            fileId = [filedata bm_stringForKey:@"fileid"];
            if (![fileId bm_isNotEmpty])
            {
                return;
            }
        }
        
        // 后台关联课件是发送showpage信令，多课件时不响应
        if (![self isOneWhiteBoardView] && [msgName isEqualToString:sYSSignalShowPage] && ![fileId isEqualToString:@"0"])
        {
            return;
        }
       
        [self.docmentList enumerateObjectsUsingBlock:^(YSFileModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([fileId isEqualToString:obj.fileid])
            {
                NSDictionary *filedata = [tDataDic bm_dictionaryForKey:@"filedata"];
                obj.currpage = [filedata bm_uintForKey:@"currpage"];
            }
        }];
        [self addOrReplaceDocumentFile:tDataDic];
        
        YSWhiteBoardView *whiteBoardView = nil;
        if ([msgName isEqualToString:sYSSignalShowPage])
        {
            if (self.mainWhiteBoardView)
            {
                [self.mainWhiteBoardView changeFileId:fileId];
                whiteBoardView = self.mainWhiteBoardView;
                
                [self setTheCurrentDocumentFileID:fileId];

                [self.mainWhiteBoardView remotePubMsg:message];
                
//                for (NSDictionary *dictionary in self.sharpChangeArray)
//                {
//                    NSString *ID     = [dictionary objectForKey:@"id"];
//                    NSString *pageID = [ID componentsSeparatedByString:@"_"].lastObject;
//                    NSString *tempFileID = [[ID componentsSeparatedByString:@"_"]
//                        objectAtIndex:[ID componentsSeparatedByString:@"_"].count - 2];
//
//                    NSDictionary *filedata = [tDataDic bm_dictionaryForKey:@"filedata"];
//                    NSInteger currpage = [filedata bm_uintForKey:@"currpage"];
//                    if ([fileId isEqualToString:tempFileID] && pageID.integerValue == currpage)
//                    {
//                        [self.mainWhiteBoardView remotePubMsg:dictionary];
//                    }
//                }
                
                if (self.wbDelegate && [self.wbDelegate respondsToSelector:@selector(onWhiteBoardChangedFileWithFileList:)])
                {
                    NSMutableArray *fileList = [[NSMutableArray alloc] init];
                    [fileList addObject:self.mainWhiteBoardView.fileId];
                    [self.wbDelegate onWhiteBoardChangedFileWithFileList:fileList];
                }
                return;
            }
        }
        else
        {
            whiteBoardView = [self getWhiteBoardViewWithFileId:fileId];
            if (!whiteBoardView)
            {
                BOOL mineCreat = [fromId isEqualToString:[YSRoomInterface instance].localUser.peerID];
                
                if (inlist)
                {
                    mineCreat = NO;
                }
                
                whiteBoardView = [self createWhiteBoardWithFileId:fileId isFromLocalUser:mineCreat loadFinishedBlock:nil];
                //whiteBoardView.backgroundColor = [UIColor bm_randomColor];
                [self.mainWhiteBoardView addSubview:whiteBoardView];
                whiteBoardView.topBar.delegate = self;
                [self addWhiteBoardViewWithWhiteBoardView:whiteBoardView];
                
                if ([self.defaultFileId isEqualToString:fileId] && [self isCanControlWhiteBoardView])
                {
                    // 默认课件最大化
                    NSString *whiteBoardId = [YSRoomUtil getwhiteboardIDFromFileId:self.defaultFileId];
                    NSString *msgID = [NSString stringWithFormat:@"MoreWhiteboardState_%@", whiteBoardId];
                    
                    CGFloat scaleLeft = whiteBoardViewCurrentLeft / (self.mainWhiteBoardView.bm_width - self.whiteBoardViewDefaultSize.width);
                    CGFloat scaleTop = whiteBoardViewCurrentTop / (self.mainWhiteBoardView.bm_height - self.whiteBoardViewDefaultSize.height);
                    CGFloat scaleWidth = self.whiteBoardViewDefaultSize.width / self.mainWhiteBoardView.bm_width;
                    CGFloat scaleHeight = self.whiteBoardViewDefaultSize.height / self.mainWhiteBoardView.bm_height;
                    
                    NSDictionary * data = @{@"x":@(scaleLeft),@"y":@(scaleTop),@"width":@(scaleWidth),@"height":@(scaleHeight),@"small":@NO,@"full":@YES,@"type":@"full",@"instanceId":whiteBoardId};
                    NSString *associatedMsgID = [NSString stringWithFormat:@"DocumentFilePage_ExtendShowPage_%@", whiteBoardId];
                    
                    [YSRoomUtil pubWhiteBoardMsg:sYSSignalMoreWhiteboardState msgID:msgID data:data extensionData:nil associatedMsgID:associatedMsgID expires:0 completion:nil];
                }
                self.defaultFileId = nil;
            }
        }
        
        [self setTheCurrentDocumentFileID:fileId];
        [whiteBoardView remotePubMsg:message];
        
        return;
    }
    /// 白板视频标注
    else if ([msgName isEqualToString:sYSSignalVideoWhiteboard])
    {
        if ([self isOneWhiteBoardView])
        {
            return;
        }
        if (![tDataDic bm_isNotEmptyDictionary])
        {
            return;
        }
        
        CGFloat videoRatio = [tDataDic bm_doubleForKey:@"videoRatio"];
        [self.mp4WhiteBoardView showVideoWhiteboardWithData:tDataDic videoRatio:videoRatio];

        return;
    }
    else if ([msgName isEqualToString:sYSSignalSharpsChange])
    {
        if ([tDataDic bm_isNotEmptyDictionary])
        {
            /// 白板视频标注数据
            NSString *whiteboardID = [tDataDic bm_stringTrimForKey:@"whiteboardID"];
            if ([whiteboardID isEqualToString:YSVideoWhiteboard_Id])
            {
                if ([self isOneWhiteBoardView])
                {
                    return;
                }
                
                [self.mp4WhiteBoardView drawVideoWhiteboardWithData:tDataDic inList:inlist];
                
                return;
            }
        }
        
        if ([self isOneWhiteBoardView])
        {
            [self.mainWhiteBoardView remotePubMsg:message];
        }
        else
        {
            if ([msgId containsString:@"###_SharpsChange"])
            {
                // 保存画笔数据
                [self.sharpChangeArray addObject:message];
                
                NSArray *components = [msgId componentsSeparatedByString:@"_"];
                if (components.count > 2)
                {
                    //NSString *currentPage = components.lastObject;
                    NSString *fileId = [components objectAtIndex:components.count - 2];
                    YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithFileId:fileId];
                    if (whiteBoardView)
                    {
                        [whiteBoardView remotePubMsg:message];
                    }
                }
            }
        }
        return;
    }
    // 白板加页
    else if ([msgName isEqualToString:sYSSignalWBPageCount])
    {
        if (self.mainWhiteBoardView)
        {
            [self.mainWhiteBoardView remotePubMsg:message];
        }
        
        return;
    }
    else if ([msgName isEqualToString:sYSSignalH5DocumentAction] || [msgName isEqualToString:sYSSignalNewPptTriggerActionClick])
    {
        NSString *fileId = [tDataDic bm_stringForKey:@"fileid"];
        if (!fileId)
        {
            NSString *sourceInstanceId = [tDataDic bm_stringForKey:@"sourceInstanceId"];
            if (sourceInstanceId)
            {
                fileId = [YSRoomUtil getFileIdFromSourceInstanceId:sourceInstanceId];
            }
        }
        
        if (fileId)
        {
            if ([fileId isEqualToString:YSDefaultWhiteBoardId])
            {
                 if (self.mainWhiteBoardView)
                {
                    [self.mainWhiteBoardView remotePubMsg:message];
                }
            }
            else
            {
                YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithFileId:fileId];
                if (whiteBoardView)
                {
                    [whiteBoardView remotePubMsg:message];
                }
            }
        }
        
        return;
    }
    // 小白板上的UI信令
    else if ([msgName isEqualToString:sYSSignalMoreWhiteboardState])
    {
        [self receiveMessageToMoveAndZoomWith:tDataDic WithInlist:inlist];
        return;
    }
    // 窗口布局
    else if ([msgName isEqualToString:sYSSignalMoreWhiteboardGlobalState])
    {
        if ([fromId isEqualToString:[YSRoomInterface instance].localUser.peerID])
        {
            return;
        }
        
        NSString *type = [tDataDic bm_stringForKey:@"type"];
        // 窗口排序
        if ([type isEqualToString:@"sort"])
        {
            NSArray *sort = [tDataDic bm_arrayForKey:@"sort"];
            
            NSString *instanceId = [tDataDic bm_stringForKey:@"instanceId"];
            NSString *currentFileId = [YSRoomUtil getFileIdFromSourceInstanceId:instanceId];
            if ([currentFileId bm_isNotEmpty])
            {
                [self setTheCurrentDocumentFileID:currentFileId sendArrange:NO];
            }
            
            for (NSString *whiteBoardId in sort)
            {
                YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithWhiteBoardId:whiteBoardId];
                if (whiteBoardView)
                {
                    [whiteBoardView bm_bringToFront];
                }
            }
        }
        // 全部显示隐藏
        else if ([type isEqualToString:@"visibleToggle"])
        {
            
        }
        
        return;
    }
    
    if (self.mainWhiteBoardView)
    {
        [self.mainWhiteBoardView remotePubMsg:message];
    }

    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        [whiteBoardView remotePubMsg:message];
    }
}

- (void)roomWhiteBoardOnRemoteDelMsg:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    NSDictionary *message = [dict objectForKey:YSWhiteBoardNotificationUserInfoKey];
    
    NSString *msgName = [message bm_stringForKey:@"name"];
    if (![msgName bm_isNotEmpty])
    {
        return;
    }
    NSString *msgId = [message bm_stringForKey:@"id"];
    if (![msgId bm_isNotEmpty])
    {
        return;
    }

    if ([msgName isEqualToString:sYSSignalExtendShowPage])
    {
        NSString *messageId = [message objectForKey:@"id"];
        
        NSString *fileId = nil;
                
        NSString *messageIdHead = @"DocumentFilePage_ExtendShowPage_docModule_";
        
        if (messageId.length > messageIdHead.length)
        {
            fileId = [messageId substringFromIndex:messageIdHead.length];
        }
        
        if (![fileId bm_isNotEmpty])
        {
            return;
        }

        [self removeWhiteBoardViewWithFileId:fileId];
        
        return;
    }
    /// 白板视频标注
    else if ([msgName isEqualToString:sYSSignalVideoWhiteboard])
    {
        if ([self isOneWhiteBoardView])
        {
            return;
        }
        [self.mp4WhiteBoardView hideVideoWhiteboard];

        return;
    }

    if (![msgName isEqualToString:sYSSignalClassBegin] && ![msgName isEqualToString:sYSSignalSharpsChange])
    {
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

// 媒体流发布状态
- (void)roomWhiteBoardOnShareMediaState:(NSNotification *)notification
{
    if ([self isOneWhiteBoardView])
    {
        return;
    }
    
    NSDictionary *message = notification.userInfo;
    
    NSString *peerID = [message bm_stringForKey:YSWhiteBoardOnShareMediaStateExtensionIdKey];
    YSMediaState mediaState = [message bm_intForKey:YSWhiteBoardOnShareMediaStateKey];
    NSDictionary *mediaDic = [message bm_dictionaryForKey:YSWhiteBoardOnShareMediaStateExtensionMsgKey];

    if (![peerID bm_isNotEmpty])
    {
        return;
    }

    self.mediaFileSenderPeerId = peerID;
    
    if (mediaState == YSMedia_Pulished)
    {
        YSMediaFileModel *mediaFileModel = [YSMediaFileModel mediaFileModelWithDic:mediaDic];
        if (!mediaFileModel)
        {
            return;
        }
        
        self.mediaFileModel = mediaFileModel;
        
        [self handlePlayMediaFile];
    }
    else
    {
        [self handleStopMediaFile];
    }
}

// 更新媒体流的信息
- (void)roomWhiteBoardOnUpdateMediaStream:(NSNotification *)notification
{
    if ([self isOneWhiteBoardView])
    {
        return;
    }
    
    NSDictionary *message = notification.userInfo;
    
    NSTimeInterval duration = [message bm_doubleForKey:YSWhiteBoardUpadteMediaStreamDurationKey];
    NSTimeInterval pos = [message bm_doubleForKey:YSWhiteBoardUpadteMediaStreamPositionKey];
    BOOL isPlay = [message bm_boolForKey:YSWhiteBoardUpadteMediaStreamPlayingKey];
    if (isPlay)
    {
        [self.mp4WhiteBoardView hideVideoWhiteboard];
    }
    [self onRoomUpdateMediaStream:duration pos:pos isPlay:isPlay];
}

- (void)handlePlayMediaFile
{
    BOOL mineCreat = [self.mediaFileSenderPeerId isEqualToString:[YSRoomInterface instance].localUser.peerID];
    
    if (self.mediaFileModel.isVideo)
    {
        YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithFileId:self.mediaFileModel.fileid];
        if (whiteBoardView)
        {
            self.mp4WhiteBoardView = whiteBoardView;
            self.mp4WhiteBoardView.isH5LoadMedia = YES;
        }
        else
        {
            self.mp4WhiteBoardView = [self createMp4WhiteBoardWithFileId:self.mediaFileModel.fileid isFromLocalUser:mineCreat loadFinishedBlock:nil];
            self.mp4WhiteBoardView.topBar.delegate = self;
            [self addWhiteBoardViewWithWhiteBoardView:self.mp4WhiteBoardView];
        }

        BMWeakSelf
        [[YSRoomInterface instance] playMediaFile:self.mediaFileSenderPeerId renderType:YSRenderMode_fit window:self.mp4WhiteBoardView.whiteBoardContentView completion:^(NSError *error) {
            [weakSelf.mp4WhiteBoardView setMediaStream:0 pos:0 isPlay:NO fileName:self.mediaFileModel.filename];
        }];
    }
    else if (self.mediaFileModel.isAudio)
    {
        self.mp3WhiteBoardView = [self createMp3WhiteBoardWithFileId:self.mediaFileModel.fileid isFromLocalUser:NO loadFinishedBlock:nil];
        [self addWhiteBoardViewWithWhiteBoardView:self.mp3WhiteBoardView];
        
        BMWeakSelf
        [[YSRoomInterface instance] playMediaFile:self.mediaFileSenderPeerId renderType:YSRenderMode_fit window:self.mp3WhiteBoardView.whiteBoardContentView completion:^(NSError *error) {
            [weakSelf.mp3WhiteBoardView setMediaStream:0 pos:0 isPlay:YES fileName:self.mediaFileModel.filename];
        }];
    }
    
    if (self.wbDelegate && [self.wbDelegate respondsToSelector:@selector(onWhiteBoardChangedMediaFileStateWithFileId:state:)])
    {
        [self.wbDelegate onWhiteBoardChangedMediaFileStateWithFileId:self.mediaFileModel.fileid state:YSWhiteBordMediaState_Play];
    }
}

- (void)handleStopMediaFile
{
    [[YSRoomInterface instance] unPlayMediaFile:self.mediaFileSenderPeerId completion:^(NSError *error) {
    }];

    if (self.mediaFileModel.isVideo)
    {
        [self.mp4WhiteBoardView hideVideoWhiteboard];

        if (self.mp4WhiteBoardView.isH5LoadMedia)
        {
            self.mp4WhiteBoardView.isH5LoadMedia = NO;
        }
        else
        {
            [self removeWhiteBoardViewWithWhiteBoardView:self.mp4WhiteBoardView];
        }
        self.mp4WhiteBoardView = nil;
        
        if (self.isBeginClass && [YSRoomInterface instance].localUser.role == YSUserType_Teacher)
        {
            [self clearVideoMark];
            [YSRoomUtil delWhiteBoardMsg:sYSSignalVideoWhiteboard msgID:sYSSignalVideoWhiteboard data:nil completion:nil];
        }
    }
    else if (self.mediaFileModel.isAudio)
    {
        [self removeWhiteBoardViewWithWhiteBoardView:self.mp3WhiteBoardView];
        self.mp3WhiteBoardView = nil;
    }
    
    if (self.wbDelegate && [self.wbDelegate respondsToSelector:@selector(onWhiteBoardChangedMediaFileStateWithFileId:state:)])
    {
        [self.wbDelegate onWhiteBoardChangedMediaFileStateWithFileId:self.mediaFileModel.fileid state:YSWhiteBordMediaState_Stop];
    }
    
    self.mediaFileModel = nil;
    self.mediaFileSenderPeerId = nil;
}

- (void)onRoomUpdateMediaStream:(NSTimeInterval)duration pos:(NSTimeInterval)pos isPlay:(BOOL)isPlay
{
    if ([[YSWhiteBoardManager shareInstance] isCanControlWhiteBoardView])
    {
        if (pos >= duration)
        {
            [[YSRoomInterface instance] stopShareMediaFile:nil];
            self.isMediaDrag = NO;
            return;
        }
    }
    
    if (!self.isMediaDrag)
    {
        if (isPlay)
        {
            [self continueMediaStream:duration pos:pos];
        }
        else
        {
            [self pauseMediaStream:duration pos:pos];
        }
    }
    self.isMediaDrag = NO;
}

- (void)pauseMediaStream:(NSTimeInterval)duration pos:(NSTimeInterval)pos
{
    self.mediaFileModel.isPause = YES;
    if (self.mediaFileModel.isVideo)
    {
        [self.mp4WhiteBoardView setMediaStream:duration pos:pos isPlay:NO fileName:self.mediaFileModel.filename];
    }
    else if (self.mediaFileModel.isAudio)
    {
        [self.mp3WhiteBoardView setMediaStream:duration pos:pos isPlay:NO fileName:self.mediaFileModel.filename];
    }
    
    if (self.wbDelegate && [self.wbDelegate respondsToSelector:@selector(onWhiteBoardChangedMediaFileStateWithFileId:state:)])
    {
        [self.wbDelegate onWhiteBoardChangedMediaFileStateWithFileId:self.mediaFileModel.fileid state:YSWhiteBordMediaState_Pause];
    }
}

- (void)continueMediaStream:(NSTimeInterval)duration pos:(NSTimeInterval)pos
{
    self.mediaFileModel.isPause = NO;
    if (self.mediaFileModel.isVideo)
    {
        [self.mp4WhiteBoardView setMediaStream:duration pos:pos isPlay:YES fileName:self.mediaFileModel.filename];
    }
    else if (self.mediaFileModel.isAudio)
    {
        [self.mp3WhiteBoardView setMediaStream:duration pos:pos isPlay:YES fileName:self.mediaFileModel.filename];
    }
    
    if (self.wbDelegate && [self.wbDelegate respondsToSelector:@selector(onWhiteBoardChangedMediaFileStateWithFileId:state:)])
    {
        [self.wbDelegate onWhiteBoardChangedMediaFileStateWithFileId:self.mediaFileModel.fileid state:YSWhiteBordMediaState_Play];
    }
}

/// 发送信令清除白板视频标注
- (void)clearVideoMark
{
    if (!self.isBeginClass)
    {
        return;
    }
    
    YSRoomUser *localUser = [YSRoomInterface instance].localUser;
    if (localUser.role != YSUserType_Teacher)
    {
        return;
    }

    NSString *whiteboardID = YSVideoWhiteboard_Id;

    NSString *key = [NSString stringWithFormat:@"clear_%f", [NSDate date].timeIntervalSince1970];
    NSDictionary *dic = @{@"eventType" : @"clearEvent", @"actionName" : @"ClearAction", @"clearActionId" : key, @"whiteboardID" : whiteboardID, @"isBaseboard" : @(false), @"nickname" : @"iOS"};
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&error];
    if (error)
    {
        return;
    }
    NSString *shapeID = [NSString stringWithFormat:@"%@###_SharpsChange_%@_%@", key, YSVideoWhiteboard_Id, @"1"];
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *associatedMsgID = @"VideoWhiteboard";//[NSString stringWithFormat:@"%@%@", sYSSignalDocumentFilePage_ExtendShowPage, whiteboardID];
    [[YSRoomInterface instance] pubMsg:sYSSignalSharpsChange msgID:shapeID toID:YSRoomPubMsgTellAll data:dataString save:YES extensionData:@{} associatedMsgID:associatedMsgID associatedUserID:nil expires:0 completion:^(NSError *error) {
    }];
}


#pragma mark -YSWBMediaControlviewDelegate

- (void)mediaControlviewPlay:(BOOL)isPlay
{
    [[YSRoomInterface instance] pauseMediaFile:isPlay];
    if (self.mediaFileModel.isVideo)
    {
        if (self.isBeginClass)
        {
            if (isPlay)
            {
                [YSRoomUtil pubWhiteBoardMsg:sYSSignalVideoWhiteboard msgID:sYSSignalVideoWhiteboard data:@{@"videoRatio":@(self.mediaFileModel.width/self.mediaFileModel.height)} extensionData:nil associatedMsgID:@"" expires:0 completion:nil];
            }
            else
            {
                [self clearVideoMark];
                [YSRoomUtil delWhiteBoardMsg:sYSSignalVideoWhiteboard msgID:sYSSignalVideoWhiteboard data:nil completion:nil];
            }
        }
    }
}

- (void)mediaControlviewSlider:(NSTimeInterval)value
{
    self.isMediaDrag = YES;
    [[YSRoomInterface instance] seekMediaFile:value];
    if (self.mediaFileModel.isVideo)
     {
         if (self.isBeginClass)
         {
             [self clearVideoMark];
             [YSRoomUtil delWhiteBoardMsg:sYSSignalVideoWhiteboard msgID:sYSSignalVideoWhiteboard data:nil completion:nil];
         }
     }
}

- (void)mediaControlviewClose
{
    [[YSRoomInterface instance] stopShareMediaFile:nil];
}


#pragma -
#pragma mark YSWhiteBoardViewDelegate

/// H5脚本文件加载初始化完成
- (void)onWBViewWebViewManagerPageFinshed:(YSWhiteBoardView *)whiteBoardView
{
    if (self.wbDelegate && [self.wbDelegate respondsToSelector:@selector(onWhiteBoardPageFinshed:)])
    {
        [self.wbDelegate onWhiteBoardPageFinshed:whiteBoardView.fileId];
    }
}

/// 切换Web课件加载状态
- (void)onWBViewWebViewManagerLoadedState:(YSWhiteBoardView *)whiteBoardView withState:(NSDictionary *)dic
{
    if (self.wbDelegate && [self.wbDelegate respondsToSelector:@selector(onWhiteBoardLoadedState:withState:)])
    {
        [self.wbDelegate onWhiteBoardLoadedState:whiteBoardView.fileId withState:dic];
    }
}

/// Web课件翻页结果
- (void)onWBViewWebViewManagerStateUpdate:(YSWhiteBoardView *)whiteBoardView withState:(NSDictionary *)dic
{
    if (self.wbDelegate && [self.wbDelegate respondsToSelector:@selector(onWhiteBoardStateUpdate:withState:)])
    {
        [self.wbDelegate onWhiteBoardStateUpdate:whiteBoardView.fileId withState:dic];
    }
}

/// 翻页超时
- (void)onWBViewWebViewManagerSlideLoadTimeout:(YSWhiteBoardView *)whiteBoardView withState:(NSDictionary *)dic
{
    if (self.wbDelegate && [self.wbDelegate respondsToSelector:@selector(onWhiteBoardSlideLoadTimeout:withState:)])
    {
        [self.wbDelegate onWhiteBoardSlideLoadTimeout:whiteBoardView.fileId withState:dic];
    }
}

/// 课件缩放
- (void)onWWBViewDrawViewManagerZoomScaleChanged:(YSWhiteBoardView *)whiteBoardView zoomScale:(CGFloat)zoomScale
{
    if (self.wbDelegate && [self.wbDelegate respondsToSelector:@selector(onWhiteBoardZoomScaleChanged:zoomScale:)])
    {
        [self.wbDelegate onWhiteBoardZoomScaleChanged:whiteBoardView.fileId zoomScale:zoomScale];
    }
}

/// 课件全屏
- (void)onWBViewFullScreen:(BOOL)isAllScreen wbView:(YSWhiteBoardView *)whiteBoardView
{
    if (self.wbDelegate && [self.wbDelegate respondsToSelector:@selector(onWhiteBoardFullScreen:)])
    {
        [self.wbDelegate onWhiteBoardFullScreen:isAllScreen];
    }
}

/// 拖拽Mp3手势事件  本地操作
- (void)moveMp3ViewWithGestureRecognizer:(UIPanGestureRecognizer *)panGesture
{
    UIView *panView = panGesture.view;

    //1、获得拖动位移
    CGPoint offsetPoint = [panGesture translationInView:panView];
    //2、清空拖动位移
    [panGesture setTranslation:CGPointZero inView:panView];
    //3、重新设置控件位置
    CGFloat newX = panView.bm_centerX+offsetPoint.x;
    CGFloat newY = panView.bm_centerY+offsetPoint.y;

    if ([YSRoomInterface instance].localUser.role == YSUserType_Teacher)
    {
        CGFloat viewWidth = panView.bm_width;
        CGFloat viewHeight = panView.bm_height;
        
        if (newX < 1 + viewWidth/2)
        {
            newX = 1 + viewWidth/2 ;
        }
        else if (newX > self.mainWhiteBoardView.bm_width - viewWidth/2 - 1)
        {
            newX = self.mainWhiteBoardView.bm_width - viewWidth/2 - 1;
        }
        
        if (newY <= 1 + viewHeight/2)
        {
            newY = 1 + viewHeight/2;
        }
        else if (newY > self.mainWhiteBoardView.bm_height - viewHeight/2 - 1)
        {
            newY = self.mainWhiteBoardView.bm_height - viewHeight/2 - 1;
        }
    }
    else
    {
       CGFloat viewWidth = panView.bm_width;
        
        if (newX < 1 + viewWidth/2)
        {
            newX = 1 + viewWidth/2 ;
        }
        else if (newX > self.mainWhiteBoardView.bm_width - viewWidth/2 - 1)
        {
            newX = self.mainWhiteBoardView.bm_width - viewWidth/2 - 1;
        }
        
        if (newY <= 1 + viewWidth/2)
        {
            newY = 1 + viewWidth/2;
        }
        else if (newY > self.mainWhiteBoardView.bm_height - viewWidth/2 - 1)
        {
            newY = self.mainWhiteBoardView.bm_height - viewWidth/2 - 1;
        }
    }
        
    CGPoint centerPoint = CGPointMake(newX, newY);
    panView.center = centerPoint;
}

@end
