//
//  YSBrushToolsConfigs.m
//  YSWhiteBoard
//
//  Created by 马迪 on 2020/4/2.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import "YSBrushToolsConfigs.h"

@implementation YSBrushToolsConfigs

- (void)setColorHex:(NSString *)colorHex
{
    _colorHex = colorHex;
    if (!colorHex)
    {
        colorHex = @"";
    }
}



@end
