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
#import "YSWBMp3Controlview.h"
#import "YSWBMp4Controlview.h"
#import "YSWBMediaMarkView.h"

#define YSTopViewHeight         (30.0f)

static const CGFloat kMp3_Width_iPhone = 55.0f;
static const CGFloat kMp3_Width_iPad = 70.0f;
#define MP3VIEW_WIDTH                   ([UIDevice bm_isiPad] ? kMp3_Width_iPad : kMp3_Width_iPhone)

@interface YSWhiteBoardView ()
<
    YSWBWebViewManagerDelegate,
    YSCoursewareControlViewDelegate,
    YSWhiteBoardControlViewDelegate
>
{
    /// 是否主白板
    BOOL isMainWhiteBoard;
    
    CGFloat topViewHeight;
    
    CGSize oldSize;
}

@property (nonatomic, strong) NSString *whiteBoardId;
@property (nonatomic, strong) NSString *fileId;

/// 媒体课件窗口
@property (nonatomic, assign) BOOL isMediaView;
@property (nonatomic, assign) YSWhiteBordMediaType mediaType;

/// 白板背景容器
@property (nonatomic, strong) UIView *whiteBoardContentView;
/// 白板背景图
@property (nonatomic, strong) UIImageView *bgImageView;

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

/// 当前页码
@property (nonatomic, assign) NSUInteger currentPage;
/// 总页码
@property (nonatomic, assign) NSUInteger totalPage;

/// 翻页工具条拖动前的临时View
@property (nonatomic, strong) UIImageView *dragPageControlViewImage;

/// 右下角拖动放大的view
@property (nonatomic, strong) UIView *dragZoomView;

/// 小白板点击控制条全屏前的frame
//@property (nonatomic, assign)CGRect whiteBoardFrame;

/// MP3播放控制
@property (nonatomic, strong) YSWBMp3Controlview *mp3ControlView;
/// MP3播放动画
@property (nonatomic, strong) UIImageView *playMp3ImageView;

/// 视频播放背景
@property (nonatomic, strong) UIImageView *mp4WaitingImageView;
/// 视频播放控制
@property (nonatomic, strong) YSWBMp4ControlView *mp4ControlView;
/// H5媒体关闭
@property (nonatomic, strong) UIButton *closeH5Mp4Btn;
/// H5媒体点击手势接收
@property (nonatomic, strong) UIView *h5Mp4TapGestureView;

/// 白板视频标注视图
@property (nonatomic, strong) YSWBMediaMarkView *mediaMarkView;
@property (nonatomic, strong) NSMutableArray <NSDictionary *> *mediaMarkSharpsDatas;

/// H5课件cookie
@property (nonatomic, strong) NSArray <NSDictionary *> *connectH5CoursewareUrlCookies;

@end

@implementation YSWhiteBoardView

- (void)dealloc
{
    [self destroy];
}

- (void)destroy
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideMp4ControlView) object:nil];

    [self.cacheMsgPool removeAllObjects];
    self.cacheMsgPool = nil;

    [self.webViewManager destroy];
    self.webViewManager = nil;

    [self.drawViewManager clearAfterClass];
    self.drawViewManager = nil;
}

- (instancetype)initWithFrame:(CGRect)frame fileId:(NSString *)fileId loadFinishedBlock:(wbLoadFinishedBlock)loadFinishedBlock
{
    return [self initWithFrame:frame fileId:fileId isMedia:NO mediaType:YSWhiteBordMediaType_Video loadFinishedBlock:loadFinishedBlock];
}

- (instancetype)initWithFrame:(CGRect)frame fileId:(NSString *)fileId isMedia:(BOOL)isMedia mediaType:(YSWhiteBordMediaType)mediaType loadFinishedBlock:(nullable  wbLoadFinishedBlock)loadFinishedBlock
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.fileId = fileId;
        self.isMediaView = isMedia;
        self.mediaType = mediaType;
        
        if ([fileId isEqualToString:@"0"])
        {
            isMainWhiteBoard = YES;
            self.whiteBoardId = YSDefaultWhiteBoardId;
        }
        else
        {
            isMainWhiteBoard = NO;
            self.whiteBoardId = [NSString stringWithFormat:@"%@%@", YSWhiteBoardId_Header, fileId];
        }
        
        self.cacheMsgPool = [NSMutableArray array];
        self.loadingH5Fished = NO;
        if (self.isMediaView)
        {
            self.loadingH5Fished = YES;
        }
        self.mediaMarkSharpsDatas = [NSMutableArray array];

        topViewHeight = 0;

        if (!isMainWhiteBoard && (!self.isMediaView || self.mediaType != YSWhiteBordMediaType_Audio))
        {
            topViewHeight = YSTopViewHeight;
            
            YSFileModel *model = [[YSWhiteBoardManager shareInstance] getDocumentWithFileID:self.fileId];
            
            YSWhiteBoardTopBar *topBar = [[YSWhiteBoardTopBar alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, YSTopViewHeight)];
            topBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            topBar.titleString = model.filename;
            [self addSubview:topBar];
            self.topBar = topBar;
            
            BMWeakSelf
            topBar.barButtonsClick = ^(UIButton * _Nonnull sender) {
                [weakSelf topBarButtonClick:sender];
            };
        }
        
        CGRect contentFrame = CGRectMake(0, topViewHeight, frame.size.width, frame.size.height-topViewHeight);
        UIView *whiteBoardContentView = [[UIView alloc] initWithFrame:contentFrame];
        [self addSubview:whiteBoardContentView];
        self.whiteBoardContentView = whiteBoardContentView;
        if (self.mediaType == YSWhiteBordMediaType_Audio)
        {
            self.whiteBoardContentView.backgroundColor = [UIColor clearColor];
        }
        else
        {
            self.whiteBoardContentView.backgroundColor = YSWhiteBoard_BackGroudColor;
        }
        
        UITapGestureRecognizer *oneTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeToCurrentBWView:)];
        oneTap.numberOfTapsRequired = 1;
        [self.whiteBoardContentView addGestureRecognizer:oneTap];

        if (!isMedia)
        {
            self.bgImageView = [[UIImageView alloc] init];
            [self.whiteBoardContentView addSubview:self.bgImageView];
            self.bgImageView.frame = self.whiteBoardContentView.bounds;
            self.bgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            self.bgImageView.contentMode = UIViewContentModeScaleAspectFit;
            
            self.webViewManager = [[YSWBWebViewManager alloc] init];
            self.webViewManager.delegate = self;
            
            self.wbView = [self.webViewManager createWhiteBoardWithFrame:whiteBoardContentView.bounds connectH5CoursewareUrlCookies:self.connectH5CoursewareUrlCookies loadFinishedBlock:loadFinishedBlock];
            [self.whiteBoardContentView addSubview:self.wbView];
            
            self.drawViewManager = [[YSWBDrawViewManager alloc] initWithBackView:whiteBoardContentView webView:self.wbView];
            
            YSCoursewareControlView *pageControlView = [[YSCoursewareControlView alloc] initWithFrame:CGRectMake(0, 0, 232, 28)];
            pageControlView.delegate = self;
            pageControlView.fileId = self.fileId;
            [self addSubview:pageControlView];
            self.pageControlView = pageControlView;
            self.pageControlView.bm_centerX = frame.size.width * 0.5f;
            self.pageControlView.bm_bottom = frame.size.height - 20;
            
            // 拖拽
            UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragPageControlView:)];
            [self.pageControlView addGestureRecognizer:panGestureRecognizer];
        }
            
        if (self.mediaType != YSWhiteBordMediaType_Audio)
        {
            if ([YSRoomInterface instance].localUser.role == YSUserType_Teacher )
            {
                if (!isMainWhiteBoard)
                {
                    UIView *dragZoomView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 40, 40)];
                    dragZoomView.backgroundColor = UIColor.clearColor;
                    dragZoomView.bm_right = frame.size.width;
                    dragZoomView.bm_bottom = frame.size.height;
                    self.dragZoomView = dragZoomView;
                    [self addSubview:dragZoomView];
                    
                    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panGestureToZoomView:)];
                    [dragZoomView addGestureRecognizer:panGesture];
                    
                    YSWhiteBoardControlView *whiteBoardControlView = [[YSWhiteBoardControlView alloc] initWithFrame:CGRectMake(self.bm_width - 70 - 70, self.pageControlView.bm_originY, 70, 28)];
                    whiteBoardControlView.bm_bottom = self.bm_height - 20;
                    whiteBoardControlView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
                    [self addSubview:whiteBoardControlView];
                    self.whiteBoardControlView = whiteBoardControlView;
                    self.whiteBoardControlView.delegate = self;
                    whiteBoardControlView.hidden = YES;
                    
                    [self makeMp4WaitingView];
                    [self makeMp4ControlView];
                }
                else
                {
                    // 最小化时的收藏夹按钮
                    UIButton *collectBtn = [[UIButton alloc]initWithFrame:CGRectMake(frame.size.width-40-26, frame.size.height-90, 40, 40)];
                    collectBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
                    [collectBtn setImage:[UIImage imageNamed:@"SplitScreen_leaveMessage_normal"] forState:UIControlStateNormal];
                    [collectBtn setImage:[UIImage imageNamed:@"SplitScreen_leaveMessage_selected"] forState:UIControlStateSelected];
                    collectBtn.contentMode = UIViewContentModeScaleAspectFill;
                    [collectBtn addTarget:self action:@selector(collectButtonsClick:) forControlEvents:UIControlEventTouchUpInside];
                    [self addSubview:collectBtn];
                    self.collectBtn = collectBtn;
                }
            }
        }
        else
        {
            // 音频
            if ([[YSWhiteBoardManager shareInstance] isCanControlWhiteBoardView])
            {
                [self makeMp3ControlView];
            }
            else
            {
                [self makeMp3Animation];
            }
        }
    }
    
    return self;
}

