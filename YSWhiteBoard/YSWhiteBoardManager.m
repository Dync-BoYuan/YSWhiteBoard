//
//  YSWhiteBoardManager.m
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/22.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import "YSWhiteBoardManager.h"
#import "YSFileModel.h"
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

// 消息列表
//@property (nonatomic, strong) NSMutableArray <NSDictionary *> *msgList;


/// 记录UI层是否开始上课
@property (nonatomic, assign) BOOL isBeginClass;
@property (nonatomic, strong) NSDictionary *beginClassMessage;

/// 课件列表
@property (nonatomic, strong) NSMutableArray <YSFileModel *> *docmentList;
/// 课件Dic列表
@property (nonatomic, strong) NSMutableArray <NSDictionary *> *docmentDicList;

/// 当前激活文档id
@property (nonatomic, strong, setter=setTheCurrentDocumentFileID:) NSString *currentFileId;

// UI

@property (nonatomic, assign) CGSize whiteBoardViewDefaultSize;

/// 主白板
@property (nonatomic, strong) YSWhiteBoardView *mainWhiteBoardView;
/// 预加载课件
@property (nonatomic, strong) YSWhiteBoardView *preLoadWhiteBoardView;
/// 课件窗口列表
@property (nonatomic, strong) NSMutableArray <YSWhiteBoardView *> *coursewareViewList;

// 画笔控制
@property (nonatomic, strong) YSBrushToolsManager *brushToolsManager;



///拖出视频view时的模拟移动图
@property (nonatomic, strong) UIImageView *dragImageView;

///小白板是否正在拖动
@property (nonatomic, assign) BOOL isDraging;

///小白板是否正在拖动缩放
@property (nonatomic, assign) BOOL isDragZooming;


@end

@implementation YSWhiteBoardManager

#pragma mark - dealloc

- (void)dealloc
{
    [self clearAllData];
}

- (void)clearAllData
{
    [self.mainWhiteBoardView destroy];
    
    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        [whiteBoardView destroy];
    }
    [self.coursewareViewList removeAllObjects];
    self.coursewareViewList = nil;

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
        //[whiteBoardManagerSingleton registerURLProtocol:NO];
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
            [whiteBoardManagerSingleton registerURLProtocol:YES];
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
        
        self.brushToolsManager = [YSBrushToolsManager shareInstance];
        
        whiteBoardViewCurrentLeft = YSWhiteBoardDefaultLeft;
        whiteBoardViewCurrentTop = YSWhiteBoardDefaultTop;

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

- (void)registerDelegate:(id <YSWhiteBoardManagerDelegate>)delegate configration:(NSDictionary *)config
{
    self.wbDelegate = delegate;
    self.configration = config;
}

- (YSWhiteBoardView *)createMainWhiteBoardWithFrame:(CGRect)frame
                        loadFinishedBlock:(wbLoadFinishedBlock)loadFinishedBlock
{
    CGFloat height = frame.size.height * 0.6f;
    CGFloat width = height / 3.0f * 5.0f;
    self.whiteBoardViewDefaultSize = CGSizeMake(width, height);
    
    self.mainWhiteBoardView = [[YSWhiteBoardView alloc] initWithFrame:frame fileId:@"0" loadFinishedBlock:loadFinishedBlock];
    self.mainWhiteBoardView.delegate = self;
    [self.mainWhiteBoardView changeWhiteBoardBackgroudColor:YSWhiteBoard_MainBackGroudColor];
    
    return self.mainWhiteBoardView;
}

- (YSWhiteBoardView *)createWhiteBoardWithFileId:(NSString *)fileId
                               loadFinishedBlock:(wbLoadFinishedBlock)loadFinishedBlock
{
    if (![fileId bm_isNotEmpty] || [fileId isEqualToString:@"0"])
    {
        return nil;
    }
    CGRect frame = CGRectMake(whiteBoardViewCurrentLeft, whiteBoardViewCurrentTop, self.whiteBoardViewDefaultSize.width, self.whiteBoardViewDefaultSize.height);
    
    YSWhiteBoardView *whiteBoardView = [[YSWhiteBoardView alloc] initWithFrame:frame fileId:fileId loadFinishedBlock:loadFinishedBlock];
    whiteBoardView.delegate = self;
    
    if (self.isBeginClass)
    {
        [whiteBoardView remotePubMsg:self.beginClassMessage];
    }
    
    if ([self isUserCanDraw])
    {
        YSBrushToolsConfigs *currentConfig = [YSBrushToolsManager shareInstance].currentConfig;
        [whiteBoardView didSelectDrawType:currentConfig.drawType color:currentConfig.colorHex widthProgress:currentConfig.progress];
    }

    [whiteBoardView refreshWhiteBoard];

    [self makeCurrentWhiteBoardViewPoint];
    
    return whiteBoardView;
}

