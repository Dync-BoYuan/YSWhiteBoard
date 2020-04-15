//
//  YSWBDrawViewManager.m
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/22.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import "YSWBDrawViewManager.h"
#import "DocShowView.h"
#import "DrawView.h"
#import "LaserPan.h"

NSString *const YSWhiteBoardRemoteSelectTool = @"YSWhiteBoardRemoteSelectTool"; //远程选择

@interface YSWBDrawViewManager ()
<
    UIGestureRecognizerDelegate,
    DocShowViewZoomScaleDelegate
>
{
    NSUInteger total0Page;
    
    /// 获取数据
    BOOL hasRecoveried;

    /// 自己发送的数据
    BOOL sendFromSelf;
}
/// 承载View
@property (nonatomic, weak) UIView *contentView;

/// web课件通过YSWBWebViewManager创建的webView
@property (nonatomic, weak) WKWebView *wkWebView;
/// 普通课件视图
@property (nonatomic, strong) DocShowView *fileView;

/// 激光笔
@property (nonatomic, strong) LaserPan *laserPan;


@property (nonatomic, strong) NSMutableDictionary *wbToolConfigs;
@property (nonatomic, strong) NSString *defaultPrimaryColor;

/// 当前fileId
@property (nonatomic, strong) NSString *fileId;

/// 当前页码
//@property (nonatomic, assign) NSInteger currentPage;
/// 总页码
@property (nonatomic, assign) NSInteger pagecount;

/// 课件使用 webView 加载
@property (nonatomic, assign) BOOL showOnWeb;

/// 记录刚进入教室 老师的画笔状态，是否使用选取工具
@property (nonatomic, assign) BOOL selectMouse;

/// 课件比例
@property (nonatomic, assign) CGFloat ratio;
@property (nonatomic, assign) CGFloat h5Ratio;
/// 课件缩放比例
@property (nonatomic, assign) CGFloat currentScale;


@end

@implementation YSWBDrawViewManager

- (instancetype)initWithBackView:(UIView *)view webView:(WKWebView *)webView
{
    self = [super init];

    if (self)
    {
        self.contentView = view;
        self.wkWebView = webView;
        
        self.showOnWeb = NO;
        self.selectMouse = YES;
        
        self.fileId = @"0";
        self.currentPage = 1;
        
        self.address = [YSWhiteBoardManager shareInstance].serverDocAddrKey;

        // 创建主白板
        self.fileView = [[DocShowView alloc] init];
        self.fileView.backgroundColor = [UIColor clearColor];
        self.fileView.hidden = YES;
        self.fileView.zoomDelegate = self;
        [self.contentView addSubview:self.fileView];
        
        [self.fileView bmmas_makeConstraints:^(BMMASConstraintMaker *make) {
            make.left.bmmas_equalTo(self.contentView.bmmas_left);
            make.right.bmmas_equalTo(self.contentView.bmmas_right);
            make.top.bmmas_equalTo(self.contentView.bmmas_top);
            make.bottom.bmmas_equalTo(self.contentView.bmmas_bottom);
        }];

        // 监听_contentView.frame更新布局
        [self.contentView addObserver:self
                       forKeyPath:@"frame"
                          options:NSKeyValueObservingOptionNew
                          context:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(remoteSelectorTool:)
                                                     name:YSWhiteBoardRemoteSelectTool
                                                   object:nil];


        [self makeWbToolConfigs];
        
        [view setNeedsLayout];
        [view layoutIfNeeded];
    }

    return self;
}

/// 变更fileView背景色
- (void)changeFileViewBackgroudColor:(UIColor *)color
{
    self.fileView.userSetWhiteBoardColor = color;
}

- (void)setAddress:(NSString *)address
{
    _address = address;
    if (self.fileDictionary)
    {
        [self drawOnView:self.fileView.ysDrawView.drawView
                     withData:self.fileDictionary
            updateImmediately:YES];
    }
}

#pragma mark - WbToolConfigs

- (void)makeWbToolConfigs
{
    // 默认颜色 红
    self.defaultPrimaryColor = @"#FF0000";
    [self freshWbToolConfigs];
}

- (void)freshWbToolConfigs
{
    self.wbToolConfigs = [[NSMutableDictionary alloc] init];
    
    // 画笔
    NSDictionary *toolTypeLineConfig = @{ @"drawType" : @(YSDrawTypePen),
                                          @"colorHex" : @"",
                                          @"progress" : @(0.03f) };
    [self.wbToolConfigs setObject:toolTypeLineConfig forKey:@(YSNativeToolTypeLine)];
    
    // 文本
    NSDictionary *toolTypeTextConfig = @{ @"drawType" : @(YSDrawTypeTextMS),
                                          @"colorHex" : @"",
                                          @"progress" : @(0.3f) };
    [self.wbToolConfigs setObject:toolTypeTextConfig forKey:@(YSNativeToolTypeText)];
    
    // 形状
    NSDictionary *toolTypeSharpConfig = @{ @"drawType" : @(YSDrawTypeEmptyRectangle),
                                           @"colorHex" : @"",
                                           @"progress" : @(0.03f) };
    [self.wbToolConfigs setObject:toolTypeSharpConfig forKey:@(YSNativeToolTypeShape)];
    
    // 橡皮
    NSDictionary *toolTypeEraserConfig = @{ @"drawType" : @(YSDrawTypeEraser),
                                            @"colorHex" : @"",
                                            @"progress" : @(0.03f) };
    [self.wbToolConfigs setObject:toolTypeEraserConfig forKey:@(YSNativeToolTypeEraser)];
}

- (void)changeDefaultPrimaryColor:(NSString *)colorHex
{
    NSMutableArray *colorMuArr = [NSMutableArray arrayWithObjects:
                                  @"#000000", @"#9B9B9B", @"#FFFFFF", @"#FF87A3", @"#FF515F", @"#FF0000",
                                  @"#E18838", @"#AC6B00", @"#864706", @"#FF7E0B", @"#FFD33B", @"#FFF52B",
                                  @"#B3D330", @"#88BA44", @"#56A648", @"#53B1A4", @"#68C1FF", @"#058CE5",
                                  @"#0B48FF", @"#C1C7FF", @"#D25FFA", @"#6E3087", @"#3D2484", @"#142473", nil];
    
    NSUInteger index = [colorMuArr indexOfObject:colorHex];
    if (index != NSNotFound)
    {
        self.defaultPrimaryColor = colorHex;
    }
}