- (void)makeMp3Animation
{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, MP3VIEW_WIDTH, MP3VIEW_WIDTH)];
    
    NSMutableArray *imageArray = [[NSMutableArray alloc] init];
    for (NSUInteger i=1; i<=50; i++)
    {
        NSString *imageName = [NSString stringWithFormat:@"main_playmp3_%02lu", (unsigned long)i];
        [imageArray addObject:imageName];
    }
    
    [imageView bm_animationWithImageArray:imageArray duration:2 repeatCount:0];
    
    self.playMp3ImageView = imageView;
    
    [self addSubview:self.playMp3ImageView];
    
    self.bm_size = self.playMp3ImageView.bm_size;
    
    UITapGestureRecognizer *oneTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeToCurrentBWView:)];
    oneTap.numberOfTapsRequired = 1;
    self.playMp3ImageView.userInteractionEnabled = YES;
    [self.playMp3ImageView addGestureRecognizer:oneTap];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureToMoveMp3View:)];
    [self addGestureRecognizer:panGesture];
}

- (void)makeMp3ControlView
{
    self.mp3ControlView = [[YSWBMp3Controlview alloc] init];
    self.mp3ControlView.delegate = [YSWhiteBoardManager shareInstance];
    self.mp3ControlView.backgroundColor = [UIColor bm_colorWithHex:0x000000 alpha:0.39];
    [self addSubview:self.mp3ControlView];
    if ([UIDevice bm_isiPad])
    {
        self.mp3ControlView.frame = CGRectMake(0, 0, 386, 74);
        [self.mp3ControlView bm_roundedRect:37];
    }
    else
    {
        self.mp3ControlView.frame = CGRectMake(0, 0, 300, 60);
        [self.mp3ControlView bm_roundedRect:30];
    }
    
    self.bm_size = self.mp3ControlView.bm_size;
    
    UITapGestureRecognizer *oneTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeToCurrentBWView:)];
    oneTap.numberOfTapsRequired = 1;
    [self.mp3ControlView addGestureRecognizer:oneTap];

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureToMoveMp3View:)];
    [self addGestureRecognizer:panGesture];
}

- (void)makeMp4ControlView
{
    self.mp4ControlView = [[YSWBMp4ControlView alloc] init];
    self.mp4ControlView.frame = CGRectMake(30, 0, self.bm_width - 60, 46);
    self.mp4ControlView.bm_bottom = self.bm_height - 23;
    [self addSubview:self.mp4ControlView];
    
    self.mp4ControlView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [self.mp4ControlView bm_roundedRect:23];
    
    self.mp4ControlView.hidden = YES;
    self.mp4ControlView.delegate = [YSWhiteBoardManager shareInstance];
}

- (void)makeMp4WaitingView
{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.whiteBoardContentView.bounds];
    imageView.contentMode = UIViewContentModeCenter;
    [self.whiteBoardContentView addSubview:imageView];
    imageView.backgroundColor = [UIColor blackColor];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if (!self.isMediaView)
    {
        imageView.hidden = YES;
    }
    self.mp4WaitingImageView = imageView;
    
    NSMutableArray *imageArray = [[NSMutableArray alloc] init];
    for (NSUInteger i=1; i<=21; i++)
    {
        NSString *imageName = [NSString stringWithFormat:@"ysfloatview_loding%@", @(i)];
        [imageArray addObject:imageName];
    }
    [imageView bm_animationWithImageArray:imageArray duration:3 repeatCount:0];
    [imageView startAnimating];
}

- (void)hideMp4ControlView
{
    self.mp4ControlView.hidden = YES;
}

- (void)setIsH5LoadMedia:(BOOL)isH5LoadMedia
{
    if (isH5LoadMedia == _isH5LoadMedia)
    {
        return;
    }
    
    _isH5LoadMedia = isH5LoadMedia;
    
    if (isH5LoadMedia)
    {
        self.pageControlView.hidden = YES;

        self.mp4WaitingImageView.hidden = NO;
        [self.mp4WaitingImageView bm_bringToFront];
        
        if ([[YSWhiteBoardManager shareInstance] isCanControlWhiteBoardView])
        {
            UIButton *closeH5Mp4Btn = [UIButton buttonWithType:UIButtonTypeCustom];
            [closeH5Mp4Btn addTarget:self action:@selector(stopH5Media) forControlEvents:UIControlEventTouchUpInside];
            [closeH5Mp4Btn setImage:[UIImage imageNamed:@"ysh5media_closemp4_normal"] forState:UIControlStateNormal];
            closeH5Mp4Btn.frame = CGRectMake(self.frame.size.width - 35, 40, 25, 25);
            closeH5Mp4Btn.backgroundColor = [UIColor clearColor];
            closeH5Mp4Btn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
            self.closeH5Mp4Btn = closeH5Mp4Btn;
            [self addSubview:closeH5Mp4Btn];
            self.h5Mp4TapGestureView = [[UIView alloc] initWithFrame:CGRectMake(0, YSTopViewHeight, self.frame.size.width, self.frame.size.height - YSTopViewHeight)];
            self.h5Mp4TapGestureView.backgroundColor = [UIColor clearColor];
            [self addSubview:self.h5Mp4TapGestureView];
            self.h5Mp4TapGestureView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            
            [self.mp4ControlView bm_bringToFront];
            [self.closeH5Mp4Btn bm_bringToFront];
            [self.whiteBoardControlView bm_bringToFront];
            [self.dragZoomView bm_bringToFront];
            UITapGestureRecognizer *oneTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeToCurrentBWView:)];
            oneTap.numberOfTapsRequired = 1;
            [self.h5Mp4TapGestureView addGestureRecognizer:oneTap];
        }
    }
    else
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideMp4ControlView) object:nil];
        self.pageControlView.hidden = NO;
        self.mp4WaitingImageView.hidden = YES;
        self.mp4ControlView.hidden = YES;
        if (self.closeH5Mp4Btn)
        {
            [self.closeH5Mp4Btn removeFromSuperview];
            self.closeH5Mp4Btn = nil;
        }
        
        if (self.h5Mp4TapGestureView)
        {
            [self.h5Mp4TapGestureView removeFromSuperview];
            self.h5Mp4TapGestureView = nil;
        }
    }
}

