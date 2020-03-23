//
//  YSWKWebViewWeakDelegate.h
//  YSWhiteBroad
//
//  Created by MAC-MiNi on 2018/4/9.
//  Copyright © 2018年 MAC-MiNi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YSWKWebViewWeakDelegate : NSObject<WKScriptMessageHandler>

- (instancetype)initWithDelegate:(id <WKScriptMessageHandler>)scriptDelegate;

@end

NS_ASSUME_NONNULL_END
