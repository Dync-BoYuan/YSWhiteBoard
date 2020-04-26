//
//  YSMediaSlider.m
//  YSAll
//
//  Created by fzxm on 2020/1/7.
//  Copyright © 2020 YS. All rights reserved.
//

#import "YSWBMediaSlider.h"

@implementation YSWBMediaSlider

// 子类重写

//
///// 设置track（滑条）尺寸
//- (CGRect)trackRectForBounds:(CGRect)bounds
//{
//    CGRect minimumValueImageRect = [self minimumValueImageRectForBounds:bounds];
//    CGRect maximumValueImageRect = [self maximumValueImageRectForBounds:bounds];
//    CGFloat margin = 2;
//    CGFloat H = 10;
//    CGFloat Y =( bounds.size.height - H ) *.5f;
//    CGFloat X = CGRectGetMaxX(minimumValueImageRect) + margin;
//    CGFloat W = CGRectGetMinX(maximumValueImageRect) - X - margin;
//    return CGRectMake(X, Y, W, H);
//}
//
///// 设置thumb（滑块）尺寸
//- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value
//{
//    
//    CGFloat Ww = 17;
//    CGFloat margin = Ww *.5f + 2;
//    /// 滑块的滑动区域宽度
//    CGFloat maxWidth = CGRectGetWidth(rect) + 2 * margin;
//    /// 每次偏移量
//    CGFloat offset = (maxWidth - Ww)/(self.maximumValue - self.minimumValue);
//    
//    CGFloat H = 24;
//    CGFloat Y = (bounds.size.height - H ) *.5f;
//    CGFloat W = Ww;
//    CGFloat X = CGRectGetMinX(rect) - margin + offset *(value-self.minimumValue);
//    CGRect r =  CGRectMake(X, Y, W, H);
//    return r;
//}
@end
