//
//  UIView+Layout.h
//
//  Created by 谭真 on 15/2/24.
//  Copyright © 2015年 谭真. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    BMTZOscillatoryAnimationToBigger,
    BMTZOscillatoryAnimationToSmaller,
} BMTZOscillatoryAnimationType;

@interface UIView (BMLayout)

@property (nonatomic) CGFloat bmtz_left;        ///< Shortcut for frame.origin.x.
@property (nonatomic) CGFloat bmtz_top;         ///< Shortcut for frame.origin.y
@property (nonatomic) CGFloat bmtz_right;       ///< Shortcut for frame.origin.x + frame.size.width
@property (nonatomic) CGFloat bmtz_bottom;      ///< Shortcut for frame.origin.y + frame.size.height
@property (nonatomic) CGFloat bmtz_width;       ///< Shortcut for frame.size.width.
@property (nonatomic) CGFloat bmtz_height;      ///< Shortcut for frame.size.height.
@property (nonatomic) CGFloat bmtz_centerX;     ///< Shortcut for center.x
@property (nonatomic) CGFloat bmtz_centerY;     ///< Shortcut for center.y
@property (nonatomic) CGPoint bmtz_origin;      ///< Shortcut for frame.origin.
@property (nonatomic) CGSize  bmtz_size;        ///< Shortcut for frame.size.

+ (void)bm_showOscillatoryAnimationWithLayer:(CALayer *)layer type:(BMTZOscillatoryAnimationType)type;

@end
