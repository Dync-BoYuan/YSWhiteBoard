//
//  YSCoursewareControlView.h
//  YSWhiteBoard
//
//  Created by 马迪 on 2020/4/2.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol YSCoursewareControlViewDelegate <NSObject>

/// 刷新课件
- (void)coursewareFrashBtnClick:(UIButton *)sender;
/// 全屏 复原 回调
- (void)coursewarefullScreen:(BOOL)isAllScreen;
/// 上一页
- (void)coursewareTurnToPreviousPage;
/// 下一页
- (void)coursewareTurnToNextPage;
/// 放大
- (void)coursewareToEnlarge;
/// 缩小
- (void)coursewareToNarrow;

@end


@interface YSCoursewareControlView : UIView

@property (nonatomic, weak) id <YSCoursewareControlViewDelegate> delegate;

/// 是否全屏
@property (nonatomic, assign) BOOL isAllScreen;

/// 是否可以翻页  (未开课前通过权限判断是否可以翻页  上课后永久不可以翻页)
@property (nonatomic, assign) BOOL allowTurnPage;

/// 是否可以缩放
@property (nonatomic, assign) BOOL allowScaling;

/// 缩放比例
@property (nonatomic, assign, readonly) CGFloat zoomScale;


/// 重置缩放按钮
- (void)resetBtnStates;
///
- (void)changeZoomScale:(CGFloat)zoomScale;

/// 初始化 当前页以及总页数
- (void)sc_setTotalPage:(NSInteger)total currentPage:(NSInteger)currentPage isWhiteBoard:(BOOL)isWhiteBoard;
- (void)sc_setTotalPage:(NSInteger)total currentPage:(NSInteger)currentPage canPrevPage:(BOOL)canPrevPage canNextPage:(BOOL)canNextPage isWhiteBoard:(BOOL)isWhiteBoard;


@end

NS_ASSUME_NONNULL_END