- (void)stopH5Media
{
    if (self.isH5LoadMedia)
    {
        [[YSRoomInterface instance] stopShareMediaFile:nil];
    }
}

- (void)changeToCurrentBWView:(UITapGestureRecognizer *)tapGesture
{
    if ([[YSWhiteBoardManager shareInstance] isCanControlWhiteBoardView])
    {
        if (self.isMediaView || self.isH5LoadMedia)
        {
            self.mp4ControlView.hidden = !self.mp4ControlView.hidden;
            if (!self.mp4ControlView.hidden)
            {
                [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideMp4ControlView) object:nil];
                [self performSelector:@selector(hideMp4ControlView) withObject:nil afterDelay:3.0f];
            }
        }

        [[YSWhiteBoardManager shareInstance] setTheCurrentDocumentFileID:self.fileId];
    }
}

- (void)panGestureToMoveMp3View:(UIPanGestureRecognizer *)panGesture
{
    if ([self.delegate respondsToSelector:@selector(moveMp3ViewWithGestureRecognizer:)])
    {
        [self.delegate moveMp3ViewWithGestureRecognizer:panGesture];
    }
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    CGRect contentFrame = CGRectMake(0, topViewHeight, frame.size.width, frame.size.height-topViewHeight);
    self.whiteBoardContentView.frame = contentFrame;
    [self.drawViewManager updateFrame];
        
    self.pageControlView.bm_centerX = frame.size.width * 0.5f;
    self.pageControlView.bm_bottom = frame.size.height - 20;

    self.dragZoomView.bm_right = frame.size.width;
    self.dragZoomView.bm_bottom = frame.size.height;

    if (1)
    {
        if (self.mp4ControlView.bm_width < 300)
        {
            [self.mp4ControlView hideMp4ControlViewOutsidePause:YES];
        }
        else
        {
            [self.mp4ControlView hideMp4ControlViewOutsidePause:NO];
        }
        
        if ([self.positionData bm_boolForKey:@"full"])
        {
            self.mp4ControlView.frame = CGRectMake(80, 0, self.whiteBoardControlView.bm_left - 10 - 80 , 46);
        }
        else
        {
            self.mp4ControlView.frame = CGRectMake(30, 0, self.bm_width - 60, 46);
        }
        self.mp4ControlView.bm_bottom = self.bm_height - 23;
    }
}

- (void)doMsgCachePool
{
    // 执行所有缓存的信令消息
    NSArray *array = self.cacheMsgPool;
    
    for (NSDictionary *dic in array)
    {
        NSString *func = dic[kYSMethodNameKey];
        SEL funcSel = NSSelectorFromString(func);

        NSLog(@"===================doMsgCachePool: %@", func);

        NSMutableArray *params = [NSMutableArray array];
        if ([[dic allKeys] containsObject:kYSParameterKey])
        {
            params = dic[kYSParameterKey];
        }
        
        switch (params.count)
        {
            case 1:
                ((void (*)(id, SEL, id))objc_msgSend)(self, funcSel, params.firstObject);
                break;
                
            default:
                break;
        }
    }
    
    [self.cacheMsgPool removeAllObjects];
}

- (void)refreshWhiteBoard
{
    CGRect frame = self.frame;
    if (self.mediaType == YSWhiteBordMediaType_Audio)
    {
        [self refreshWhiteBoardWithFrame:frame];
        
        return;
    }
    
    if (self != [YSWhiteBoardManager shareInstance].mainWhiteBoardView)
    {
        NSDictionary *message = self.positionData;
        
        if (self.isMediaView)
        {
            NSDictionary *positionData = [[YSWhiteBoardManager shareInstance].allPositionDict bm_dictionaryForKey:self.fileId];
            if ([positionData bm_isNotEmpty])
            {
                message = positionData;
            }
        }
        
        if (self.pageControlView.isAllScreen)
        {
            frame = CGRectMake(0, -30, BMUI_SCREEN_WIDTH, BMUI_SCREEN_HEIGHT+30);
            self.whiteBoardControlView.hidden = YES;
        }
        else
        {
            NSString * type = [message bm_stringForKey:@"type"];
            
            if (([type isEqualToString:@"full"] || [type isEqualToString:@"init"]) && [message bm_boolForKey:@"full"])
            {
                frame = CGRectMake(0, -30, self.mainWhiteBoard.bm_width, self.mainWhiteBoard.bm_height+30);
                self.whiteBoardControlView.hidden = NO;
            }
            else
            {
                CGFloat scale = self.mainWhiteBoard.bm_width / self.mainWhiteBoard.bm_height;
                
                CGFloat height = 0;
                CGFloat width = 0;
                if (scale > 5.0/3.0)
                {
                    CGFloat scaleHeight = [message bm_floatForKey:@"height"];
                    height = scaleHeight * self.mainWhiteBoard.bm_height;
                    width = height * 5.0/3.0;
                }
                else
                {
                    CGFloat scaleWidth = [message bm_floatForKey:@"width"];
                    width = scaleWidth * self.mainWhiteBoard.bm_width;
                    height = width * 3.0/5.0;
                }
                
                
                if (!width || !height)
                {
                    width = self.bm_width;
                    height = self.bm_height;
                }
                
                //x,y值在主白板上的比例
                CGFloat scaleLeft = [message bm_floatForKey:@"x"];
                CGFloat scaleTop = [message bm_floatForKey:@"y"];
                
                CGFloat x = scaleLeft * (self.mainWhiteBoard.bm_width - width);
                CGFloat y = scaleTop * (self.mainWhiteBoard.bm_height - height);
                
                if ((x + width) > (self.mainWhiteBoard.bm_width - 2))
                {
                    x = self.mainWhiteBoard.bm_width - width - 1;
                }
                
                if ((y + height) > (self.mainWhiteBoard.bm_height - 2))
                {
                    y = self.mainWhiteBoard.bm_height - height - 1;
                }
                
                frame = CGRectMake(x, y, width, height);
                
                self.whiteBoardControlView.hidden = YES;
            }
        }
    }
    
    [self refreshWhiteBoardWithFrame:frame];
}

// 页面刷新尺寸
- (void)refreshWhiteBoardWithFrame:(CGRect)frame;
{
    self.frame = frame;
    [self refreshWebWhiteBoard];
}

/// 变更白板窗口背景色
- (void)changeWhiteBoardBackgroudColor:(UIColor *)color
{
    if (!color)
    {
        color = YSWhiteBoard_BackGroudColor;
    }

    self.whiteBoardContentView.backgroundColor = color;
}

/// 变更白板画板背景色
- (void)changeCourseViewBackgroudColor:(UIColor *)color
{
    [self.drawViewManager changeCourseViewBackgroudColor:color];
}

/// 变更白板背景图
- (void)changeMainWhiteBoardBackImage:(UIImage *)image
{
    self.bgImageView.image = image;
}

- (CGFloat)documentZoomScale
{
    if (self.drawViewManager.showOnWeb)
    {
        return 1.0f;
    }
    else
    {
        return [self.drawViewManager documentZoomScale];
    }
}

#pragma mark - 监听课堂 底层通知消息

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
    if (!self.loadingH5Fished)
    {
        NSLog(@"===================cacheMsgPool userPropertyChanged");
        
        NSString *methodName = NSStringFromSelector(@selector(userPropertyChanged:));
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setValue:methodName forKey:kYSMethodNameKey];
        [dic setValue:@[message] forKey:kYSParameterKey];
        [self.cacheMsgPool addObject:dic];
        
        return;
    }

    NSLog(@"===================userPropertyChanged");

    if (self.webViewManager)
    {
        [self.webViewManager sendSignalMessageToJS:WBSetProperty message:message];
    }
    
    if (self.drawViewManager)
    {
        [self.drawViewManager updateProperty:message];
    }
    NSDictionary *properties = [message bm_dictionaryForKey:@"properties"];
    if (![properties bm_isNotEmptyDictionary])
    {
        return;
    }
    
    if ([properties bm_containsObjectForKey:@"candraw"])
    {
        if ([properties bm_boolForKey:@"candraw"])
        {
            BOOL isCurrent = self.isCurrent;
            BOOL canPageTurningFlag = [YSWhiteBoardManager shareInstance].roomConfig.canPageTurningFlag;
            YSUserRoleType role = [YSRoomInterface instance].localUser.role;
            
            if ((role == YSUserType_Student  && isCurrent && canPageTurningFlag) || role == YSUserType_Teacher)
            {
                self.pageControlView.allowTurnPage = YES;
            }
        }
        else
        {
            self.pageControlView.allowTurnPage = NO;
        }
    }
}