- (void)makeCurrentWhiteBoardViewPoint
{
    static NSUInteger loopCount = 0;
    static NSUInteger lineCount = 0;

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
}

- (void)clickToBringVideoToFont:(UIView *)whiteBoard
{
    [whiteBoard bm_bringToFront];
}

#pragma mark 拖拽手势

- (void)panToMoveWhiteBoardView:(UIView *)whiteBoard withGestureRecognizer:(UIPanGestureRecognizer *)pan
{
    if (!self.isDraging)
    {
        if ([whiteBoard isEqual:self.mainWhiteBoardView])
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
    
    CGPoint endPoint = [pan translationInView:whiteBoard];
    
    if (!self.dragImageView)
    {
        UIImage * img = [whiteBoard bm_screenshot];
        self.dragImageView = [[UIImageView alloc]initWithImage:img];
        [self.mainWhiteBoardView addSubview:self.dragImageView];
    }

        CGFloat dragImageViewX = whiteBoard.bm_originX + endPoint.x;
        CGFloat dragImageViewY = whiteBoard.bm_originY + endPoint.y;
        
        if (dragImageViewX + whiteBoard.bm_width >= self.mainWhiteBoardView.bm_width-1)
        {
            dragImageViewX = self.mainWhiteBoardView.bm_width - 1 - whiteBoard.bm_width;
        }
        else if (dragImageViewX <= 1)
        {
            dragImageViewX = 1;
        }
        
        if (dragImageViewY + whiteBoard.bm_height >= self.mainWhiteBoardView.bm_height - 1)
        {
            dragImageViewY = self.mainWhiteBoardView.bm_height - 1 - whiteBoard.bm_height;
        }
        else if (dragImageViewY <= 1)
        {
            dragImageViewY = 1;
        }
        
        self.dragImageView.frame = CGRectMake(dragImageViewX, dragImageViewY, whiteBoard.bm_width, whiteBoard.bm_height);
        
        if (pan.state == UIGestureRecognizerStateEnded)
        {
            whiteBoard.frame = self.dragImageView.frame;
            
            //x,y值在主白板上的比例
            CGFloat scaleLeft = whiteBoard.bm_originX / self.mainWhiteBoardView.bm_width;
            CGFloat scaleTop = whiteBoard.bm_originY / self.mainWhiteBoardView.bm_height;
            //宽，高值在主白板上的比例
            CGFloat scaleWidth = whiteBoard.bm_width / self.mainWhiteBoardView.bm_width;
            CGFloat scaleHeight = whiteBoard.bm_width / self.mainWhiteBoardView.bm_height;
            
            
            YSWhiteBoardView * whiteBoardView = (YSWhiteBoardView *)whiteBoard;
            
            NSString * msgID = [NSString stringWithFormat:@"MoreWhiteboardState_%@", whiteBoardView.whiteBoardId];
            NSDictionary * data = @{@"x":@(scaleLeft),@"y":@(scaleTop),@"width":@(scaleWidth),@"height":@(scaleHeight),@"small":@NO,@"full":@NO,@"type":@"drag",@"instanceId":whiteBoardView.whiteBoardId};
            NSString * associatedMsgID = [NSString stringWithFormat:@"DocumentFilePage_ExtendShowPage_%@", whiteBoardView.whiteBoardId];
            
            
            [[YSRoomInterface instance] pubMsg:sYSSignalMoreWhiteboardState msgID:msgID toID:@"__all" data:data save:YES associatedMsgID:associatedMsgID associatedUserID:nil expires:0 completion:nil];
            
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.dragImageView removeFromSuperview];
                self.dragImageView = nil;
                self.isDraging = NO;
                [whiteBoard bm_bringToFront];
            });
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
        CGFloat scaleLeft = whiteBoard.bm_originX / self.mainWhiteBoardView.bm_width;
        CGFloat scaleTop = whiteBoard.bm_originY / self.mainWhiteBoardView.bm_height;
        
        //宽，高值在主白板上的比例
        CGFloat scaleWidth = dragImageViewW / self.mainWhiteBoardView.bm_width;
        CGFloat scaleHeight = dragImageViewH / self.mainWhiteBoardView.bm_height;
        
        
        NSString * msgID = [NSString stringWithFormat:@"MoreWhiteboardState_%@",whiteBoard.whiteBoardId];
        NSDictionary * data = @{@"x":@(scaleLeft),@"y":@(scaleTop),@"width":@(scaleWidth),@"height":@(scaleHeight),@"small":@NO,@"full":@NO,@"type":@"resize",@"instanceId":whiteBoard.whiteBoardId};
        NSString * associatedMsgID = [NSString stringWithFormat:@"DocumentFilePage_ExtendShowPage_%@",whiteBoard.whiteBoardId];
        
        
        [[YSRoomInterface instance] pubMsg:sYSSignalMoreWhiteboardState msgID:msgID toID:@"__all" data:data save:YES associatedMsgID:associatedMsgID associatedUserID:nil expires:0 completion:nil];
        
        
        [self.dragImageView removeFromSuperview];
        self.dragImageView = nil;
        self.isDragZooming = NO;
        [whiteBoard bm_bringToFront];
    }
}

