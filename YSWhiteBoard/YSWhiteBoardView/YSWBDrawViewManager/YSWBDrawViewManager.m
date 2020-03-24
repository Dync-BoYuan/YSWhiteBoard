//
//  YSWBDrawViewManager.m
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/22.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import "YSWBDrawViewManager.h"
#import "DrawView.h"

NSString *const YSWhiteBoardRemoteSelectTool = @"YSWhiteBoardRemoteSelectTool"; //远程选择

@interface YSWBDrawViewManager ()
<
    UIGestureRecognizerDelegate,
    DocShowViewZoomScaleDelegate
>

/// 承载View
@property (nonatomic, weak) UIView *contentView;

/// web课件通过YSWBWebViewManager创建的webView
@property (nonatomic, strong) WKWebView *wkWebView;
/// 普通课件视图
@property (nonatomic, strong) DocShowView *fileView;

@property (nonatomic, strong) NSMutableDictionary *wbToolConfigs;
@property (nonatomic, strong) NSString *defaultPrimaryColor;

/// 当前fileId
@property (nonatomic, strong) NSString *fileid;

/// 课件使用 webView 加载
@property (nonatomic, assign) BOOL showOnWeb;

/// 记录刚进入教室 老师的画笔状态，是否使用选取工具
@property (nonatomic, assign) BOOL selectMouse;

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
            if ([self.fileid isEqualToString:@"0"])
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

/*
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
            [self updateWBRatio:_ratio];
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
            [self updateWBRatio:_ratio];
            [self.fileView setNeedsLayout];
            [self.fileView layoutIfNeeded];
        }
    }
}
*/

@end