/// 收到远端pubMsg消息通知
- (void)remotePubMsg:(NSDictionary *)message
{
    if (!self.loadingH5Fished)
    {
        NSLog(@"===================cacheMsgPool remotePubMsg");
        
        NSString *methodName = NSStringFromSelector(@selector(remotePubMsg:));
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setValue:methodName forKey:kYSMethodNameKey];
        [dic setValue:@[message] forKey:kYSParameterKey];
        [self.cacheMsgPool addObject:dic];
        
        return;
    }

    NSString *msgName = [message bm_stringForKey:@"name"];
    NSString *msgId = [message bm_stringForKey:@"id"];
    NSString *fromId = [message objectForKey:@"fromID"];
    NSObject *data = [message objectForKey:@"data"];
    NSDictionary *tDataDic = [YSRoomUtil convertWithData:data];

    NSLog(@"===================remotePubMsg: %@", msgName);
    
    if (self.webViewManager)
    {
        BOOL remotePub = YES;
        if (![msgName isEqualToString:sYSSignalShowPage] && ![msgName isEqualToString:sYSSignalExtendShowPage] && ![msgName isEqualToString:sYSSignalH5DocumentAction] && ![msgName isEqualToString:sYSSignalNewPptTriggerActionClick] && ![msgName isEqualToString:sYSSignalClassBegin])
        {
            remotePub = NO;
        }

        if (remotePub)
        {
            // 关联媒体课件不响应
            if ([msgName isEqualToString:sYSSignalShowPage] || [msgName isEqualToString:sYSSignalExtendShowPage])
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
        
        if (([msgName isEqualToString:sYSSignalShowPage] || [msgName isEqualToString:sYSSignalExtendShowPage]) && ![fromId isEqualToString:[YSRoomInterface instance].localUser.peerID])
        {
            [self.webViewManager stopPlayMp3];
        }
    }
        
    if (self.drawViewManager)
    {
        [self.drawViewManager receiveWhiteBoardMessage:[NSMutableDictionary dictionaryWithDictionary:message] isDelMsg:NO];
    }
    
    if (([msgName isEqualToString:sYSSignalShowPage] || [msgName isEqualToString:sYSSignalExtendShowPage]))
    {
        self.pageControlView.frashBtn.selected = NO;
        
        id data = [tDataDic bm_dictionaryForKey:@"filedata"];
        NSDictionary *fileDataDic = [YSRoomUtil convertWithData:data];
        
        if ([fileDataDic bm_isNotEmptyDictionary])
        {
            BOOL isDynamic = NO;
            if ([tDataDic bm_boolForKey:@"isDynamicPPT"] || [tDataDic bm_boolForKey:@"isH5Document"])
            {
                isDynamic = YES;
            }
            else if ([tDataDic bm_boolForKey:@"isGeneralFile"])
            {
                NSString *filetype = [[fileDataDic bm_stringForKey:@"filetype"] lowercaseString];
                NSString *path = [[fileDataDic bm_stringForKey:@"swfpath"] lowercaseString];
                if ([filetype isEqualToString:@"gif"] || [filetype isEqualToString:@"svg"])
                {
                    isDynamic = YES;
                }
                else if ([path hasSuffix:@".gif"] || [path hasSuffix:@".svg"])
                {
                    isDynamic = YES;
                }
            }
            
            if (!isDynamic)
            {
                NSInteger totalPage = [fileDataDic bm_intForKey:@"pagenum"];
                NSInteger currentPage = [fileDataDic bm_intForKey:@"currpage"];
                
                self.pageControlView.allowScaling = YES;
                self.pageControlView.bm_centerX = self.bm_width * 0.5f;
                [self.pageControlView sc_setTotalPage:totalPage currentPage:currentPage isWhiteBoard:[self.fileId isEqualToString:@"0"]];
            }
        }
    }
}

/// 收到远端delMsg消息的通知
- (void)remoteDelMsg:(NSDictionary *)message
{
    if (!self.loadingH5Fished)
    {
        NSString *methodName = NSStringFromSelector(@selector(remoteDelMsg:));
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setValue:methodName forKey:kYSMethodNameKey];
        [dic setValue:@[message] forKey:kYSParameterKey];
        [self.cacheMsgPool addObject:dic];
        
        return;
    }

    NSString *msgName = [message bm_stringForKey:@"name"];

    NSLog(@"===================remoteDelMsg: %@", msgName);
    
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


#pragma mark -
#pragma mark YSWBWebViewManagerDelegate

/// H5脚本文件加载初始化完成
- (void)onWBWebViewManagerPageFinshed
{
    NSLog(@"===================onWBWebViewManagerPageFinshed");
    
    self.loadingH5Fished = YES;
    
    // 更新地址
    [self updateWebAddressInfo:[YSWhiteBoardManager shareInstance].serverAddressInfoDic];
    
//    if (self.drawViewManager)
//    {
//        // 更新白板数据
//        self.drawViewManager.address = [YSWhiteBoardManager shareInstance].serverDocAddrKey;
//    }
    
    [self doMsgCachePool];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(onWBViewWebViewManagerPageFinshed:)])
    {
        [self.delegate onWBViewWebViewManagerPageFinshed:self];
    }
}

/// Web课件翻页结果
- (void)onWBWebViewManagerStateUpdate:(NSDictionary *)dic
{
    NSLog(@"===================onWBWebViewManagerStateUpdate");
    NSLog(@"%s,message:%@", __func__, dic);
    
    BOOL prevPage = NO;
    BOOL nextPage = NO;
    
    if (self.drawViewManager)
    {
        // 设置页码
        if ([dic bm_containsObjectForKey:@"page"])
        {
            NSDictionary *dicPage = [dic bm_dictionaryForKey:@"page"];
            if ([dicPage bm_containsObjectForKey:@"currentPage"] && [dicPage bm_containsObjectForKey:@"totalPage"])
            {
                self.currentPage = [dicPage bm_uintForKey:@"currentPage"];
                self.totalPage   = [dicPage bm_uintForKey:@"totalPage"];
                
                NSString *fileId = self.fileId;
                if (!fileId)
                {
                     fileId = @"0";
                }
                
                YSFileModel *file = [[YSWhiteBoardManager shareInstance] getDocumentWithFileID:fileId];
                file.currpage = [dicPage bm_uintForKey:@"currentPage"];
                file.pagenum = [dicPage bm_uintForKey:@"totalPage"];

                // 肯定是showOnWeb
                if (self.drawViewManager.showOnWeb)
                {
                    if ([dicPage bm_containsObjectForKey:@"pptstep"])
                    {
                        file.pptstep = [dicPage bm_uintForKey:@"pptstep"];
                    }
                    if ([dicPage bm_containsObjectForKey:@"steptotal"])
                    {
                        file.steptotal = [dicPage bm_uintForKey:@"steptotal"];
                    }
                    [self.drawViewManager setTotalPage:self.totalPage currentPage:self.currentPage];
                }
                
                NSString *log = [NSString stringWithFormat:@"网页课件读取翻页成功%@  currentpage_%@  step_%@", fileId, @(self.currentPage), @(file.pptstep)];
                [[YSRoomInterface instance] serverLog:log];
            }
            
            prevPage = [dicPage bm_boolForKey:@"prevPage"];
            nextPage = [dicPage bm_boolForKey:@"nextPage"];
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
            [self.drawViewManager updateWBRatio:ratio];
        }
    }
    self.pageControlView.allowScaling = NO;
    self.pageControlView.bm_centerX = self.bm_width * 0.5f;
    [self.pageControlView sc_setTotalPage:self.totalPage currentPage:self.currentPage canPrevPage:prevPage canNextPage:nextPage isWhiteBoard:[self.fileId isEqualToString:@"0"]];
        
    if (self.delegate && [self.delegate respondsToSelector:@selector(onWBViewWebViewManagerStateUpdate:withState:)])
    {
        [self.delegate onWBViewWebViewManagerStateUpdate:self withState:dic];
    }
}

