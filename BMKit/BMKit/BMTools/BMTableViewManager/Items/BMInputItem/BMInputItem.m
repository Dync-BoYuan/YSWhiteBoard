//
//  BMInputItem.m
//  BMTableViewManagerSample
//
//  Created by DennisDeng on 2018/4/20.
//  Copyright © 2018年 DennisDeng. All rights reserved.
//

#import "BMInputItem.h"

@implementation BMInputItem

+ (instancetype)itemWithTitle:(NSString *)title value:(NSString *)value
{
    return [[BMInputItem alloc] initWithTitle:title value:value];
}

+ (instancetype)itemWithTitle:(NSString *)title value:(NSString *)value placeholder:(NSString *)placeholder
{
    return [[BMInputItem alloc] initWithTitle:title value:value placeholder:placeholder];
}

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.isShowHighlightBg = NO;
        
        self.editable = YES;
        
        self.contentMiddleGap = 0.0f;
    }
    
    return self;
}

- (instancetype)initWithTitle:(NSString *)title value:(NSString *)value
{
    return [self initWithTitle:title value:value placeholder:nil];
}

- (instancetype)initWithTitle:(NSString *)title value:(NSString *)value placeholder:(NSString *)placeholder
{
    self = [self init];
    
    if (self)
    {
        self.title = title;
        self.value = value;
        self.placeholder = placeholder;
    }
    
    return self;
}

- (void)setEditable:(BOOL)editable
{
    if (!self.enabled)
    {
        BMLog(@"Item is disabled");
        editable = NO;
    }
    
    _editable = editable;
}

@end