- (NSDictionary *)getWbToolConfigWithToolType:(YSNativeToolType)type
{
    NSDictionary *dic = self.wbToolConfigs[@(type)];
    NSMutableDictionary *configDic = [NSMutableDictionary dictionaryWithDictionary:dic];
    NSString *colorHex = [configDic bm_stringForKey:@"colorHex"];
    if (![colorHex bm_isNotEmpty])
    {
        [configDic setObject:self.defaultPrimaryColor forKey:@"colorHex"];
    }
    
    return configDic;
}

- (void)changeWbToolConfigWithToolType:(YSNativeToolType)type drawType:(YSDrawType)drawType color:(NSString *)hexColor progress:(float)progress
{
    if (![hexColor bm_isNotEmpty])
    {
        hexColor = self.defaultPrimaryColor;
    }
    
    switch (type)
    {
        case YSNativeToolTypeLine:
        {
            NSDictionary *dic = self.wbToolConfigs[@(YSNativeToolTypeLine)];
            NSMutableDictionary *configDic = [NSMutableDictionary dictionaryWithDictionary:dic];
            [configDic setObject:@(drawType) forKey:@"drawType"];
            [configDic setObject:hexColor forKey:@"colorHex"];
            [configDic setObject:@(progress) forKey:@"progress"];
            [self.wbToolConfigs setObject:configDic forKey:@(YSNativeToolTypeLine)];
            break;
        }
        case YSNativeToolTypeText:
        {
            NSDictionary *dic = self.wbToolConfigs[@(YSNativeToolTypeText)];
            NSMutableDictionary *configDic = [NSMutableDictionary dictionaryWithDictionary:dic];
            [configDic setObject:@(drawType) forKey:@"drawType"];
            [configDic setObject:hexColor forKey:@"colorHex"];
            [configDic setObject:@(progress) forKey:@"progress"];
            [self.wbToolConfigs setObject:configDic forKey:@(YSNativeToolTypeText)];
        }
            break;
        case YSNativeToolTypeShape:
        {
            NSDictionary *dic = self.wbToolConfigs[@(YSNativeToolTypeShape)];
            NSMutableDictionary *configDic = [NSMutableDictionary dictionaryWithDictionary:dic];
            [configDic setObject:@(drawType) forKey:@"drawType"];
            [configDic setObject:hexColor forKey:@"colorHex"];
            [configDic setObject:@(progress) forKey:@"progress"];
            [self.wbToolConfigs setObject:configDic forKey:@(YSNativeToolTypeShape)];
        }
            break;
        case YSNativeToolTypeEraser:
        {
            NSDictionary *dic = self.wbToolConfigs[@(YSNativeToolTypeEraser)];
            NSMutableDictionary *configDic = [NSMutableDictionary dictionaryWithDictionary:dic];
            [configDic setObject:@(drawType) forKey:@"drawType"];
            [configDic setObject:@"" forKey:@"colorHex"];
            [configDic setObject:@(progress) forKey:@"progress"];
            [self.wbToolConfigs setObject:configDic forKey:@(YSNativeToolTypeEraser)];
        }
            break;
        default:
            break;
    }
}

- (void)remoteSelectorTool:(NSNotification *)noti
{
    // 有穿透画笔配置项不隐藏画布(笔迹) 并响应动态课件事件
    if ([YSWhiteBoardManager shareInstance].roomConfig.isPenCanPenetration == YES)
    {
        self.fileView.isPenetration = self.showOnWeb && self.selectMouse;
    }
    else
    {
        // 是否点选鼠标
        if (self.showOnWeb)
        {
            self.fileView.hidden = [noti.object boolValue];
        }
        else
        {
            if ([self.fileId isEqualToString:@"0"])
            {
                self.fileView.ysDrawView.drawView.hidden = NO;
            }
            else
            {
                self.fileView.ysDrawView.drawView.hidden = [noti.object boolValue];
            }
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"frame"])
    {
        if (self.fileView.zoomScale > YSWHITEBOARD_MINZOOMSCALE)
        {
            float zoomScale = self.fileView.zoomScale;
            CGPoint offset = self.fileView.contentOffset;
            
            [self resetEnlargeValue:YSWHITEBOARD_MINZOOMSCALE animated:NO];
            
            [self.fileView setContentOffset:CGPointZero];
            [self updateWBRatio:self.ratio];
            [self.fileView setNeedsLayout];
            [self.fileView layoutIfNeeded];
            
            [self resetEnlargeValue:zoomScale animated:NO];
            
            if (offset.x < 0)
            {
                offset.x = 0;
            }
            if (offset.x > (self.fileView.contentSize.width - self.fileView.frame.size.width))
            {
                offset.x = (self.fileView.contentSize.width - self.fileView.frame.size.width);
            }
            if (offset.y < 0)
            {
                offset.y = 0;
            }
            if (offset.y > (self.fileView.contentSize.height - self.fileView.frame.size.height))
            {
                offset.y = (self.fileView.contentSize.height - self.fileView.frame.size.height);
            }
            [self.fileView setContentOffset:offset];
        }
        else
        {
            [self updateWBRatio:self.ratio];
            [self.fileView setNeedsLayout];
            [self.fileView layoutIfNeeded];
        }
    }
}

- (void)setShowOnWeb:(BOOL)showOnWeb
{
    _showOnWeb = showOnWeb;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0)
    {
        if (showOnWeb)
        {
            self.fileView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        else
        {
            self.fileView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
        }
    }

    [self setDragFileEnabled:self.selectMouse];
}