/// 课件加载成功回调
- (void)onWBWebViewManagerLoadedState:(NSDictionary *)dic
{
    self.isLoadingFinish = [dic[@"notice"] isEqualToString:@"loadSuccess"];
    NSLog(@"===================onWBWebViewManagerLoadedState: %@", @(self.isLoadingFinish));

    self.pageControlView.frashBtn.selected = NO;
    // 通知刷新白板
    [self refreshWhiteBoard];
    
    NSDictionary *data = [dic bm_dictionaryForKey:@"data"];
    NSString *fileid = [data bm_stringForKey:@"fileid" withDefault:@""];
    NSString *currentpage = [data bm_stringForKey:@"currpage" withDefault:@""];
    NSString *step = [data bm_stringForKey:@"step" withDefault:@""];
    NSString *cdn = [data bm_stringForKey:@"cdn" withDefault:@""];
    NSString *completeCourseUrl = [data bm_stringForKey:@"completeCourseUrl" withDefault:@""];
    NSString *log = [NSString stringWithFormat:@"网页课件读取结果%@_%@  currentpage_%@  step_%@  cdn_%@  completeCourseUrl_%@", fileid, @(self.isLoadingFinish), currentpage, step, cdn, completeCourseUrl];

    [[YSRoomInterface instance] serverLog:log];
    
    if (!self.isLoadingFinish && [dic objectForKey:@"data"] != nil)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:YSWhiteBoardEventLoadFileFail object:dic[@"data"]];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(onWBViewWebViewManagerLoadedState:withState:)])
    {
        [self.delegate onWBViewWebViewManagerLoadedState:self withState:dic];
    }
}

/// 翻页超时
- (void)onWBWebViewManagerSlideLoadTimeout:(NSDictionary *)dic
{
    if ([dic objectForKey:@"data"] == nil)
    {
        return;
    }
    
    NSLog(@"===================onWBWebViewManagerSlideLoadTimeout");
    
    NSDictionary *data = [dic bm_dictionaryForKey:@"data"];
    NSString *fileid = [data bm_stringForKey:@"fileid" withDefault:@""];
    NSString *currentpage = [data bm_stringForKey:@"currpage" withDefault:@""];
    NSString *step = [data bm_stringForKey:@"step" withDefault:@""];
    NSString *cdn = [data bm_stringForKey:@"cdn" withDefault:@""];
    NSString *completeCourseUrl = [data bm_stringForKey:@"completeCourseUrl" withDefault:@""];
    NSString *log = [NSString stringWithFormat:@"网页课件读取Timeout%@  currentpage_%@  step_%@  cdn_%@  completeCourseUrl_%@", fileid, currentpage, step, cdn, completeCourseUrl];

    [[YSRoomInterface instance] serverLog:log];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:YSWhiteBoardEventLoadSlideFail object:dic[@"data"]];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(onWBViewWebViewManagerSlideLoadTimeout:withState:)])
    {
        [self.delegate onWBViewWebViewManagerSlideLoadTimeout:self withState:dic];
    }
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
    
    [dictionary bm_setString:self.whiteBoardId forKey:@"sourceInstanceId"];
    [dictionary bm_setBool:YES forKey:@"initiative"];

    NSString *tellWho = [YSRoomInterface instance].localUser.peerID;
    NSString *associatedUserID = [YSRoomInterface instance].localUser.peerID;
    BOOL save = NO;
    if (!freshCurrentCourse && [YSWhiteBoardManager shareInstance].isBeginClass)
    {
        if ([YSRoomInterface instance].localUser.canDraw || [YSRoomInterface instance].localUser.role == YSUserType_Teacher)
        {
            tellWho = YSRoomPubMsgTellAll;
            save = YES;
            associatedUserID = nil;
        }
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    
    NSString *dataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    if ([[YSWhiteBoardManager shareInstance] isOneWhiteBoardView])
    {
        [[YSRoomInterface instance] pubMsg:sYSSignalShowPage msgID:sYSSignalDocumentFilePage_ShowPage toID:tellWho data:dataString save:save extensionData:@{} associatedMsgID:nil associatedUserID:associatedUserID expires:0 completion:nil];
    }
    else
    {
        NSString *msgID = [NSString stringWithFormat:@"%@%@", sYSSignalDocumentFilePage_ExtendShowPage, self.whiteBoardId];
        [[YSRoomInterface instance] pubMsg:sYSSignalExtendShowPage msgID:msgID toID:tellWho data:dataString save:save extensionData:@{} associatedMsgID:nil associatedUserID:associatedUserID expires:0 completion:nil];
    }
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
        [filedata setObject:@(self.currentPage) forKey:@"currpage"];
        [self.drawViewManager.fileDictionary setObject:filedata forKey:@"filedata"];
        [self showPageWithDictionary:self.drawViewManager.fileDictionary isFreshCurrentCourse:YES];
    }
}

