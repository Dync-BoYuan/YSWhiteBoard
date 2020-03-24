//
//  LaserPan.m
//  YSWhiteBoard
//
//  Created by 李合意 on 2019/2/19.
//  Copyright © 2019年 MAC-MiNi. All rights reserved.
//

#import "LaserPan.h"

@implementation LaserPan

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame {
 
    self = [super initWithFrame:frame];
    if (self) {
        
        self.image 		= [UIImage imageNamed:@"ys_laser_point"];
        
    }
    
    return self;
}
@end