- (void)updateWBRatio:(CGFloat)ratio
{
    if (ratio == 0)
    {
        return;
    }

    if (self.fileId.integerValue == 0)
    {
        //避免image，pdf延迟加载影响白板比例
        ratio = 16.0f / 9;
    }
    
    self.ratio = ratio;
    
    if (self.showOnWeb)
    {
        self.h5Ratio = ratio;
    }

    [self.fileView.underView bmmas_remakeConstraints:^(BMMASConstraintMaker *make) {
        make.left.bmmas_equalTo(self.fileView.bmmas_left);
        make.right.bmmas_equalTo(self.fileView.bmmas_right);
        make.top.bmmas_equalTo(self.fileView.bmmas_top);
        make.bottom.bmmas_equalTo(self.fileView.bmmas_bottom);
        make.width.bmmas_equalTo(self.contentView.bmmas_width);
        make.height.bmmas_equalTo(self.contentView.bmmas_height);
    }];

    // 显示图片
    if (!self.fileView.imageView.hidden) {
        if (self.ratio >= self.contentView.frame.size.width / self.contentView.frame.size.height) {
            //矮长型图片
            [self.fileView.displayView bmmas_remakeConstraints:^(BMMASConstraintMaker *make) {
                make.width.bmmas_equalTo(self.fileView.bmmas_width);
                make.height.bmmas_equalTo(self.fileView.bmmas_width).multipliedBy(1 / self.ratio);
                make.centerY.bmmas_equalTo(self.fileView.underView.bmmas_centerY);
                make.centerX.bmmas_equalTo(self.fileView.underView.bmmas_centerX);
            }];

        } else {
            //高瘦型图片
            [self.fileView.displayView bmmas_remakeConstraints:^(BMMASConstraintMaker *make) {
                make.height.bmmas_equalTo(self.fileView.bmmas_height);
                make.width.bmmas_equalTo(self.fileView.bmmas_height).multipliedBy(self.ratio);
                make.centerX.bmmas_equalTo(self.fileView.underView.bmmas_centerX);
                make.centerY.bmmas_equalTo(self.fileView.underView.bmmas_centerY);
            }];
        }

        return;
    }

    //显示pdf
    if (!self.fileView.pdfView.hidden) {
        if (self.ratio >= self.contentView.frame.size.width / self.contentView.frame.size.height) {
            //矮长型图片
            [self.fileView.displayView bmmas_remakeConstraints:^(BMMASConstraintMaker *make) {
                make.width.bmmas_equalTo(self.fileView.bmmas_width);
                make.height.bmmas_equalTo(self.fileView.bmmas_width).multipliedBy(1 / self.ratio);
                make.centerY.bmmas_equalTo(self.fileView.underView.bmmas_centerY);
                make.centerX.bmmas_equalTo(self.fileView.underView.bmmas_centerX);
            }];

        } else {
            //高瘦型图片
            [self.fileView.displayView bmmas_remakeConstraints:^(BMMASConstraintMaker *make) {
                make.height.bmmas_equalTo(self.fileView.bmmas_height);
                make.width.bmmas_equalTo(self.fileView.bmmas_height).multipliedBy(self.ratio);
                make.centerX.bmmas_equalTo(self.fileView.underView.bmmas_centerX);
                make.centerY.bmmas_equalTo(self.fileView.underView.bmmas_centerY);
            }];
        }

        return;
    }

    //显示纯白板或者web上的画布
    if (self.fileId.intValue == 0) {
        if (self.ratio >= self.contentView.frame.size.width / self.contentView.frame.size.height) {
            [self.fileView.displayView bmmas_remakeConstraints:^(BMMASConstraintMaker *make) {
                make.width.bmmas_equalTo(self.fileView.bmmas_width);
                make.height.bmmas_equalTo(self.fileView.bmmas_width).multipliedBy(1 / self.ratio);
                make.centerY.bmmas_equalTo(self.fileView.underView.bmmas_centerY);
                make.centerX.bmmas_equalTo(self.fileView.underView.bmmas_centerX);
            }];
        } else {
            [self.fileView.displayView bmmas_remakeConstraints:^(BMMASConstraintMaker *make) {
                make.height.bmmas_equalTo(self.fileView.bmmas_height);
                make.width.bmmas_equalTo(self.fileView.bmmas_height).multipliedBy(self.ratio);
                make.centerX.bmmas_equalTo(self.fileView.underView.bmmas_centerX);
                make.centerY.bmmas_equalTo(self.fileView.underView.bmmas_centerY);
            }];
        }
    } else {
        if (self.ratio >= self.fileView.frame.size.width / self.fileView.frame.size.height) {
            [self.fileView.displayView bmmas_remakeConstraints:^(BMMASConstraintMaker *make) {
                make.width.bmmas_equalTo(self.fileView.bmmas_width);
                make.height.bmmas_equalTo(self.fileView.bmmas_width).multipliedBy(1 / self.ratio);
                make.centerY.bmmas_equalTo(self.fileView.underView.bmmas_centerY);
                make.centerX.bmmas_equalTo(self.fileView.underView.bmmas_centerX);
            }];
        } else {
            [self.fileView.displayView bmmas_remakeConstraints:^(BMMASConstraintMaker *make) {
                make.height.bmmas_equalTo(self.fileView.bmmas_height);
                make.width.bmmas_equalTo(self.fileView.bmmas_height).multipliedBy(self.ratio);
                make.centerX.bmmas_equalTo(self.fileView.underView.bmmas_centerX);
                make.centerY.bmmas_equalTo(self.fileView.underView.bmmas_centerY);
            }];
        }
    }
}

// 设置具体放大值
- (void)resetEnlargeValue:(float)value animated:(BOOL)animated
{
    self.currentScale = value;
    //最小缩放系数为1，每级系数为-0.5
    [self setDragFileEnabled:self.selectMouse];
    
    //_fileView.maximumZoomScale = value;
    //_fileView.minimumZoomScale = value;
    
    [self.fileView setZoomScale:value animated:YES];

    if (self.laserPan.superview)
    {
        [self showLaserPen];
    }
}

// MARK: 设置课件可以拖动
- (void)setDragFileEnabled:(BOOL)enable
{
    self.fileView.scrollEnabled = enable;
    if ((([YSRoomInterface instance].localUser.role == YSUserType_Student) && ![YSRoomInterface instance].localUser.canDraw) ||
        ([YSRoomInterface instance].localUser.role == YSUserType_Patrol))
    {
        // 如果学生未授权总是能放大拖动
        self.fileView.scrollEnabled = YES;
    }

    if (self.showOnWeb)
    {
        self.currentScale = YSWHITEBOARD_MINZOOMSCALE;
        [self.fileView setZoomScale:YSWHITEBOARD_MINZOOMSCALE animated:NO];
        self.fileView.maximumZoomScale = YSWHITEBOARD_MINZOOMSCALE;
        self.fileView.minimumZoomScale = YSWHITEBOARD_MINZOOMSCALE;
        return;
    }

    
    if (self.selectMouse)
    {
        // 直播支持手势缩放
        self.fileView.maximumZoomScale = YSWHITEBOARD_MAXZOOMSCALE;
        self.fileView.minimumZoomScale = YSWHITEBOARD_MINZOOMSCALE;
    }
    else
    {
        if ((([YSRoomInterface instance].localUser.role == YSUserType_Student) && ![YSRoomInterface instance].localUser.canDraw))
        {
            self.currentScale = YSWHITEBOARD_MINZOOMSCALE;
            [self.fileView setZoomScale:YSWHITEBOARD_MINZOOMSCALE animated:NO];
            
            self.fileView.maximumZoomScale = YSWHITEBOARD_MINZOOMSCALE;
            self.fileView.minimumZoomScale = YSWHITEBOARD_MINZOOMSCALE;
        }
        
        self.fileView.maximumZoomScale = YSWHITEBOARD_MAXZOOMSCALE;
        self.fileView.minimumZoomScale = YSWHITEBOARD_MINZOOMSCALE;
    }
}