///k接收信令进行拖拽和缩放

- (void)receiveMessageToMoveAndZoomWith:(NSDictionary *)message WithInlist:(BOOL)inlist
{
    NSString * instanceId = [message bm_stringForKey:@"instanceId"];
    NSString *fileId = [YSRoomUtil getFileIdFromSourceInstanceId:instanceId];
    if (!fileId)
    {
        return;
    }
    YSWhiteBoardView * whiteBoardView = [self getWhiteBoardViewWithFileId:fileId];
    
    if (!whiteBoardView)
    {
        return;
    }
    
    if (inlist)
    {
        //x,y值在主白板上的比例
        CGFloat scaleLeft = [message bm_floatForKey:@"x"];
        CGFloat scaleTop = [message bm_floatForKey:@"y"];
        //宽，高值在主白板上的比例
        CGFloat scaleWidth = [message bm_floatForKey:@"width"];
        CGFloat scaleHeight = [message bm_floatForKey:@"height"];
        
        NSInteger x = scaleLeft * self.mainWhiteBoardView.bm_width;
        NSInteger y = scaleTop * self.mainWhiteBoardView.bm_height;
        NSInteger width = scaleWidth * self.mainWhiteBoardView.bm_width;
        NSInteger height = scaleHeight * self.mainWhiteBoardView.bm_height;
        
        BOOL small = [message bm_boolForKey:@"small"];
        BOOL full = [message bm_boolForKey:@"full"];
        
        whiteBoardView.frame = CGRectMake(x, y, width, height);
        
        if (small)
        {//最小化
            
        }
        else if (full)
        {//最大化
            
        }
    }
    else
    {
        NSString * type = [message bm_stringForKey:@"type"];
        
        if ([type isEqualToString:@"drag"])
        {//拖拽
            
            //x,y值在主白板上的比例
            CGFloat scaleLeft = [message bm_floatForKey:@"x"];
            CGFloat scaleTop = [message bm_floatForKey:@"y"];
            
            NSInteger x = scaleLeft * self.mainWhiteBoardView.bm_width;
            NSInteger y = scaleTop * self.mainWhiteBoardView.bm_height;
                            
            whiteBoardView.bm_origin = CGPointMake(x, y);
        }
        else if ([type isEqualToString:@"resize"])
        {//缩放
             //宽，高值在主白板上的比例
            CGFloat scaleWidth = [message bm_floatForKey:@"width"];
            CGFloat scaleHeight = [message bm_floatForKey:@"height"];
            
            NSInteger width = scaleWidth * self.mainWhiteBoardView.bm_width;
            NSInteger height = scaleHeight * self.mainWhiteBoardView.bm_height;
            whiteBoardView.bm_size = CGSizeMake(width, height);
        }
        else if ([type isEqualToString:@"small"])
        {//最小化
            
        }
        else if ([type isEqualToString:@"full"])
        {//最大化
            
        }
    }
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

- (void)refreshWhiteBoard
{
    CGFloat height = self.mainWhiteBoardView.bm_size.height * 0.6f;
    CGFloat width = height / 3.0f * 5.0f;
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
}

- (void)setTheCurrentDocumentFileID:(NSString *)fileId
{
    _currentFileId = fileId;
    
    if (![fileId isEqualToString:@"0"])
    {
        YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithFileId:fileId];
        if (whiteBoardView)
        {
            [whiteBoardView bm_bringToFront];
        }
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
    
    whiteBoardView.backgroundColor = [UIColor bm_randomColor];
    
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
        
        [whiteBoardView destroy];
    }
}