- (NSDictionary *)makeSlideOrStepDicWithFileModel:(YSFileModel *)model isNext:(BOOL)isNext
{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];

    [dic bm_setBool:model.isDynamicPPT forKey:@"isDynamicPPT"];
    [dic bm_setBool:model.isGeneralFile forKey:@"isGeneralFile"];
    [dic bm_setBool:model.isH5Document forKey:@"isH5Document"];

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
        [dic bm_setBool:model.isMedia forKey:@"isMedia"];
    }

    if (!model.currpage)
    {
        [dic setObject:filedata forKey:@"filedata"];
        return dic;
    }
    [filedata bm_setInteger:model.currpage forKey:@"currpage"];
    
    if (model.pagenum)
    {
        [filedata bm_setInteger:model.pagenum forKey:@"pagenum"];
    }
    
    if (!model.pptslide)
    {
        model.pptslide = 1;
    }
    [filedata bm_setInteger:model.pptslide forKey:@"pptslide"];
    
    if (!model.pptstep)
    {
        model.pptstep = 0;
    }
    [filedata bm_setInteger:model.pptstep forKey:@"pptstep"];
    
    if (model.steptotal)
    {
        [filedata bm_setInteger:model.steptotal forKey:@"steptotal"];
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

    self.currentPage--;
    if (self.currentPage < 1)
    {
        self.currentPage = 1;
        return;
    }
    
    NSMutableDictionary *filedata = [NSMutableDictionary dictionaryWithDictionary:[self.drawViewManager.fileDictionary objectForKey:@"filedata"]];
    [filedata setObject:@(self.currentPage) forKey:@"currpage"];
    [filedata setObject:@(self.totalPage) forKey:@"pagenum"];
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
            self.currentPage++;
            if (self.currentPage > self.totalPage)
            {
                if ([YSWhiteBoardManager shareInstance].isBeginClass)
                {
                    NSMutableDictionary *filedata = [NSMutableDictionary dictionaryWithDictionary:[self.drawViewManager.fileDictionary objectForKey:@"filedata"]];
                    [filedata setObject:@(self.currentPage) forKey:@"currpage"];
                    [filedata setObject:@(self.currentPage) forKey:@"pagenum"];
                    [self.drawViewManager.fileDictionary setObject:filedata forKey:@"filedata"];
                    
                    // 白板加页需发送
                    NSDictionary *fileDic = @{ @"totalPage" : @(self.currentPage),
                                               @"fileid" : @(0),
                                               @"sourceInstanceId" : YSDefaultWhiteBoardId };
                    NSString *json = [fileDic bm_toJSON];
//                    NSString *json = [YSRoomUtil jsonStringWithDictionary:@{@"totalPage":@(self.currentPage),
//                                                                      @"fileid":@(0),
//                                                                      @"sourceInstanceId":YSDefaultWhiteBoardId
//                                                                      }];
                    [[YSRoomInterface instance] pubMsg:sYSSignalWBPageCount msgID:sYSSignalWBPageCount toID:YSRoomPubMsgTellAll data:json save:YES completion:nil];
                }
                else
                {
                    self.currentPage--;
                    return;
                }
            }
            else
            {
                NSMutableDictionary *filedata = [NSMutableDictionary dictionaryWithDictionary:[self.drawViewManager.fileDictionary objectForKey:@"filedata"]];
                [filedata setObject:@(self.currentPage) forKey:@"currpage"];
                [filedata setObject:@(self.totalPage) forKey:@"pagenum"];
                [self.drawViewManager.fileDictionary setObject:filedata forKey:@"filedata"];
            }
        }
        else if ([YSRoomInterface instance].localUser.role == YSUserType_Student)
        {
            // 学生不加页
            self.currentPage++;
            if (self.currentPage <= self.totalPage)
            {
                NSMutableDictionary *filedata = [NSMutableDictionary dictionaryWithDictionary:[self.drawViewManager.fileDictionary objectForKey:@"filedata"]];
                [filedata setObject:@(self.currentPage) forKey:@"currpage"];
                [filedata setObject:@(self.totalPage) forKey:@"pagenum"];
                [self.drawViewManager.fileDictionary setObject:filedata forKey:@"filedata"];
            }
            else
            {
                self.currentPage--;
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

        self.currentPage++;
        if (self.currentPage > self.totalPage)
        {
            self.currentPage = self.totalPage;
            return;
        }
    
        NSMutableDictionary *filedata = [NSMutableDictionary dictionaryWithDictionary:[self.drawViewManager.fileDictionary objectForKey:@"filedata"]];
        [filedata setObject:@(self.currentPage) forKey:@"currpage"];
        [self.drawViewManager.fileDictionary setObject:filedata forKey:@"filedata"];
        
        [self showPageWithDictionary:self.drawViewManager.fileDictionary];
    }
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

        NSString *sourceInstanceId = self.whiteBoardId;
        NSDictionary *dic = [YSFileModel fileDataDocDic:file currentPage:pageNum sourceInstanceId:sourceInstanceId];

        NSMutableDictionary *dic1 = [NSMutableDictionary dictionaryWithDictionary:dic];
        [dic1 bm_setBool:YES forKey:@"initiative"];
        dic = dic1;

        if ([[YSWhiteBoardManager shareInstance] isOneWhiteBoardView])
        {
            NSDictionary *tParamDicDefault = @{
                                               @"id":sYSSignalDocumentFilePage_ShowPage,
                                               @"ts":@(0),
                                               @"data":dic ? dic : [NSNull null],
                                               @"name":sYSSignalShowPage
                                               };
            [self.webViewManager sendSignalMessageToJS:WBPubMsg message:tParamDicDefault];
        }
        else
        {
            NSString *msgID = [NSString stringWithFormat:@"%@%@", sYSSignalDocumentFilePage_ExtendShowPage, self.whiteBoardId];
            NSDictionary *tParamDicDefault = @{
                                               @"id":msgID,
                                               @"ts":@(0),
                                               @"data":dic ? dic : [NSNull null],
                                               @"name":sYSSignalExtendShowPage
                                               };
            [self.webViewManager sendSignalMessageToJS:WBPubMsg message:tParamDicDefault];
        }

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
        self.currentPage = pageNum;
        
        NSMutableDictionary *filedata = [NSMutableDictionary dictionaryWithDictionary:[self.drawViewManager.fileDictionary objectForKey:@"filedata"]];
        [filedata setObject:@(self.currentPage) forKey:@"currpage"];
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
//    if (self.drawViewManager.showOnWeb)
//    {
//        [self enlargeWhiteboard];
//    }
//    else
    {
        [self.drawViewManager enlarge];
    }
}

/// 白板 缩小
- (void)whiteBoardNarrow
{
//    if (self.drawViewManager.showOnWeb)
//    {
//        [self narrowWhiteboard];
//    }
//    else
    {

        [self.drawViewManager narrow];
    }
}

/// 白板 放大重置
- (void)whiteBoardResetEnlarge
{
    if (!self.drawViewManager.showOnWeb)
    {
        [self.drawViewManager resetEnlargeValue:YSWHITEBOARD_MINZOOMSCALE animated:YES];
    }
}

- (void)changeFileId:(NSString *)fileId
{
    self.fileId = fileId;
    self.pageControlView.fileId = fileId;
}

/// 当前页码
- (void)changeCurrentPage:(NSUInteger)currentPage
{
    self.currentPage = currentPage;
}

/// 总页码
- (void)changeTotalPage:(NSUInteger)totalPage
{
    self.totalPage = totalPage;
}

/// 缩放变更回调
- (void)onWhiteBoardFileViewZoomScaleChanged:(CGFloat)zoomScale
{
    [self.pageControlView changeZoomScale:zoomScale];
    
    if (self.delegate &&
        [self.delegate
            respondsToSelector:@selector(onWWBViewDrawViewManagerZoomScaleChanged:zoomScale:)])
    {
        [self.delegate
         onWWBViewDrawViewManagerZoomScaleChanged:self zoomScale:zoomScale];
    }
}


#pragma -
#pragma mark 画笔控制

- (void)brushToolsDidSelect:(YSBrushToolType)BrushToolType
{
    if (self.drawViewManager)
    {
        [self.drawViewManager brushToolsDidSelect:(YSNativeToolType)BrushToolType fromRemote:NO];
        
        YSBrushToolsConfigs *currentConfig = [YSBrushToolsManager shareInstance].currentConfig;
        [self.drawViewManager didSelectDrawType:currentConfig.drawType color:currentConfig.colorHex widthProgress:currentConfig.progress];
    }
}

- (void)didSelectDrawType:(YSDrawType)type color:(NSString *)hexColor widthProgress:(CGFloat)progress
{
    if (self.drawViewManager)
    {
        [self.drawViewManager didSelectDrawType:type color:hexColor widthProgress:progress];
    }
}

- (void)freshBrushToolConfigs
{
    if (self.drawViewManager)
    {
        YSBrushToolsConfigs *currentConfig = [YSBrushToolsManager shareInstance].currentConfig;
        [self.drawViewManager didSelectDrawType:currentConfig.drawType color:currentConfig.colorHex widthProgress:currentConfig.progress];
    }
}

- (void)refreshWebWhiteBoard
{
    [self.webViewManager refreshWhiteBoardWithFrame:self.whiteBoardContentView.bounds];
}


#pragma -
#pragma mark 视频控制

- (void)setMediaStream:(NSTimeInterval)duration pos:(NSTimeInterval)pos isPlay:(BOOL)isPlay fileName:(nonnull NSString *)fileName
{
    if ([[YSWhiteBoardManager shareInstance] isCanControlWhiteBoardView])
    {
        if (self.mediaType == YSWhiteBordMediaType_Audio)
        {
            [self.mp3ControlView bm_bringToFront];
            [self.mp3ControlView setMediaStream:duration pos:pos isPlay:isPlay fileName:[YSWhiteBoardManager shareInstance].mediaFileModel.filename];
        }
        else
        {
            [self.mp4ControlView bm_bringToFront];
            [self.mp4ControlView setMediaStream:duration pos:pos isPlay:isPlay fileName:fileName];
        }
    }
    else
    {
        if (isPlay)
        {
            [self.playMp3ImageView bm_bringToFront];
            self.playMp3ImageView.hidden = NO;
            [self.playMp3ImageView startAnimating];
        }
        else
        {
            [self.playMp3ImageView stopAnimating];
        }
    }
}


#pragma mark 拖拽右下角缩放View