// MARK: 设置工作模式
- (void)setWorkMode:(YSWorkMode)mode
{
    [self.fileView.ysDrawView setWorkMode:mode];
    if (![YSWhiteBoardManager shareInstance].isBeginClass)
    {
        [self.fileView.ysDrawView setWorkMode:YSWorkModeViewer];
    }
}

// 激光笔
- (void)laserPen:(NSDictionary *)dic
{
    NSString *actionName = [dic bm_stringForKey:@"actionName"];

    if ([actionName isEqualToString:sYSSignalActionShow])
    { // 显示
        if (!self.laserPan)
        {
            CGFloat width = BMIS_PAD ? 40. : 20.;
            self.laserPan = [[LaserPan alloc] initWithFrame:CGRectMake(0, 0, width, width)];
        }
    }
    else if ([actionName isEqualToString:@"move"])
    { // 移动
        if (dic[@"laser"][@"top"] && dic[@"laser"][@"left"])
        {
            CGFloat x     = [dic[@"laser"][@"left"] floatValue] / 100.;
            CGFloat y     = [dic[@"laser"][@"top"] floatValue] / 100.;
            CGFloat moveX = CGRectGetWidth(self.fileView.ysDrawView.rtDrawView.frame) * x;
            CGFloat moveY = CGRectGetHeight(self.fileView.ysDrawView.rtDrawView.frame) * y;
            
            self.laserPan.offsetX = moveX;
            self.laserPan.offsetY = moveY;
            
            [self showLaserPen];
        }
    }
    else if ([actionName isEqualToString:@"hide"])
    { // 隐藏
        [self.laserPan removeFromSuperview];
        self.laserPan = nil;
    }
}

- (void)showLaserPen
{
    CGFloat moveX = self.laserPan.offsetX;
    CGFloat moveY = self.laserPan.offsetY;
    CGFloat zoomScale = self.fileView.zoomScale;

    CGFloat offsetX = self.fileView.contentOffset.x;
    CGFloat offsetY = self.fileView.contentOffset.y;
    
    moveX = moveX * zoomScale;
    moveY = moveY * zoomScale;
    moveX = moveX - offsetX;
    moveY = moveY - offsetY;

    CGFloat startX = CGRectGetMinX(self.fileView.displayView.frame);
    CGFloat startY = CGRectGetMinY(self.fileView.displayView.frame);

    if (!self.laserPan.superview)
    {
        [self.contentView addSubview:self.laserPan];
    }
    
    [self.laserPan bmmas_remakeConstraints:^(BMMASConstraintMaker *make) {
        make.left.bmmas_equalTo(startX + moveX - CGRectGetWidth(self.laserPan.frame) / 2);
        make.top.bmmas_equalTo(startY + moveY - CGRectGetWidth(self.laserPan.frame) / 2);
    }];
}

- (void)clearAfterClass
{
    [self.fileView clearAfterClass];
}


#pragma -
#pragma mark DocShowViewZoomScaleDelegate

/// 移动ScrollView
- (void)onScrollViewDidScroll
{
    if (self.laserPan.superview)
    {
        [self showLaserPen];
    }
}

/// 手势改变ZoomScale
- (void)onZoomScaleChanged:(CGFloat)zoomScale
{
    self.currentScale = zoomScale;
    
    if (self.laserPan.superview)
    {
        [self showLaserPen];
    }

    if ([YSWhiteBoardManager shareInstance].wbDelegate &&
        [[YSWhiteBoardManager shareInstance].wbDelegate
            respondsToSelector:@selector(onWhiteBoardFileViewZoomScaleChanged:)])
    {
        [[YSWhiteBoardManager shareInstance].wbDelegate
            onWhiteBoardFileViewZoomScaleChanged:self.fileView.zoomScale];
    }
}


#pragma -
#pragma mark DrawTool

#pragma mark - 选择画笔工具：类型 && 颜色  &&大小
- (void)didSelectDrawType:(YSDrawType)type
                    color:(NSString *)hexColor
            widthProgress:(float)progress
{
    if (type == YSDrawTypeClear)
    {
        [self.fileView.ysDrawView clearDrawWithMsg];
        return;
    }

    NSUInteger toolType = 0;
    if (type >= YSDrawTypePen)
    {
        toolType = YSNativeToolTypeLine;
    }
    if (type >= YSDrawTypeTextMS)
    {
        toolType = YSNativeToolTypeText;
    }
    if (type >= YSDrawTypeEmptyRectangle)
    {
        toolType = YSNativeToolTypeShape;
    }
    if (type >= YSDrawTypeEraser)
    {
        toolType = YSNativeToolTypeEraser;
    }
    if (toolType)
    {
        [self changeWbToolConfigWithToolType:toolType drawType:type color:hexColor progress:progress];
    }

    [_fileView.ysDrawView setDrawType:type hexColor:hexColor progress:progress];
    [[YSRoomInterface instance] changeUserProperty:[YSRoomInterface instance].localUser.peerID
                                        tellWhom:YSRoomPubMsgTellAll
                                            data:@{
                                                @"primaryColor" : hexColor
                                            }
                                      completion:nil];
}



#pragma mark - 监听课堂 底层通知消息

////MARK: 授权&&上台
- (void)updateProperty:(NSDictionary *)dictionary
{
    if (![dictionary bm_isNotEmptyDictionary])
    {
        return;
    }

    NSString *toID = [dictionary bm_stringForKey:@"id"];
    if (![toID isEqualToString:[YSRoomInterface instance].localUser.peerID])
    {
        return;
    }
    
    NSDictionary *properties = [dictionary bm_dictionaryForKey:@"properties"];
    if (![properties bm_isNotEmptyDictionary])
    {
        return;
    }

    if ([properties bm_containsObjectForKey:@"candraw"])
    {
        BOOL candraw = [properties bm_boolForKey:@"candraw"];
        if ([YSRoomInterface instance].localUser.role == YSUserType_Student)
        { // 学生
            if (candraw)
            {
                // 授予画笔权限
                [self setWorkMode:self.selectMouse ? YSWorkModeViewer : YSWorkModeControllor];

            }
            else
            {
                [self setWorkMode:YSWorkModeViewer];
                self.fileView.ysDrawView.rtDrawView.draw = nil;
            }
            if (self.showOnWeb)
            {
                // 画笔穿透时在web课件上不隐藏
                self.fileView.hidden = [YSWhiteBoardManager shareInstance].roomConfig.isPenCanPenetration ? NO : _selectMouse;
            }
        }
        else if ([YSRoomInterface instance].localUser.role == YSUserType_Teacher)
        { // 老师
            [self setWorkMode:YSWorkModeControllor];
        }
        else
        { // 巡课
            [self setWorkMode:YSWorkModeViewer];
        }
    }
}

