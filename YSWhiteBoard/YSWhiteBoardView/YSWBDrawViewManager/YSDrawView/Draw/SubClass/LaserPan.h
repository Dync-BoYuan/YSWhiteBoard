//
//  LaserPan.h
//  YSWhiteBoard
//
//  Created by 李合意 on 2019/2/19.
//  Copyright © 2019年 MAC-MiNi. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LaserPan : UIImageView

/// 偏移坐标
@property (nonatomic, assign) CGFloat offsetX;
@property (nonatomic, assign) CGFloat offsetY;

@end

NS_ASSUME_NONNULL_END
