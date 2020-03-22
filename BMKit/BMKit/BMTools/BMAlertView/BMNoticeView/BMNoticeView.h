//
//  BMNoticeView.h
//  YSLive
//
//  Created by jiang deng on 2019/10/21.
//  Copyright © 2019 FS. All rights reserved.
//

#import <UIKit/UIKit.h>

#define BMNOTICEVIEW_MAXSHOWCOUNT 5

typedef NS_ENUM(NSUInteger, BMNoticeViewShowAnimation)
{
    BMNoticeViewShowAnimationNone,
    BMNoticeViewShowAnimationFadeIn,
    BMNoticeViewShowAnimationSlideInFromBottom,
    BMNoticeViewShowAnimationSlideInFromTop,
    BMNoticeViewShowAnimationSlideInFromLeft,
    BMNoticeViewShowAnimationSlideInFromRight
};

typedef NS_ENUM(NSUInteger, BMNoticeViewHideAnimation)
{
    BMNoticeViewHideAnimationNone,
    BMNoticeViewHideAnimationFadeOut,
    BMNoticeViewHideAnimationSlideOutToBottom,
    BMNoticeViewHideAnimationSlideOutToTop,
    BMNoticeViewHideAnimationSlideOutToLeft,
    BMNoticeViewHideAnimationSlideOutToRight
};

typedef void (^BMNoticeViewShowBlock)(void);
typedef void (^BMNoticeViewDismissBlock)(id _Nullable sender, NSUInteger index);

NS_ASSUME_NONNULL_BEGIN

@interface BMNoticeView : UIView

@property (nonatomic, assign, readonly, getter=isVisible) BOOL visible;

@property (nonatomic, strong, readonly) UIView *noticeView;

// 是否响应点击蒙版
@property (nonatomic, assign) BOOL shouldDismissOnTapOutside;
// 是否cancel关闭
@property (nonatomic, assign) BOOL notDismissOnCancel;

// 蒙版
@property (nonatomic, strong, readonly) UIVisualEffectView *noticeMaskBgEffectView;
@property (nullable, nonatomic, strong) UIVisualEffect *noticeMaskBgEffect;
@property (nonatomic, strong) UIColor *noticeMaskBgColor;

@property (nonatomic, assign) BMNoticeViewShowAnimation showAnimationType;
@property (nonatomic, assign) BMNoticeViewHideAnimation hideAnimationType;

@property (nullable, nonatomic, copy) BMNoticeViewShowBlock showBlock;
@property (nullable, nonatomic, copy) BMNoticeViewDismissBlock dismissBlock;

@property (nonatomic, assign) UIEdgeInsets backgroundEdgeInsets;
@property (nonatomic, assign) CGFloat topDistance;

- (void)showWithView:(UIView *)contentView inView:(UIView *)inView;
- (void)showWithView:(UIView *)contentView inView:(UIView *)inView showBlock:(nullable BMNoticeViewShowBlock)showBlock;
- (void)showWithView:(UIView *)contentView inView:(UIView *)inView showBlock:(nullable BMNoticeViewShowBlock)showBlock dismissBlock:(nullable BMNoticeViewDismissBlock)dismissBlock;

- (void)dismiss:(nullable id)sender;
- (void)dismiss:(nullable id)sender dismissBlock:(nullable BMNoticeViewDismissBlock)dismissBlock;
- (void)dismiss:(nullable id)sender animated:(BOOL)animated dismissBlock:(nullable BMNoticeViewDismissBlock)dismissBlock;

@end

@interface BMNoticeViewStack : NSObject

+ (BMNoticeViewStack *)sharedInstance;

- (void)closeAllNoticeViews;

- (void)closeNoticeView:(BMNoticeView *)noticeView;
- (void)closeNoticeView:(BMNoticeView *)noticeView animated:(BOOL)animated;

- (NSUInteger)getNoticeViewCount;
- (void)bringAllViewsToFront;

@end

NS_ASSUME_NONNULL_END
