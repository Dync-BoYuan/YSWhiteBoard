//
//  YSWBDrawViewManager.h
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/22.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "DocShowView.h"

NS_ASSUME_NONNULL_BEGIN

@interface YSWBDrawViewManager : NSObject

- (instancetype)initWithBackView:(UIView *)view webView:(WKWebView *)webView;

- (void)updateProperty:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
