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

@property (nonatomic, strong) NSMutableDictionary *fileDictionary;

- (instancetype)initWithBackView:(UIView *)view webView:(WKWebView *)webView;

- (void)clearAfterClass;

- (void)updateProperty:(NSDictionary *)dictionary;
- (void)receiveWhiteBoardMessage:(NSMutableDictionary *)dictionary isDelMsg:(BOOL)isDel;
- (void)whiteBoardOnRoomConnectedUserlist:(NSNumber *)code response:(NSDictionary *)response;

@end

NS_ASSUME_NONNULL_END
