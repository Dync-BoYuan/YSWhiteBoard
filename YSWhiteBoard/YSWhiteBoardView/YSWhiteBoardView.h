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

- (void)userPropertyChanged:(NSDictionary *)message;


// 页面刷新尺寸
- (void)refreshWhiteBoardWithFrame:(CGRect)frame;

@end

NS_ASSUME_NONNULL_END
