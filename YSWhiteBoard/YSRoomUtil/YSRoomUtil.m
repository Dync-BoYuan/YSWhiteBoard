//
//  YSRoomUtil.m
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/23.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import "YSRoomUtil.h"

@implementation YSRoomUtil

+ (NSString *)getCurrentLanguage
{
    NSArray *language = [NSLocale preferredLanguages];
    if ([language objectAtIndex:0]) {
        NSString *currentLanguage = [language objectAtIndex:0];
        if ([currentLanguage length] >= 7 &&
            [[currentLanguage substringToIndex:7] isEqualToString:@"zh-Hans"])
        {
            return @"ch";
        }

        if ([currentLanguage length] >= 7 &&
            [[currentLanguage substringToIndex:7] isEqualToString:@"zh-Hant"])
        {
            return @"tw";
        }

        if ([currentLanguage length] >= 3 &&
            [[currentLanguage substringToIndex:3] isEqualToString:@"en-"])
        {
            return @"en";
        }
    }

    return @"ch";
}

@end