- (void)panGestureToZoomView:(UIPanGestureRecognizer *)pan
{
    if (self.pageControlView.isAllScreen)
    {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(panToZoomWhiteBoardView:withGestureRecognizer:)])
    {
        [self.delegate panToZoomWhiteBoardView:self withGestureRecognizer:pan];
    }
}

- (void)dragPageControlView:(UIPanGestureRecognizer *)pan
{
    UIView *dragView = pan.view;
    if (pan.state == UIGestureRecognizerStateBegan)
    {
        
    }
    else if (pan.state == UIGestureRecognizerStateChanged)
    {
        CGPoint location = [pan locationInView:self];
        
        if (location.y < self.topBar.bm_height || location.y > self.bm_height)
        {
            return;
        }
        
        CGPoint translation = [pan translationInView:self];
        
        dragView.center = CGPointMake(dragView.center.x + translation.x, dragView.center.y + translation.y);
        [pan setTranslation:CGPointZero inView:self];
    }
    else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled)
    {
        CGRect currentFrame = dragView.frame;//self.chatBtn.frame;
        
        if (currentFrame.origin.x < 0) {
            
            currentFrame.origin.x = 0;
            if (currentFrame.origin.y < self.topBar.bm_height)
            {
                currentFrame.origin.y = self.topBar.bm_height + 4;
            }
            else if ((currentFrame.origin.y + currentFrame.size.height) > self.bounds.size.height)
            {
                currentFrame.origin.y = self.bounds.size.height - currentFrame.size.height;
            }
            [UIView animateWithDuration:BMDEFAULT_DELAY_TIME animations:^{
                dragView.frame = currentFrame;
            }];
            
            return;
        }
        
        if ((currentFrame.origin.x + currentFrame.size.width) > self.bounds.size.width)
        {
            currentFrame.origin.x = self.bounds.size.width - currentFrame.size.width;
            if (currentFrame.origin.y < self.topBar.bm_height)
            {
                currentFrame.origin.y = self.topBar.bm_height + 4;
            }
            else if ((currentFrame.origin.y + currentFrame.size.height) > self.bounds.size.height)
            {
                currentFrame.origin.y = self.bounds.size.height - currentFrame.size.height;
            }
            [UIView animateWithDuration:BMDEFAULT_DELAY_TIME animations:^{
                dragView.frame = currentFrame;
            }];
            
            return;
        }
        
        if (currentFrame.origin.y < self.topBar.bm_height)
        {
            currentFrame.origin.y = self.topBar.bm_height + 4;
            [UIView animateWithDuration:BMDEFAULT_DELAY_TIME animations:^{
                dragView.frame = currentFrame;
            }];
            return;
        }
        
        if ((currentFrame.origin.y + currentFrame.size.height) > self.bounds.size.height)
        {
            currentFrame.origin.y = self.bounds.size.height - currentFrame.size.height;
            [UIView animateWithDuration:BMDEFAULT_DELAY_TIME animations:^{
                dragView.frame = currentFrame;
            }];
            
            return;
        }
    }
}

- (void)collectButtonsClick:(UIButton *)sender
{
//    NSArray * coursewareViewList = [YSWhiteBoardManager shareInstance].coursewareViewList;
    
    NSArray *arrangeList = [[YSWhiteBoardManager shareInstance] getWhiteBoardViewArrangeList];
    
    if (sender.selected)
    {
        BOOL isHidden = NO;
        for (int i = 0; i<arrangeList.count; i++)
        {
            YSWhiteBoardView * whiteBoardView = arrangeList[i];
            if (!whiteBoardView.hidden)
            {
                NSString * msgID = [NSString stringWithFormat:@"MoreWhiteboardState_%@", whiteBoardView.whiteBoardId];
                
                NSDictionary * data = @{@"x":@0,@"y":@0,@"width":@1,@"height":@1,@"small":@YES,@"full":@NO,@"type":@"small",@"instanceId":whiteBoardView.whiteBoardId};
                NSString * associatedMsgID = [NSString stringWithFormat:@"DocumentFilePage_ExtendShowPage_%@", whiteBoardView.whiteBoardId];
                
                [YSRoomUtil pubWhiteBoardMsg:sYSSignalMoreWhiteboardState msgID:msgID data:data extensionData:nil associatedMsgID:associatedMsgID expires:0 completion:nil];
                
                isHidden = YES;
            }
        }
        
        if (!isHidden)
        {
            for (YSWhiteBoardView * whiteBoardView in arrangeList)
            {
                // x,y值在主白板上的比例
                CGFloat scaleLeft = [whiteBoardView.positionData bm_floatForKey:@"x"];
                CGFloat scaleTop = [whiteBoardView.positionData bm_floatForKey:@"y"];
                
                // 宽，高值在主白板上的比例
                CGFloat scaleWidth = [whiteBoardView.positionData bm_floatForKey:@"width"];
                CGFloat scaleHeight = [whiteBoardView.positionData bm_floatForKey:@"height"];
                
                NSString * msgID = [NSString stringWithFormat:@"MoreWhiteboardState_%@", whiteBoardView.whiteBoardId];
                NSDictionary * data = @{@"x":@(scaleLeft),@"y":@(scaleTop),@"width":@(scaleWidth),@"height":@(scaleHeight),@"small":@NO,@"full":@NO,@"type":@"small",@"instanceId":whiteBoardView.whiteBoardId};
                NSString * associatedMsgID = [NSString stringWithFormat:@"DocumentFilePage_ExtendShowPage_%@", whiteBoardView.whiteBoardId];
                
                [YSRoomUtil pubWhiteBoardMsg:sYSSignalMoreWhiteboardState msgID:msgID data:data extensionData:nil associatedMsgID:associatedMsgID expires:0 completion:nil];
            }
            sender.selected = NO;
        }
    }
    else
    {
        for (YSWhiteBoardView * whiteBoardView in arrangeList)
        {
            NSString * msgID = [NSString stringWithFormat:@"MoreWhiteboardState_%@", whiteBoardView.whiteBoardId];
            NSDictionary * data = @{@"x":@0,@"y":@0,@"width":@1,@"height":@1,@"small":@YES,@"full":@NO,@"type":@"small",@"instanceId":whiteBoardView.whiteBoardId};
            NSString * associatedMsgID = [NSString stringWithFormat:@"DocumentFilePage_ExtendShowPage_%@", whiteBoardView.whiteBoardId];
            
            [YSRoomUtil pubWhiteBoardMsg:sYSSignalMoreWhiteboardState msgID:msgID data:data extensionData:nil associatedMsgID:associatedMsgID expires:0 completion:nil];
        }
        sender.selected = YES;
    }
}

#pragma mark - 小白板的topbar上的按钮点击事件

- (void)topBarButtonClick:(UIButton *)sender
{
    switch (sender.tag) {
        case 1:
        {//最小化
            
            YSWhiteBoardView * mainWhiteBoard = (YSWhiteBoardView *)self.superview;
            mainWhiteBoard.collectBtn.selected = YES;
            
            NSString * msgID = [NSString stringWithFormat:@"MoreWhiteboardState_%@", self.whiteBoardId];
            NSDictionary * data = @{@"x":@0,@"y":@0,@"width":@1,@"height":@1,@"small":@YES,@"full":@NO,@"type":@"small",@"instanceId":self.whiteBoardId};
            NSString * associatedMsgID = [NSString stringWithFormat:@"DocumentFilePage_ExtendShowPage_%@", self.whiteBoardId];
            
            [YSRoomUtil pubWhiteBoardMsg:sYSSignalMoreWhiteboardState msgID:msgID data:data extensionData:nil associatedMsgID:associatedMsgID expires:0 completion:nil];
        }
            break;
        case 2:
        {//全屏
            // ====  信令  ====
            NSString * msgID = [NSString stringWithFormat:@"MoreWhiteboardState_%@", self.whiteBoardId];
            
            //x,y值在主白板上的比例
            CGFloat scaleLeft = [self.positionData bm_floatForKey:@"x"];
            CGFloat scaleTop = [self.positionData bm_floatForKey:@"y"];
            
            //宽，高值在主白板上的比例
            CGFloat scaleWidth = [self.positionData bm_floatForKey:@"width"];
            CGFloat scaleHeight = [self.positionData bm_floatForKey:@"height"];
            
            
            NSDictionary * data = @{@"x":@(scaleLeft),@"y":@(scaleTop),@"width":@(scaleWidth),@"height":@(scaleHeight),@"small":@NO,@"full":@YES,@"type":@"full",@"instanceId":self.whiteBoardId};
            NSString * associatedMsgID = [NSString stringWithFormat:@"DocumentFilePage_ExtendShowPage_%@", self.whiteBoardId];
            
            [YSRoomUtil pubWhiteBoardMsg:sYSSignalMoreWhiteboardState msgID:msgID data:data extensionData:nil associatedMsgID:associatedMsgID expires:0 completion:nil];
        }
            break;
        case 3:
        {//删除按钮
            [self deleteWhiteBoardView];
        }
            break;
        default:
            break;
    }
}