#pragma mark  删除所有课件窗口
- (void)removeAllWhiteBoardView
{
    for (YSWhiteBoardView *whiteBoardView in self.coursewareViewList)
    {
        [whiteBoardView destroy];
    }
    
    [self.coursewareViewList removeAllObjects];
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
    
    NSString *sourceInstanceId = [YSRoomUtil getSourceInstanceIdFromFileId:fileId];
    NSDictionary *fileDic = [YSFileModel fileDataDocDic:fileModel sourceInstanceId:sourceInstanceId];
    
    if (self.roomUseType == YSRoomUseTypeLiveRoom)
    {
        [[YSRoomInterface instance] pubMsg:sYSSignalShowPage
                                     msgID:sYSSignalDocumentFilePage_ShowPage
                                      toID:[YSRoomInterface instance].localUser.peerID
                                      data:fileDic
                                      save:NO
                             extensionData:nil
                           associatedMsgID:nil
                          associatedUserID:nil
                                   expires:0
                                completion:nil];
    }
    else
    {
        NSString *msgID = [NSString stringWithFormat:@"%@%@%@", sYSSignalDocumentFilePage_ExtendShowPage, YSWhiteBoardId_Header, self.currentFile.fileid];
        [[YSRoomInterface instance] pubMsg:sYSSignalExtendShowPage
                                     msgID:msgID
                                      toID:[YSRoomInterface instance].localUser.peerID
                                      data:fileDic
                                      save:NO
                             extensionData:nil
                           associatedMsgID:nil
                          associatedUserID:nil
                                   expires:0
                                completion:nil];
    }
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
- (void)changePrimaryColor:(NSString *)colorHex
{
    [self.brushToolsManager changePrimaryColor:colorHex];
}


#pragma mark - 监听课堂 底层通知消息

- (void)loadNotifiction
{
    // checkRoom相关通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnCheckRoom:) name:YSWhiteBoardOnCheckRoomNotification object:nil];
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
    // 教室文件列表的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardFileList:) name:YSWhiteBoardFileListNotification object:nil];
    // 教室消息列表的通知
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnRemoteMsgList:) name:YSWhiteBoardOnRemoteMsgListNotification object:nil];
    // 大并发房间用户上台通知
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomWhiteBoardOnBigRoomUserPublished:) name:YSWhiteBoardOnBigRoomUserPublishedNotification object:nil];
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
    }
}

