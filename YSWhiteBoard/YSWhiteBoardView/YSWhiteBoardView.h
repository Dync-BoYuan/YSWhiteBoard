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
#import "YSWhiteBoardTopBar.h"

NS_ASSUME_NONNULL_BEGIN

@protocol YSWhiteBoardViewDelegate;

@interface YSWhiteBoardView : UIView

@property (nonatomic, weak) id <YSWhiteBoardViewDelegate> delegate;

@property (nonatomic, strong, readonly) NSString *whiteBoardId;
@property (nonatomic, strong, readonly) NSString *fileId;

/// 当前页码
@property (nonatomic, assign, readonly) NSUInteger currentPage;
/// 总页码
@property (nonatomic, assign, readonly) NSUInteger totalPage;

/// 课件加载成功
@property (nonatomic, assign, readonly) BOOL isLoadingFinish;

/// 白板背景容器
@property (nonatomic, strong, readonly) UIView *whiteBoardContentView;

/// web文档
@property (nonatomic, strong, readonly) YSWBWebViewManager *webViewManager;
/// 普通文档
@property (nonatomic, strong, readonly) YSWBDrawViewManager *drawViewManager;

/// 小白板的topBar
@property (nonatomic, strong)YSWhiteBoardTopBar * topBar;


- (instancetype)initWithFrame:(CGRect)frame fileId:(NSString *)fileId loadFinishedBlock:(nullable  wbLoadFinishedBlock)loadFinishedBlock;

/// 更新服务器地址
- (void)updateWebAddressInfo:(NSDictionary *)message;
/// 断开连接
- (void)disconnect:(NSDictionary *)message;
/// 用户属性改变通知
- (void)userPropertyChanged:(NSDictionary *)message;

/// 收到远端pubMsg消息通知
- (void)remotePubMsg:(NSDictionary *)message;
/// 收到远端delMsg消息的通知
- (void)remoteDelMsg:(NSDictionary *)message;


// 页面刷新尺寸
- (void)refreshWhiteBoard;
- (void)refreshWhiteBoardWithFrame:(CGRect)frame;


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

- (void)changeFileId:(NSString *)fileId;
/// 当前页码
- (void)changeCurrentPage:(NSUInteger)currentPage;
/// 总页码
- (void)changeTotalPage:(NSUInteger)pagecount;


#pragma -
#pragma mark 画笔控制

- (void)brushToolsDidSelect:(YSBrushToolType)BrushToolType;
- (void)didSelectDrawType:(YSDrawType)type color:(NSString *)hexColor widthProgress:(CGFloat)progress;
- (void)freshBrushToolConfigs;

@end


@protocol YSWhiteBoardViewDelegate <NSObject>

@required

/// H5脚本文件加载初始化完成
- (void)onWBViewWebViewManagerPageFinshed:(YSWhiteBoardView *)whiteBoardView;

/// 切换Web课件加载状态
- (void)onWBViewWebViewManagerLoadedState:(YSWhiteBoardView *)whiteBoardView withState:(NSDictionary *)dic;

/// Web课件翻页结果
- (void)onWBViewWebViewManagerStateUpdate:(YSWhiteBoardView *)whiteBoardView withState:(NSDictionary *)dic;
/// 翻页超时
- (void)onWBViewWebViewManagerSlideLoadTimeout:(YSWhiteBoardView *)whiteBoardView withState:(NSDictionary *)dic;

@end




NS_ASSUME_NONNULL_END
