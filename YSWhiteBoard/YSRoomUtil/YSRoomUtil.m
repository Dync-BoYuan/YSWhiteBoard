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

+ (NSDictionary *)convertWithData:(id)data
{
    if (!data)
    {
        return nil;
    }
    
    NSDictionary *dataDic = nil;
    
    if ([data isKindOfClass:[NSString class]])
    {
        NSString *tDataString = [NSString stringWithFormat:@"%@", data];
        NSData *tJsData = [tDataString dataUsingEncoding:NSUTF8StringEncoding];
        if (tJsData)
        {
            dataDic = [NSJSONSerialization JSONObjectWithData:tJsData
                                                      options:NSJSONReadingMutableContainers
                                                        error:nil];
        }
    }
    else if ([data isKindOfClass:[NSDictionary class]])
    {
        dataDic = (NSDictionary *)data;
    }
    else if ([data isKindOfClass:[NSData class]])
    {
        NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        dataDic = [YSRoomUtil convertWithData:dataStr];
    }
    
    return dataDic;
}

+ (NSString *)jsonStringWithDictionary:(NSDictionary *)dict
{
    NSError *error;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString = @"";
    if (!jsonData)
    {
        NSLog(@"%@", error);
    }
    else
    {
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    
    // 去掉字符串中的空格
    NSRange range = {0, jsonString.length};
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    
    //去掉字符串中的换行符
    NSRange range2 = {0, mutStr.length};
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    
    return mutStr;
}

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString
{
    if (jsonString == nil)
    {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err)
    {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    
    return dic;
}

@end