// MARK:-收到消息
- (void)receiveWhiteBoardMessage:(NSDictionary *)dictionary isDelMsg:(BOOL)isDel
{
#if 0
    if (![dictionary bm_isNotEmptyDictionary])
    {
        return;
    }

    // 信令相关性
    NSString *associatedMsgID = [dictionary objectForKey:@"associatedMsgID"];
    // 信令名
    NSString *msgName = [dictionary objectForKey:@"name"];
    // 信令id
    NSString *msgID = [dictionary objectForKey:@"id"];
    // 信令内容
    id dataObject = [dictionary objectForKey:@"data"];
    
    NSMutableDictionary *data = [YSRoomUtil convertWithData:dataObject];

    if ([msgName isEqualToString:@"FullScreen"])
    {
        NSString *fullScreenType = [data objectForKey:@"fullScreenType"];
        if ([fullScreenType isEqualToString:@"courseware_file"] && [YSWhiteBoardManager shareInstance].roomConfig.coursewareFullSynchronize)
        {
            [self resetEnlargeValue:YSWHITEBOARD_MINZOOMSCALE animated:YES];
        }
    }
    else if ([msgName isEqualToString:@"WBPageCount"])
    {
        total0Page = [data bm_uintForKey:@"totalPage"];
    }

    //切换课件服务器，刷新课件
    if ([msgID isEqualToString:@"RemoteControl"])
    {
        NSString *action = [data objectForKey:@"action"];
        if ([action isEqualToString:@"changeCdnIp"])
        {
            NSString *address = [data objectForKey:@"key"];
            if (![self.address isEqualToString:address])
            {
                self.address = address;
                [self drawOnView:_fileView.ysDrawView.drawView
                             withData:self.fileDictionary
                    updateImmediately:YES];
            }
        }
    }

    //选择鼠标
    NSString *fromID = [dictionary objectForKey:@"fromID"];
    //    NSString *toID = [dictionary objectForKey:@"toID"];
    NSNumber *selectMouse = [data objectForKey:@"selectMouse"];
    if ([msgName isEqualToString:@"whiteboardMarkTool"]) {
        if (![fromID isEqualToString:[YSRoomInterface instance].localUser.peerID]) {
            //        if ([[YSRoomInterface instance] getRoomUserWithUId:fromID].role == 0) {

            if (selectMouse.boolValue) {

                [[NSNotificationCenter defaultCenter]
                    postNotificationName:YSWhiteSendTextDrawIfChooseMouseNotification
                                  object:nil];
                _selectMouse                         = YES;
                _fileView.ysDrawView.rtDrawView.mode = YSWorkModeViewer;

                if ([[YSRoomInterface instance] getRoomUserWithUId:fromID].role ==
                        YSUserType_Teacher ||
                    [[YSRoomInterface instance] getRoomUserWithUId:fromID].role ==
                        YSUserType_Assistant) {

                    [[NSNotificationCenter defaultCenter]
                        postNotificationName:YSWhiteBoardRemoteSelectTool
                                      object:@(YES)];
                }
            }
            else {
                _selectMouse = NO;
                _fileView.ysDrawView.rtDrawView.mode =
                    _selectMouse ? YSWorkModeViewer : YSWorkModeControllor;
                _fileView.hidden = NO;

                if ([[YSRoomInterface instance] getRoomUserWithUId:fromID].role ==
                        YSUserType_Teacher ||
                    [[YSRoomInterface instance] getRoomUserWithUId:fromID].role ==
                        YSUserType_Assistant) {
                    [[NSNotificationCenter defaultCenter]
                        postNotificationName:YSWhiteBoardRemoteSelectTool
                                      object:@(NO)];
                }

                // 移除激光笔
                [_laserPan removeFromSuperview];
                _laserPan = nil;
            }
        }
        [self setDragFileEnabled:_selectMouse];
        return;
    }

    if (!associatedMsgID || [associatedMsgID hasPrefix:@"CaptureImg"]) { // 加入截屏绘制
        if ([msgName isEqualToString:@"ClassBegin"] && [msgID isEqualToString:@"ClassBegin"]) {
            if (!isDel) {
                //上课
            } else {
                //下课
                [_fileView.ysDrawView.rtDrawView clearDataAfterClass];
                // 下课隐藏 工具栏
                [self clearAfterClass];
            }
        }

        //大白板翻页
        else if ([msgName isEqualToString:sShowPage]) {
            [_fileView.ysDrawView.rtDrawView clearDataAfterClass];
            [self drawOnView:_fileView.ysDrawView.drawView withData:data updateImmediately:YES];
            return;
        } else if ([msgName isEqualToString:sDocumentChange]) {

            NSNumber *inIsDel = [data objectForKey:@"isDel"];
            NSNumber *fileid  = [[data objectForKey:@"filedata"] objectForKey:@"fileid"];

            if (![YSWhiteBoardManager shareInstance].isBeginClass) {
                if (!inIsDel.boolValue) {
                    return;
                } else {
                    return;
                }
            } else {
                //已上课
                if (inIsDel.boolValue) {
                    return;
                } else {
                    //添加课件，添加多媒体课件不响应
                    NSNumber *isMedia = [data objectForKey:@"isMedia"];
                    if (isMedia.boolValue) {
                        return;
                    } else {
                        __block BOOL has = NO;
                        [self.classFileList
                            enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull obj, NSUInteger idx,
                                                         BOOL *_Nonnull stop) {
                                NSNumber *inFileid = [obj objectForKey:@"fileid"];
                                if (inFileid.integerValue == fileid.integerValue) {
                                    has   = YES;
                                    *stop = YES;
                                }
                            }];

                        if (!has) {
                            [self.classFileList addObject:[data objectForKey:@"filedata"] ?: @"0"];
                        }
                    }
                    return;
                }
            }
        }
        //大白板绘制
        else if ([msgName isEqualToString:sSharpsChange]) {

            if ([data[@"eventType"] isEqualToString:@"laserMarkEvent"]) { // 激光笔
                if (![associatedMsgID hasPrefix:@"CaptureImg_"]) { [self laserPen:data]; }
            } else { // 绘制相关

                NSString *ID     = [dictionary objectForKey:@"id"];
                NSString *pageID = [ID componentsSeparatedByString:@"_"].lastObject;
                NSString *fileID = [[ID componentsSeparatedByString:@"_"]
                    objectAtIndex:[ID componentsSeparatedByString:@"_"].count - 2];
                BOOL drawOnCurrentPage =
                    [self.fileid isEqualToString:fileID] && self.currentPage == pageID.integerValue;

                id whiteboardID = [data objectForKey:sWhiteboardID];
                sendFromSelf = [fromID isEqualToString:[YSRoomInterface instance].localUser.peerID];

                if (isDel) {
                    // 此处的 delmsg  来源 于撤销 删除上一条pubmsg
                    // delMsg的data字段，在回放中是不可用的 会直接取用 对应 pubmsg 里的 data 数据
                    // 导致数据异常 此处修复异常数据

                    [data setObject:@"undoEvent" forKey:@"eventType"];
                }
                BOOL isWhiteBoard = ([whiteboardID isKindOfClass:[NSString class]] &&
                                     [whiteboardID isEqualToString:@"default"]) ||
                                    ([whiteboardID isKindOfClass:[NSNumber class]] &&
                                     [whiteboardID isEqualToNumber:@(0)]);
                if (isWhiteBoard) {

                    [_fileView.ysDrawView.drawView switchFileID:fileID
                                                 andCurrentPage:pageID.intValue
                                              updateImmediately:drawOnCurrentPage];
                    [self drawOnView:_fileView.ysDrawView.drawView
                                 withData:data
                        updateImmediately:drawOnCurrentPage];
                }

                return;
            }
        }
    }
