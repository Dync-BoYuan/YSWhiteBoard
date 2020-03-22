//
//  BMAlignedImageView.h
//  BMAlignedImageViewSample
//
//  Created by DennisDeng on 2018/3/1.
//  Copyright © 2018年 DennisDeng. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, BMImageViewHorizontallyAlignment)
{
    // 左
    BMImageViewHorizontallyAlignmentLeft = 0,
    // Default 中
    BMImageViewHorizontallyAlignmentCenter,
    // 右
    BMImageViewHorizontallyAlignmentRight,
};

typedef NS_ENUM(NSUInteger, BMImageViewVerticallyAlignment)
{
    // 上
    BMImageViewVerticallyAlignmentTop = 0,
    // Default 中
    BMImageViewVerticallyAlignmentCenter,
    // 下
    BMImageViewVerticallyAlignmentBottom
};

NS_ASSUME_NONNULL_BEGIN

@interface BMAlignedImageView : UIView

@property (nonatomic, strong, readonly) UIImageView *realImageView;

@property (nonatomic, assign) BMImageViewHorizontallyAlignment horizontallyAlignment;
@property (nonatomic, assign) BMImageViewVerticallyAlignment verticallyAlignment;

@property (nonatomic, assign) BOOL enableScaleUp;
@property (nonatomic, assign) BOOL enableScaleDown;

@property (nullable, nonatomic, strong) UIImage *image;
@property (nullable, nonatomic, strong) UIImage *highlightedImage;

@property (nonatomic, getter=isHighlighted, assign) BOOL highlighted;

@property (nullable, nonatomic, strong) NSArray<UIImage *> *animationImages;
@property (nullable, nonatomic, strong) NSArray<UIImage *> *highlightedAnimationImages;

@property (nonatomic, assign) NSTimeInterval animationDuration;
@property (nonatomic, assign) NSInteger      animationRepeatCount;

@property (null_resettable, nonatomic, strong) UIColor *tintColor;

- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;

- (instancetype)initWithImage:(nullable UIImage *)image;
- (instancetype)initWithImage:(nullable UIImage *)image highlightedImage:(nullable UIImage *)highlightedImage;

@end

NS_ASSUME_NONNULL_END
