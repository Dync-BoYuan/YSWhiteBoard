//
//  UIView+BMCountDownManager.h
//  BMTableViewManagerSample
//
//  Created by jiang deng on 2018/11/14.
//Copyright © 2018 DJ. All rights reserved.
//

#import "BMCountDownManager.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (BMCountDownManager)

// 倒计时标识
@property (nullable, nonatomic, copy) id countDownIdentifier;
// 每秒触发响应事件
@property (nullable, nonatomic, copy) BMCountDownProcessBlock countDownProcessBlock;

// 启动倒计时，计时timeInterval
- (void)startCountDownWithTimeInterval:(NSInteger)timeInterval;

// 暂停倒计时
- (void)pauseCountDown;
// 继续倒计时
- (void)continueCountDown;

// 停止倒计时
- (void)stopCountDown;

@end

NS_ASSUME_NONNULL_END