#endif
}

#pragma mark - 进教室恢复数据 & 断线重连恢复数据

// MARK: 恢复数据
- (void)recoverDrawMessage:(NSMutableDictionary *)dictionary onDrawView:(DrawView *)drawView
{
    NSLog(@"YSWBView recoverDrawMessage: dictionary%@", dictionary);
    
    NSString *msgName = [dictionary objectForKey:@"name"];
    NSString *msgID = [dictionary objectForKey:@"id"];
    id dataObject = [dictionary objectForKey:@"data"];
    NSMutableDictionary *data = nil;
    if ([dataObject isKindOfClass:[NSDictionary class]])
    {
        data = [NSMutableDictionary dictionaryWithDictionary:dataObject];
    }
    if ([dataObject isKindOfClass:[NSString class]])
    {
        data = [NSJSONSerialization
            JSONObjectWithData:[(NSString *)dataObject dataUsingEncoding:NSUTF8StringEncoding]
                       options:NSJSONReadingMutableContainers
                         error:nil];
    }
    
    if ([msgName isEqualToString:@"ClassBegin"] && [msgID isEqualToString:@"ClassBegin"])
    {
        //上课
    }
    else if ([msgName isEqualToString:sYSSignalShowPage])
    {
        [self drawOnView:self.fileView.ysDrawView.drawView withData:data updateImmediately:YES];
    }
    else if ([msgName isEqualToString:sYSSignalSharpsChange])
    {
        id whiteboardID = [data objectForKey:@"whiteboardID"];
        if ([whiteboardID isKindOfClass:[NSString class]])
        {
            if ([whiteboardID isEqualToString:@"default"])
            {
                [self drawOnView:self.fileView.ysDrawView.drawView withData:data updateImmediately:YES];
            }
        }
        else if ([whiteboardID isKindOfClass:[NSNumber class]])
        {
            if ([whiteboardID isEqualToNumber:@(0)])
            {
                [self drawOnView:self.fileView.ysDrawView.drawView withData:data updateImmediately:YES];
            }
        }
    }
    else if ([msgName isEqualToString:@"whiteboardMarkTool"])
    {
        NSNumber *selectMouse = [data objectForKey:@"selectMouse"];
        self.selectMouse = selectMouse.boolValue;

        // 学生进入教室此通知YSBrushToolView还未创建，无法响应此通知
        [[NSNotificationCenter defaultCenter] postNotificationName:YSWhiteBoardRemoteSelectTool
                                                            object:@(self.selectMouse)];

        if (self.selectMouse && self.showOnWeb)
        {
            self.fileView.hidden = [YSWhiteBoardManager shareInstance].roomConfig.isPenCanPenetration ? NO : self.selectMouse;
        }
        [self setWorkMode:self.selectMouse ? YSWorkModeViewer : YSWorkModeControllor];
        if ([YSRoomInterface instance].localUser.role == YSUserType_Teacher)
        {
            if (!self.selectMouse)
            {
                [self didSelectDrawType:YSDrawTypePen color:@"#ED3E3A" widthProgress:0.05];
            }
        }
    }
}

- (void)whiteBoardOnRoomConnectedUserlist:(NSNumber *)code response:(NSDictionary *)response
{
    if (![response bm_isNotEmptyDictionary])
    {
        return;
    }

    NSDictionary *msglist = [response objectForKey:@"msglist"];

    NSMutableArray *whiteboardRecoveryMSG = [@[] mutableCopy];
    // 开始恢复大白板数据
    hasRecoveried = NO;
    self.fileView.ysDrawView.drawView.shouldShowdraweraName = NO;
    self.fileView.ysDrawView.drawView.hidden = NO;

    for (NSString *key in msglist.allKeys)
    {
        NSDictionary *dictionary  = [msglist objectForKey:key];
        NSString *associatedMsgID = [dictionary objectForKey:@"associatedMsgID"];

        // 表示该信令用于大白板
        if ([key containsString:@"SharpsChange"])
        {
            if (![associatedMsgID isEqualToString:@"QuestionModel"]) {
                [whiteboardRecoveryMSG addObject:[msglist objectForKey:key]];
            }
        } else if ([key isEqualToString:@"DocumentFilePage_ShowPage"]) {
            [whiteboardRecoveryMSG addObject:[msglist objectForKey:key]];
        } else if ([key isEqualToString:@"whiteboardMarkTool"]) {
            [whiteboardRecoveryMSG addObject:[msglist objectForKey:key]];
        } else if ([key isEqualToString:@"ExtendWhiteboardMarkTool"]) {
            [whiteboardRecoveryMSG addObject:[msglist objectForKey:key]];
        } else if ([key isEqualToString:sYSSignalClassBegin]) {
            [whiteboardRecoveryMSG addObject:[msglist objectForKey:key]];
        } else if ([key isEqualToString:@"WBPageCount"]) {
            id data = [dictionary objectForKey:@"data"];
            NSDictionary *dataDic = nil;
            if ([data isKindOfClass:[NSString class]]) {
                dataDic = [NSJSONSerialization
                    JSONObjectWithData:[(NSString *)data dataUsingEncoding:NSUTF8StringEncoding]
                               options:NSJSONReadingMutableLeaves
                                 error:nil];
            }
            if ([data isKindOfClass:[NSDictionary class]]) { dataDic = (NSDictionary *)data; }
            NSNumber *totalPage = [dataDic objectForKey:@"totalPage"];
            total0Page = totalPage;
        }
    }

    // 将whiteboardRecoveryMSG元素按seq值排序
    if (whiteboardRecoveryMSG.count != 0)
    {
        whiteboardRecoveryMSG = [[whiteboardRecoveryMSG
            sortedArrayUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
                return [[obj1 objectForKey:@"seq"] compare:[obj2 objectForKey:@"seq"]];
            }] mutableCopy];

        // 遍历调用receiveDrawMessage
        for (NSDictionary *dic in whiteboardRecoveryMSG)
        {
            NSString *ID = [dic objectForKey:@"id"];

            if ([ID containsString:@"###_SharpsChange"])
            {
                NSArray *components = [ID componentsSeparatedByString:@"_"];
                if (components.count > 2) {
                    NSString *currentPage = components.lastObject;
                    NSString *fileID      = [components objectAtIndex:components.count - 2];
                    //如果是画笔则先翻页保证每步绘制在正确的页面上

                    [self.fileView.ysDrawView.drawView switchFileID:fileID
                                                 andCurrentPage:currentPage.intValue
                                              updateImmediately:YES];
                }
            }
            [self recoverDrawMessage:[NSMutableDictionary dictionaryWithDictionary:dic]
                          onDrawView:_fileView.ysDrawView.drawView];
        }
    }

    hasRecoveried = YES;

    // 切换一下画布到主白板
    [self.fileView.ysDrawView.drawView switchFileID:self.fileId
                                 andCurrentPage:(int)self.currentPage
                              updateImmediately:YES];
}

