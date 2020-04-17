//
//  YSWhiteBoardView.h
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/23.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "YSWBDrawViewManager.h"
#import "YSWBWebViewManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol YSWhiteBoardViewDelegate;

@interface YSWhiteBoardView : UIView

@property (nonatomic, weak) id <YSWhiteBoardViewDelegate> delegate;

@property (nonatomic, strong, readonly) NSString *whiteBoardId;
@property (nonatomic, strong, readonly) NSString *fileId;

/// 课件加载成功
@property (nonatomic, assign, readonly) BOOL isLoadingFinish;

/// web文档
@property (nonatomic, strong, readonly) YSWBWebViewManager *webViewManager;
/// 普通文档
@property (nonatomic, strong, readonly) YSWBDrawViewManager *drawViewManager;

- (instancetype)initWithFrame:(CGRect)frame fileId:(NSString *)fileId loadFinishedBlock:(nullable  wbLoadFinishedBlock)loadFinishedBlock;

/// 断开连接
- (void)disconnect:(NSDictionary *)message;
/// 用户属性改变通知
- (void)userPropertyChanged:(NSDictionary *)message;
/// 用户离开通知
- (void)participantLeaved:(NSDictionary *)message;
/// 用户进入通知
- (void)participantJoin:(NSDictionary *)message;
/// 自己被踢出教室通知
- (void)participantEvicted:(NSDictionary *)message;
/// 收到远端pubMsg消息通知
- (void)remotePubMsg:(NSDictionary *)message;
/// 收到远端delMsg消息的通知
- (void)remoteDelMsg:(NSDictionary *)message;

/// 连接教室成功的通知
//- (void)whiteBoardOnRoomConnectedUserlist:(NSNumber *)code response:(NSDictionary *)response;

/// 大并发房间用户上台通知
- (void)bigRoomUserPublished:(NSDictionary *)message;

/// 更新服务器地址
- (void)updateWebAddressInfo:(NSDictionary *)message;

// 页面刷新尺寸
- (void)refreshWhiteBoard;
- (void)refreshWhiteBoardWithFrame:(CGRect)frame;

- (void)receiveWhiteBoardMessage:(NSDictionary *)dictionary isDelMsg:(BOOL)isDel;


#pragma -
#pragma mark 课件操作

/// 刷新当前白板课件
- (void)freshCurrentCourse;

/// 课件 上一页
- (void)whiteBoardPrePage;
/// 课件 下一页
- (void)whiteBoardNextPage;
/// 课件 跳转页
- (void)whiteBoardTurnToPage:(NSUInteger)pageNum;

/// 白板 放大
- (void)whiteBoardEnlarge;
/// 白板 缩小
- (void)whiteBoardNarrow;
/// 白板 放大重置
- (void)whiteBoardResetEnlarge;


@end


@protocol YSWhiteBoardViewDelegate <NSObject>

@required

/// 房间链接成功msglist回调
- (void)onWBWebViewManagerOnRoomConnectedMsglist:(NSDictionary *)msgList;


/// 教室加载状态
- (void)onWBWebViewManagerLoadedState:(NSDictionary *)message;

/// 白板初始化完成
- (void)onWBWebViewManagerPageFinshed;

/// 预加载文档结束
- (void)onWBWebViewManagerPreloadingFished;

///拖拽手势事件
- (void)panToMoveWhiteBoardView:(YSWhiteBoardView *)whiteBoard withGestureRecognizer:(UIPanGestureRecognizer *)pan;

@end




NS_ASSUME_NONNULL_END
