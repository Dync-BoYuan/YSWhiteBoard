//
//  NSURLProtocol+YSWhiteBoard.m
//  YSWhiteBoard
//
//  Created by jiang deng on 2019/12/9.
//  Copyright © 2019 YS. All rights reserved.
//

#import "NSURLProtocol+YSWhiteBoard.h"
#import <WebKit/WebKit.h>

/**
 * The functions below use some undocumented APIs, which may lead to rejection by Apple.
 */

FOUNDATION_STATIC_INLINE Class ContextControllerClass()
{
    static Class cls;
    if (!cls)
    {
        cls = [[[WKWebView new] valueForKey:@"browsingContextController"] class];
    }
    return cls;
}

FOUNDATION_STATIC_INLINE SEL RegisterSchemeSelector()
{
    return NSSelectorFromString(@"registerSchemeForCustomProtocol:");
}

FOUNDATION_STATIC_INLINE SEL UnregisterSchemeSelector()
{
    return NSSelectorFromString(@"unregisterSchemeForCustomProtocol:");
}

@implementation NSURLProtocol (YSWhiteBoard)

+ (void)ys_registerScheme:(NSString *)scheme
{
    Class cls = ContextControllerClass();
    SEL sel = RegisterSchemeSelector();
    if ([(id)cls respondsToSelector:sel])
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:scheme];
#pragma clang diagnostic pop
    }
}

+ (void)ys_unregisterScheme:(NSString *)scheme
{
    Class cls = ContextControllerClass();
    SEL sel = UnregisterSchemeSelector();
    if ([(id)cls respondsToSelector:sel])
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:scheme];
#pragma clang diagnostic pop
    }
}

@end