// 获取服务器地址
- (void)roomGetWhiteBoardOnServerAddrs:(NSNotification *) notification
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
- (void)roomWhiteBoardFileList:(NSNotification *)notification
{   // 3
    NSDictionary *dict = notification.userInfo;
    NSArray *fileList = [dict objectForKey:YSWhiteBoardNotificationUserInfoKey] ;
    NSMutableArray *mFileList = [NSMutableArray arrayWithArray:fileList];
    
    NSDictionary *preloadFileDic = nil;
    
    [self.docmentList removeAllObjects];
    self.docmentDicList = [NSMutableArray arrayWithArray:fileList];

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

- (void)roomWhiteBoardOnRoomConnectedUserlist:(NSNumber *)code response:(NSDictionary *)response
{
    if (![response bm_isNotEmptyDictionary])
    {
        return;
    }

    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:response];

    NSMutableDictionary *myselfDict = [NSMutableDictionary dictionary];
    [myselfDict setValue:[YSRoomInterface instance].localUser.properties forKey:@"properties"];
    [myselfDict setValue:[YSRoomInterface instance].localUser.peerID forKey:@"id"];
    
    [dict setValue:myselfDict forKey:@"myself"];
    
    NSDictionary *msgList = [dict objectForKey:@"msglist"];
    for (NSString *key in msgList.allKeys)
    {
        NSDictionary *msgDic = [msgList bm_dictionaryForKey:key];

        [self roomWhiteBoardOnRemotePubMsgWithMessage:msgDic inList:YES];
    }

    NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:@"seq" ascending:YES];
    // 历史msgList如果有ShowPage信令，需要主动发给H5去刷新当前课件
    BOOL show = NO;
    NSArray *msgArray = [[msgList allValues] sortedArrayUsingDescriptors:@[ desc ]];;
    for (NSDictionary *msgDic in msgArray)
    {
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
            break;
        }
    }
    
    if (!show)
    {
        [self changeCourseWithFileId:self.currentFile.fileid];
        
        if (self.roomUseType != YSRoomUseTypeLiveRoom)
        {
            NSString *fileId = @"0";
            YSFileModel *fileModel = [self getDocumentWithFileID:fileId];
            NSDictionary *fileDic = [YSFileModel fileDataDocDic:fileModel sourceInstanceId:nil];
            
            NSString *msgID = [NSString stringWithFormat:@"%@%@%@", sYSSignalDocumentFilePage_ExtendShowPage, YSWhiteBoardId_Header, self.currentFile.fileid];
            [[YSRoomInterface instance] pubMsg:sYSSignalExtendShowPage
                                         msgID:msgID
                                          toID:[YSRoomInterface instance].localUser.peerID
                                          data:fileDic
                                          save:NO
                                 extensionData:nil
                               associatedMsgID:nil
                              associatedUserID:nil
                                       expires:0
                                    completion:nil];
        }
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
    NSDictionary *dict = notification.userInfo;
    NSDictionary *message = [dict objectForKey:YSWhiteBoardNotificationUserInfoKey];
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
        [self.brushToolsManager changePrimaryColor:colorHex];
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
    }
    
    long ts = (long)[message bm_uintForKey:@"ts"];
    NSString *fromId = [message objectForKey:@"fromID"];
    NSObject *data = [message objectForKey:@"data"];
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
        }
        [self.docmentList enumerateObjectsUsingBlock:^(YSFileModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([fileId isEqualToString:obj.fileid])
            {
                NSDictionary *filedata = [tDataDic bm_dictionaryForKey:@"filedata"];
                obj.currpage = [filedata bm_stringForKey:@"currpage"];
            }
        }];
        [self addOrReplaceDocumentFile:tDataDic];
        [self setTheCurrentDocumentFileID:fileId];
        
        if ([msgName isEqualToString:sYSSignalShowPage])
        {
            if (self.mainWhiteBoardView)
            {
                [self.mainWhiteBoardView changeFileId:fileId];
                [self.mainWhiteBoardView remotePubMsg:message];
            }
        }
        else
        {
            YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithFileId:fileId];
            if (!whiteBoardView)
            {
                whiteBoardView = [self createWhiteBoardWithFileId:fileId loadFinishedBlock:nil];
                whiteBoardView.backgroundColor = [UIColor bm_randomColor];
                [self.mainWhiteBoardView addSubview:whiteBoardView];
                whiteBoardView.topBar.delegate = self;
                
                [self addWhiteBoardViewWithWhiteBoardView:whiteBoardView];
            }
            
            [whiteBoardView remotePubMsg:message];
        }
        
        return;
    }
    else if ([msgName isEqualToString:sYSSignalSharpsChange])
    {
        if ([msgId containsString:@"###_SharpsChange"])
        {
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
            YSWhiteBoardView *whiteBoardView = [self getWhiteBoardViewWithFileId:fileId];
            if (whiteBoardView)
            {
                [whiteBoardView remotePubMsg:message];
            }
        }
        
        return;
    }
    else if ([msgName isEqualToString:sYSSignalMoreWhiteboardState])
    {
        [self receiveMessageToMoveAndZoomWith:message WithInlist:inlist];
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
        NSObject *data = [message objectForKey:@"data"];
        NSDictionary *tDataDic = [YSRoomUtil convertWithData:data];
        if (![tDataDic bm_isNotEmptyDictionary])
        {
            return;
        }
        
        NSString *fileId = [tDataDic bm_stringForKey:@"fileid"];
        if (!fileId)
        {
            NSString *sourceInstanceId = [tDataDic bm_stringForKey:@"sourceInstanceId"];
            if (sourceInstanceId)
            {
                if ([sourceInstanceId isEqualToString:@"default"])
                {
                    return;
                }
                else if (sourceInstanceId.length > YSWhiteBoardId_Header.length)
                {
                    fileId = [sourceInstanceId substringFromIndex:YSWhiteBoardId_Header.length];
                }
            }
        }
        
        if (fileId)
        {
            [self removeWhiteBoardViewWithFileId:fileId];
        }
        
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


@end
