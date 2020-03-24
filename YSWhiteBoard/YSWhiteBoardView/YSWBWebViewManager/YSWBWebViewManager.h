//
//  YSWBWebViewManager.h
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/22.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol YSWBWebViewManagerDelegate;

@interface YSWBWebViewManager : NSObject

/// webview崩溃回调
@property (nonatomic, copy, nullable) wbWebViewTerminateBlock webViewTerminateBlock;
@property (nonatomic, weak, nullable) id <YSWBWebViewManagerDelegate> delegate;

@property (nonatomic, strong, readonly) WKWebView *webView;

/// 是否正在播放媒体文件
@property (nonatomic, assign) BOOL playingMedia;

- (WKWebView *)createWhiteBoardWithFrame:(CGRect)frame
                         loadFinishedBlock:(wbLoadFinishedBlock)loadFinishedBlock;


/**
 向js发送消息

 @param signalingName 信令名称
 @param message 消息
 */
- (void)sendSignalMessageToJS:(NSString *)signalingName message:(nullable id)message;


/**
 向js发送消息

 @param message 消息
 */
- (void)sendMessageToJS:(NSString *)message;


/**
 向js发送动作指令

 @param action 动作
 @param cmd 消息
 */
- (void)sendAction:(NSString *)action command:(nullable NSDictionary *)cmd;

/*
 房间链接成功
 */
- (void)whiteBoardOnRoomConnectedUserlist:(NSNumber *)code response:(NSDictionary *)response;

/**
 发送缓存消息

 @param array 缓存消息
 */
- (void)sendCacheInformation:(NSMutableArray *)array;

/**
 刷新界面
 */
- (void)refreshWhiteBoardWithFrame:(CGRect)frame;

/**
 销毁
 */
- (void)destory;

/**
 重新加载webview
 */
- (void)webViewreload;

- (void)stopPlayMp3;

@end


@protocol YSWBWebViewManagerDelegate <NSObject>

@required

/// 文档控制按钮状态更新
- (void)onWBWebViewManagerStateUpdate:(NSDictionary *)message;
/// 课件加载成功回调
- (void)onWBWebViewManagerLoadSuccess:(NSDictionary *)dic;
/// 翻页超时
- (void)onWBWebViewManagerSlideLoadTimeout:(NSDictionary *)dic;
/// 房间链接成功msglist回调
- (void)onWBWebViewManagerOnRoomConnectedMsglist:(NSDictionary *)msgList;
/// 教室加载状态
- (void)onWBWebViewManagerLoadedState:(NSDictionary *)message;
/// 白板初始化完成
- (void)onWBWebViewManagerPageFinshed;
/// 预加载文档结束
- (void)onWBWebViewManagerPreloadingFished;

@end

NS_ASSUME_NONNULL_END
