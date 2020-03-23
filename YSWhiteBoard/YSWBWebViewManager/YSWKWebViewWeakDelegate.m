//
//  YSWKWebViewWeakDelegate.m
//  YSWhiteBroad
//
//  Created by MAC-MiNi on 2018/4/9.
//  Copyright © 2018年 MAC-MiNi. All rights reserved.
//

#import "YSWKWebViewWeakDelegate.h"

@interface YSWKWebViewWeakDelegate ()

@property (nonatomic, weak) id <WKScriptMessageHandler> scriptDelegate;

@end


@implementation YSWKWebViewWeakDelegate

- (instancetype)initWithDelegate:(id <WKScriptMessageHandler>)scriptDelegate
{
    self = [super init];
    if(self)
    {
        self.scriptDelegate = scriptDelegate;
    }
    
    return self;
    
}

- (void)userContentController:(WKUserContentController*)userContentController didReceiveScriptMessage:(WKScriptMessage*)message
{
    if (self.scriptDelegate && [self.scriptDelegate respondsToSelector:@selector(userContentController:didReceiveScriptMessage:)])
    {
        [self.scriptDelegate userContentController:userContentController didReceiveScriptMessage:message];
    }
}

@end
