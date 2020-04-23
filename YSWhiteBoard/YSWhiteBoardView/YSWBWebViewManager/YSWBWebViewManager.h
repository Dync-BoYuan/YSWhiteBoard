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

@property (nonatomic, assign) BOOL isPreLoadFile;

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

/**
 刷新界面
 */
- (void)refreshWhiteBoardWithFrame:(CGRect)frame;

/**
 销毁
 */
- (void)destroy;

/**
 重新加载webview
 */
- (void)webViewreload;

- (void)stopPlayMp3;

@end


@protocol YSWBWebViewManagerDelegate <NSObject>

@required

/// H5脚本文件加载初始化完成
- (void)onWBWebViewManagerPageFinshed;

/// 请求了预加载后返回预加载文档结束
//- (void)onWBWebViewManagerPreloadingFished;

/// 房间链接成功msglist回调
//- (void)onWBWebViewManagerOnRoomConnectedMsglist:(NSDictionary *)msgList;

/// 切换Web课件加载状态
- (void)onWBWebViewManagerLoadedState:(NSDictionary *)dic;

/// Web课件翻页结果
- (void)onWBWebViewManagerStateUpdate:(NSDictionary *)dic;
/// 翻页超时
- (void)onWBWebViewManagerSlideLoadTimeout:(NSDictionary *)dic;

@end

NS_ASSUME_NONNULL_END