#pragma mark - 绘制翻页处理

- (void)drawOnView:(DrawView *)drawView
             withData:(NSMutableDictionary *)dictionary
    updateImmediately:(BOOL)update
{
    if (![dictionary bm_isNotEmptyDictionary])
    {
        return;
    }

    // 绘制消息
    NSString *actionName = [dictionary objectForKey:@"actionName"];
    NSString *clearActionId = [dictionary objectForKey:@"clearActionId"];

    YSEvent eventType = 0;
    NSString *eventTypeString = [dictionary objectForKey:@"eventType"];

    if ([eventTypeString isEqualToString:@"shapeSaveEvent"])
    {
        eventType = YSEventShapeAdd;
        if (hasRecoveried)
        {
            //收到自己画笔信令不显示落笔名字
            self.fileView.ysDrawView.drawView.shouldShowdraweraName = [YSWhiteBoardManager shareInstance].roomConfig.isShowWriteUpTheName;
            if (self.fileView.ysDrawView.drawView.shouldShowdraweraName)
            {
                if (sendFromSelf)
                {
                    self.fileView.ysDrawView.drawView.shouldShowdraweraName = NO;
                    sendFromSelf = NO;
                }
                else
                {
                    self.fileView.ysDrawView.drawView.shouldShowdraweraName = YES;
                }
            }
        }
        else
        {
            self.fileView.ysDrawView.drawView.shouldShowdraweraName = NO;
        }
    }
    else if ([eventTypeString isEqualToString:@"undoEvent"])
    {
        eventType = YSEventShapeUndo;
    }
    else if ([eventTypeString isEqualToString:@"redoEvent"])
    {
        eventType = YSEventShapeRedo;
        self.fileView.ysDrawView.drawView.shouldShowdraweraName = NO;
    }
    else if ([eventTypeString isEqualToString:@"clearEvent"])
    {
        eventType = YSEventShapeClean;
    }

    // 课件消息
    if (!eventTypeString || eventTypeString.length == 0)
    {
        eventType = YSEventShowPage;
    }
    
    switch (eventType)
    {
        case YSEventShowPage: {
            NSString *fileid   = [[dictionary objectForKey:@"filedata"] objectForKey:@"fileid"];
            BOOL isGeneralFile = [[dictionary objectForKey:@"isGeneralFile"] boolValue];
            NSNumber *pageNum  = [[dictionary objectForKey:@"filedata"] objectForKey:@"pagenum"];
            NSNumber *currentPage =
                [[dictionary objectForKey:@"filedata"] objectForKey:@"currpage"];

            if (currentPage == nil || [currentPage isEqual:[NSNull null]]) { currentPage = @(1); }

            NSNumber *isMedia = [dictionary objectForKey:@"isMedia"];
            if (isMedia.boolValue)
            {
                // 老师后台关联课件的时候会发送showpage，如果是media类型直接return
                return;
            }

            [_fileView.ysDrawView.drawView clearDrawersNameAfterShowPage];
            [self resetEnlargeValue:YSWHITEBOARD_MINZOOMSCALE animated:YES];
            self.fileDictionary = dictionary;

            [[UIApplication sharedApplication].keyWindow endEditing:YES];

            if ([pageNum isEqual:[NSNull null]]) { pageNum = @(0); }

            self.fileId = [NSString stringWithFormat:@"%@", fileid];
#warning currentFileId
            //[YSWhiteBoardManager shareInstance].currentFileId = self.fileid;
            self.currentPage = currentPage.intValue;
            self.pagecount = pageNum.intValue;

            //切换文档的时候更新drawview的数据用来分页绘制
            [drawView switchFileID:self.fileId
                    andCurrentPage:(int)self.currentPage
                 updateImmediately:YES];
            [self.fileView.ysDrawView.rtDrawView switchFileID:self.fileId
                                           andCurrentPage:(int)self.currentPage
                                        updateImmediately:YES];

            self.fileView.ysDrawView.rtDrawView.fileid = self.fileId;
            self.fileView.ysDrawView.rtDrawView.pageId = (int)self.currentPage;

            if (self.fileId.intValue == 0)
            {
                self.showOnWeb = NO;
                self.pagecount = total0Page;
                NSMutableDictionary *message = [NSMutableDictionary dictionary];
                [message setObject:@"showOnLocal" forKey:@"fileTypeMark"];
                NSMutableDictionary *page = [NSMutableDictionary dictionary];
                [page setObject:[NSString stringWithFormat:@"%d", (int)(self.currentPage)]
                         forKey:@"currentPage"];
                [page setObject:[NSString stringWithFormat:@"%d", (int)(self.pagecount)]
                         forKey:@"totalPage"];
                [message setObject:page forKey:@"page"];

                if ([YSWhiteBoardManager shareInstance].wbDelegate &&
                    [[YSWhiteBoardManager shareInstance].wbDelegate
                        respondsToSelector:@selector(onWhiteBoardViewStateUpdate:)])
                {
                    [[YSWhiteBoardManager shareInstance].wbDelegate
                        onWhiteBoardViewStateUpdate:message];
                }

                self.wkWebView.hidden = YES;
                [self.fileView showWhiteBoard0];
                [self updateWBRatio:16.0f / 9];
                
                self.fileView.isPenetration = NO;

                return;
            }

            if (isGeneralFile)
            {
                NSString *path = [[dictionary objectForKey:@"filedata"] objectForKey:@"swfpath"];
                NSArray *com = [path componentsSeparatedByString:@"."];
                path = [NSString stringWithFormat:@"%@-%@.%@", com.firstObject, currentPage, com.lastObject];
                NSString *realPath = [NSString stringWithFormat:@"https://%@%@", self.address, path];
                
                __block BOOL hasPDF = NO;
                [[YSWhiteBoardManager shareInstance].docmentDicList
                    enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull obj, NSUInteger idx,
                                                 BOOL *_Nonnull stop) {

                        if ([[obj objectForKey:@"fileid"] integerValue] == self.fileId.integerValue)
                        { //v查找课件库中的对应课件是否可以使用pdf
                            NSString *cospdfpath = [obj objectForKey:@"cospdfpath"];
                            if ([cospdfpath bm_isNotEmpty])
                            {
                                hasPDF = YES;
                                *stop  = YES;
                            }
                        }
                    }];

                if (hasPDF) {
                    self.showOnWeb = NO;
                    NSMutableDictionary *message = [NSMutableDictionary dictionary];
                    [message setObject:@"showOnLocal" forKey:@"fileTypeMark"];
                    NSMutableDictionary *page = [NSMutableDictionary dictionary];
                    [page setObject:[NSString stringWithFormat:@"%@", currentPage]
                             forKey:@"currentPage"];
                    [page setObject:[NSString stringWithFormat:@"%@", pageNum] forKey:@"totalPage"];
                    [message setObject:page forKey:@"page"];

                    if ([YSWhiteBoardManager shareInstance].wbDelegate &&
                        [[YSWhiteBoardManager shareInstance].wbDelegate
                            respondsToSelector:@selector(onWhiteBoardViewStateUpdate:)]) {
                        [[YSWhiteBoardManager shareInstance].wbDelegate
                            onWhiteBoardViewStateUpdate:message];
                    }
                    /*
                     {
                     fileTypeMark = h5Document;
                     irregular = "1.777777777777778";
                     page =     {
                     addPage = 0;
                     currentPage = 1;
                     nextPage = 0;
                     nextStep = 0;
                     prevPage = 0;
                     prevStep = 0;
                     skipPage = 0;
                     totalPage = 10;
                     };
                     scale = 1;
                     }
                     */

                    //加载pdf
                    self.fileView.hidden           = NO;
                    self.wkWebView.hidden          = YES;
                    BMWeakSelf
                    [self.fileView showPDFwithDataDictionary:dictionary
                                                Doc_Host:self.address
                                            Doc_Protocol:@"https"
                                           didFinishLoad:^(float ratio) {
                                               [weakSelf updateWBRatio:ratio];
                                               weakSelf.fileView.whiteBoardColorView.hidden = NO;
                                               [weakSelf.fileView.pdfView setNeedsDisplay];
                                           }];

                } else {
                    //加载图片
                    if (![self.fileId isEqualToString:@"0"]) {
                        if ([realPath hasSuffix:@".svg"]) {
                            //交给web加载
                            self.showOnWeb    = YES;
                            self.wkWebView.hidden = NO;
                            [self.fileView showOnWeb];
                            self.fileView.hidden = self.selectMouse;
                        } else if ([realPath hasSuffix:@".gif"]) {
                            //交给web加载
                            self.showOnWeb    = YES;
                            self.wkWebView.hidden = NO;
                            [self.fileView showOnWeb];
                            self.fileView.hidden = self.selectMouse;

                        } else {

                            self.showOnWeb               = NO;
                            NSMutableDictionary *message = [NSMutableDictionary dictionary];
                            [message setObject:@"showOnLocal" forKey:@"fileTypeMark"];
                            NSMutableDictionary *page = [NSMutableDictionary dictionary];
                            [page setObject:[NSString stringWithFormat:@"%@", currentPage]
                                     forKey:@"currentPage"];
                            [page setObject:[NSString stringWithFormat:@"%@", pageNum]
                                     forKey:@"totalPage"];
                            [message setObject:page forKey:@"page"];

                            if ([YSWhiteBoardManager shareInstance].wbDelegate &&
                                [[YSWhiteBoardManager shareInstance].wbDelegate
                                    respondsToSelector:@selector(onWhiteBoardViewStateUpdate:)]) {
                                [[YSWhiteBoardManager shareInstance].wbDelegate
                                    onWhiteBoardViewStateUpdate:message];
                            }
                            //原生加载
                            self.wkWebView.hidden          = YES;
                            self.fileView.hidden           = NO;
                            BMWeakSelf
                            NSString *host = [NSURL URLWithString:realPath].host;
                            [self.fileView showImage:[NSURL URLWithString:realPath] host:host finishBlock:^(float ratio) {
                                [weakSelf updateWBRatio:ratio];
                            }];
                        }
                    }
                }
            } else {
                self.showOnWeb    = YES;
                self.wkWebView.hidden = NO;
                [self.fileView showOnWeb];
                self.fileView.hidden = [YSWhiteBoardManager shareInstance].roomConfig.isPenCanPenetration ? NO : self.selectMouse;
            }
            
            if ([YSWhiteBoardManager shareInstance].roomConfig.isPenCanPenetration == YES)
            {
                self.fileView.isPenetration = self.showOnWeb && self.selectMouse;
            }

        } break;
            
        case YSEventShapeAdd: {
            if ([actionName isEqualToString:@"ClearAction"]) {
                //恢复清空
                [self.fileView.ysDrawView clearDraw:clearActionId];
            } else {
                [self.fileView.ysDrawView addDrawData:dictionary refreshImmediately:update];
            }
        } break;
            
        case YSEventShapeClean: {
            NSString *clearID = [dictionary objectForKey:@"clearActionId"];
            [self.fileView.ysDrawView clearDraw:clearID];
        } break;
            
        case YSEventShapeUndo: {
            [self.fileView.ysDrawView undoDraw];
            break;
        }
            
        case YSEventShapeRedo: {
            if ([actionName isEqualToString:@"ClearAction"]) {
                NSString *clearID = [dictionary objectForKey:@"clearActionId"];
                [self.fileView.ysDrawView clearDraw:clearID];
            }
            if ([actionName isEqualToString:@"AddShapeAction"]) {
                [self.fileView.ysDrawView addDrawData:dictionary refreshImmediately:update];
            }
            break;
        }
            
        default:
            break;
    }
}

@end
