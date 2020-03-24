//
//  YSWhiteBoardView.m
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/23.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import "YSWhiteBoardView.h"

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

- (void)userPropertyChanged:(NSDictionary *)message
{
    if (self.webViewManager)
    {
        [self.webViewManager sendSignalMessageToJS:WBSetProperty message:message];
    }
    
    if (self.drawViewManager)
    {
        //[self.drawViewManager updateProperty:message];
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
