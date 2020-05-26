//
//  YSMediaMarkView.h
//  YSLive
//
//  Created by jiang deng on 2019/11/18.
//  Copyright © 2019 YS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YSDrawView.h"

NS_ASSUME_NONNULL_BEGIN

@interface YSWBMediaMarkView : UIView

/// 接收处理VideoWhiteboard信令
///- (void)handleSignal:(NSDictionary *)dictionary isDel:(BOOL)isDel;

//恢复数据
///- (void)recoveryMediaMark;

///- (void)clear;

- (void)freshViewWithSavedSharpsData:(NSArray <NSDictionary *> *)sharpsDataArray videoRatio:(CGFloat)videoRatio;
- (void)freshViewWithData:(NSDictionary *)data savedSharpsData:(NSArray <NSDictionary *> *)sharpsDataArray;

- (void)clearDrawVideoMark;

@end

NS_ASSUME_NONNULL_END
