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
/// 全屏 复原 回调
/// @param isAllScreen 是否全屏
- (void)boardControlProxyfullScreen:(BOOL)isAllScreen;
/// 上一页
- (void)boardControlProxyPrePage;
/// 下一页
- (void)boardControlProxyNextPage;
/// 放大
- (void)boardControlProxyEnlarge;
/// 缩小
- (void)boardControlProxyNarrow;

@end

@interface YSCoursewareControlView : UIView

@property (nonatomic, weak) id <YSCoursewareControlViewDelegate> delegate;

/// 是否全屏
@property (nonatomic, assign) BOOL isAllScreen;
/// 是否可以缩放
@property (nonatomic, assign) BOOL allowScaling;
/// 是否可以翻页  (未开课前通过权限判断是否可以翻页  上课后永久不可以翻页)
@property (nonatomic, assign) BOOL allowTurnPage;
/// 缩放比例
@property (nonatomic, assign, readonly) CGFloat zoomScale;


@end

NS_ASSUME_NONNULL_END
