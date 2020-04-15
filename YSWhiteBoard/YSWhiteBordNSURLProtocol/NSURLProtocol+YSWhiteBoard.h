//
//  NSURLProtocol+YSWhiteBoard.h
//  YSWhiteBoard
//
//  Created by jiang deng on 2019/12/9.
//  Copyright © 2019 YS. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLProtocol (YSWhiteBoard)

+ (void)ys_registerScheme:(NSString *)scheme;
+ (void)ys_unregisterScheme:(NSString *)scheme;

@end

NS_ASSUME_NONNULL_END
