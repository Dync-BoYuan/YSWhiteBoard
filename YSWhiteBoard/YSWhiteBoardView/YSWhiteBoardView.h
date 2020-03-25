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

NS_ASSUME_NONNULL_BEGIN

@interface YSWhiteBoardView : UIView

@property (nonatomic, strong, readonly) NSString *fileId;

/// web文档
@property (nonatomic, strong, readonly) YSWBWebViewManager *webViewManager;
/// 普通文档
@property (nonatomic, strong, readonly) YSWBDrawViewManager *drawViewManager;

- (instancetype)initWithFrame:(CGRect)frame fileId:(NSString *)fileId loadFinishedBlock:(nullable  wbLoadFinishedBlock)loadFinishedBlock;

/// 用户属性改变通知
- (void)userPropertyChanged:(NSDictionary *)message;
/// 用户离开通知
- (void)participantLeaved:(NSDictionary *)message;
/// 用户进入通知
- (void)participantJoin:(NSDictionary *)message;
/// 自己被踢出教室通知
- (void)participantEvicted:(NSDictionary *)message;
/// 收到远端pubMsg消息通知
- (void)remotePubMsg:(NSDictionary *)message;







// 页面刷新尺寸
- (void)refreshWhiteBoardWithFrame:(CGRect)frame;

@end

NS_ASSUME_NONNULL_END