#pragma mark YSCoursewareControlViewDelegate

/// 刷新课件
- (void)coursewareFrashBtnClick
{
    [self freshCurrentCourse];
}

/// 全屏 复原 回调
- (void)coursewarefullScreen:(BOOL)isAllScreen
{
    if ([self.delegate respondsToSelector:@selector(onWBViewFullScreen:wbView:)])
    {
        // 课件全屏
        [self bm_bringToFront];
        [self.delegate onWBViewFullScreen:isAllScreen wbView:self];
    }
}

/// 上一页
- (void)coursewareTurnToPreviousPage
{
    [self whiteBoardPrePage];
}

/// 下一页
- (void)coursewareTurnToNextPage
{
    [self whiteBoardNextPage];
}

/// 放大
- (void)coursewareToEnlarge
{
    [self whiteBoardEnlarge];
}

/// 缩小
- (void)coursewareToNarrow
{
    [self whiteBoardNarrow];
}

#pragma mark YSWhiteBoardControlViewDelegate

/// 由全屏还原的按钮
- (void)whiteBoardfullScreenReturn
{
    NSDictionary * dict = self.positionData;
    //====  信令  ====
    // x,y值在主白板上的比例
    CGFloat scaleLeft = [dict bm_floatForKey:@"x"];
    CGFloat scaleTop = [dict bm_floatForKey:@"y"];
    
    // 宽，高值在主白板上的比例
    CGFloat scaleWidth = [dict bm_floatForKey:@"width"];
    CGFloat scaleHeight = [dict bm_floatForKey:@"height"];
    
    NSString *msgID = [NSString stringWithFormat:@"MoreWhiteboardState_%@", self.whiteBoardId];
    NSDictionary *data = @{@"x":@(scaleLeft),@"y":@(scaleTop),@"width":@(scaleWidth),@"height":@(scaleHeight),@"small":@NO,@"full":@NO,@"type":@"full",@"instanceId":self.whiteBoardId};
    NSString *associatedMsgID = [NSString stringWithFormat:@"DocumentFilePage_ExtendShowPage_%@", self.whiteBoardId];
    
    [YSRoomUtil pubWhiteBoardMsg:sYSSignalMoreWhiteboardState msgID:msgID data:data extensionData:nil associatedMsgID:associatedMsgID expires:0 completion:nil];
}

/// 删除按钮
- (void)deleteWhiteBoardView
{
    if ([YSWhiteBoardManager shareInstance].isBeginClass)
    {
        if (self.isMediaView)
        {
            [[YSRoomInterface instance] stopShareMediaFile:nil];
        }
        else
        {
            if (self.isH5LoadMedia)
            {
                [[YSRoomInterface instance] stopShareMediaFile:nil];
            }
            
            NSString *msgID = [NSString stringWithFormat:@"%@%@", sYSSignalDocumentFilePage_ExtendShowPage, self.whiteBoardId];
            NSDictionary *data = @{@"sourceInstanceId" : self.whiteBoardId};
            [YSRoomUtil delWhiteBoardMsg:sYSSignalExtendShowPage msgID:msgID data:data completion:nil];
        }
    }
    else
    {
        if (self.isMediaView)
        {
            [[YSRoomInterface instance] stopShareMediaFile:nil];
        }
        else
        {
            if (self.isH5LoadMedia)
            {
                [[YSRoomInterface instance] stopShareMediaFile:nil];
            }
            
            [[YSWhiteBoardManager shareInstance] removeWhiteBoardViewWithWhiteBoardView:self];
        }
    }
}


#pragma -
#pragma mark 白板视频标注

/// 显示白板视频标注
- (void)showVideoWhiteboardWithData:(NSDictionary *)data videoRatio:(CGFloat)videoRatio
{
    if (self.mediaMarkView.superview)
    {
        [self.mediaMarkView removeFromSuperview];
        self.mediaMarkView = nil;
    }
    
    self.mediaMarkView = [[YSWBMediaMarkView alloc] initWithFrame:CGRectMake(0, YSTopViewHeight, self.bounds.size.width, self.bounds.size.height-YSTopViewHeight)];
    [self addSubview:self.mediaMarkView];
    self.mediaMarkView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UITapGestureRecognizer *oneTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeToCurrentBWView:)];
    oneTap.numberOfTapsRequired = 1;
    [self.mediaMarkView addGestureRecognizer:oneTap];
    [self.mp4ControlView bm_bringToFront];

    [self.mediaMarkView freshViewWithSavedSharpsData:self.mediaMarkSharpsDatas videoRatio:videoRatio];
    [self.mediaMarkSharpsDatas removeAllObjects];
}

/// 绘制白板视频标注
- (void)drawVideoWhiteboardWithData:(NSDictionary *)data inList:(BOOL)inlist
{
    if (inlist)
    {
        [self.mediaMarkSharpsDatas addObject:data];
    }
    else
    {
        [self.mediaMarkView freshViewWithData:data savedSharpsData:self.mediaMarkSharpsDatas];
        [self.mediaMarkSharpsDatas removeAllObjects];
    }
}

/// 隐藏白板视频标注
- (void)hideVideoWhiteboard
{
    [self.mediaMarkSharpsDatas removeAllObjects];
    if (self.mediaMarkView.superview)
    {
        [self.mediaMarkView removeFromSuperview];
        self.mediaMarkView = nil;
    }
}

/// 清除白板视频标注
- (void)clearDrawVideoMark
{
    if (![YSWhiteBoardManager shareInstance].isBeginClass)
    {
        return;
    }

    YSRoomUser *localUser = [YSRoomInterface instance].localUser;
    if (localUser.role != YSUserType_Teacher)
    {
        return;
    }
    
    [self.mediaMarkView clearDrawVideoMark];
}


#pragma -
#pragma mark 白板H5课件参数设置

/// 变更H5课件地址参数，此方法会刷新当前H5课件以变更新参数
- (void)changeConnectH5CoursewareUrlParameters:(NSDictionary *)parameters
{
    if (!self.loadingH5Fished)
    {
        NSLog(@"===================cacheMsgPool userPropertyChanged");
        
        NSString *methodName = NSStringFromSelector(@selector(changeConnectH5CoursewareUrlParameters:));
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setValue:methodName forKey:kYSMethodNameKey];
        [dic setValue:@[parameters] forKey:kYSParameterKey];
        [self.cacheMsgPool addObject:dic];
        
        return;
    }

    NSString *code = @"setDocParams";
    NSString *parametersJson = [parameters bm_toJSON];
    if (!parametersJson)
    {
        parametersJson = @"";
    }
    NSString *data = [NSString stringWithFormat:@"%@", parametersJson];
    NSString *jsString = [NSString stringWithFormat:@"JsSocket.%@(%@, true)", code, data];
    
    if (self.webViewManager)
    {
        [self.webViewManager sendMessageToJS:jsString];
    }
}

/// 设置H5课件Cookies
- (void)setConnectH5CoursewareUrlCookies:(nullable NSArray <NSDictionary *> *)cookies
{
    _connectH5CoursewareUrlCookies = [NSArray arrayWithArray:cookies];
}

@end
