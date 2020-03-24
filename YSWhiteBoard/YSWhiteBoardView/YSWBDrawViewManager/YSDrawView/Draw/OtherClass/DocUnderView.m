//
//  DocUnderView.m
//  YSWhiteBoard
//
//  Created by ys on 2019/3/7.
//  Copyright © 2019 MAC-MiNi. All rights reserved.
//

#import "DocUnderView.h"

@implementation DocUnderView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (CGRectContainsPoint(self.subviews.firstObject.frame, point)) {
        return YES;
    }
    return NO;
}

@end
