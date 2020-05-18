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

+ (BOOL)checkDataType:(id)data
{
    if (!data)
    {
        return YES;
    }
    if ([data isKindOfClass:[NSNumber class]] || [data isKindOfClass:[NSString class]] || [data isKindOfClass:[NSDictionary class]]  || [data isKindOfClass:[NSArray class]])
    {
        return YES;
    }
    return NO;
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

+ (BOOL)checkIsMedia:(NSString *)filetype
{
    if ([filetype isEqualToString:@"mp3"]
        || [filetype isEqualToString:@"mp4"]
        || [filetype isEqualToString:@"webm"]
        || [filetype isEqualToString:@"ogg"]
        || [filetype isEqualToString:@"wav"])
    {
        return YES;
    }
    
    return NO;
}

+ (BOOL)checkIsVideo:(NSString *)filetype
{
    if ([filetype isEqualToString:@"mp4"] || [filetype isEqualToString:@"webm"])
    {
        return YES;
    }
    
    return NO;
}

+ (NSString *)getFileIdFromSourceInstanceId:(NSString *)sourceInstanceId
{
    NSString *fileId = nil;
    if ([sourceInstanceId isEqualToString:YSDefaultWhiteBoardId])
    {
        fileId = @"0";
    }
    else if (sourceInstanceId.length > YSWhiteBoardId_Header.length)
    {
        fileId = [sourceInstanceId substringFromIndex:YSWhiteBoardId_Header.length];
    }
    
    return fileId;
}

+ (NSString *)getSourceInstanceIdFromFileId:(NSString *)fileId
{
    NSString *sourceInstanceId = [YSRoomUtil getwhiteboardIDFromFileId:fileId];
    
    return sourceInstanceId;
}

+ (NSString *)getwhiteboardIDFromFileId:(NSString *)fileId
{
    if ([fileId isEqualToString:@"0"])
    {
       return YSDefaultWhiteBoardId;
    }
    else
    {
        if ([[YSWhiteBoardManager shareInstance] isOneWhiteBoardView])
        {
            return YSDefaultWhiteBoardId;
        }
        
        NSString *whiteboardID = [NSString stringWithFormat:@"%@%@", YSWhiteBoardId_Header, fileId];
        return whiteboardID;
    }
}

+ (int)pubWhiteBoardMsg:(NSString *)msgName
                  msgID:(NSString *)msgID
                   data:(NSDictionary * _Nullable)dataDic
          extensionData:(NSDictionary * _Nullable)extensionData
        associatedMsgID:(NSString * _Nullable)associatedMsgID
                expires:(NSTimeInterval)expires
             completion:(completion_block _Nullable)completion
{
    if ([msgName isEqualToString:sYSSignalShowPage] || [msgName isEqualToString:sYSSignalExtendShowPage] || [msgName isEqualToString:sYSSignalMoreWhiteboardState] || [msgName isEqualToString:sYSSignalMoreWhiteboardGlobalState])
    {
        NSString *tellWho = [YSRoomInterface instance].localUser.peerID;
        NSString *associatedUserID = [YSRoomInterface instance].localUser.peerID;
        BOOL save = NO;
        if ([YSWhiteBoardManager shareInstance].isBeginClass)
        {
            if ([YSRoomInterface instance].localUser.role == YSUserType_Teacher)
            {
                tellWho = YSRoomPubMsgTellAll;
                associatedUserID = nil;
                save = YES;
            }
            else if ([YSRoomInterface instance].localUser.role == YSUserType_Student)
            {
                tellWho = YSRoomPubMsgTellAll;
                associatedUserID = nil;
                save = YES;
            }
        }
        
        if ([msgName isEqualToString:sYSSignalShowPage] || [msgName isEqualToString:sYSSignalExtendShowPage])
        {
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:dataDic];
            [dic bm_setBool:YES forKey:@"initiative"];
            dataDic = dic;
        }
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];

        NSString *dataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

        return [[YSRoomInterface instance] pubMsg:msgName msgID:msgID toID:tellWho data:dataString save:save extensionData:extensionData associatedMsgID:associatedMsgID associatedUserID:associatedUserID expires:expires completion:completion];
    }
    
    return -1;
}

+ (int)delWhiteBoardMsg:(NSString *)msgName
                  msgID:(NSString *)msgID
                   data:(NSDictionary * _Nullable)dataDic
             completion:(completion_block _Nullable)completion
{
    if ([msgName isEqualToString:sYSSignalShowPage] || [msgName isEqualToString:sYSSignalExtendShowPage])
    {
        NSString *tellWho = [YSRoomInterface instance].localUser.peerID;
        if ([YSWhiteBoardManager shareInstance].isBeginClass)
        {
            if ([YSRoomInterface instance].localUser.role == YSUserType_Teacher)
            {
                tellWho = YSRoomPubMsgTellAll;
            }
        }
        
        return [[YSRoomInterface instance] delMsg:msgName msgID:msgID toID:tellWho data:dataDic completion:completion];
    }
    
    return -1;
}

+ (NSString*)absoluteFileUrl:(NSString*)fileUrl withServerDic:(NSDictionary *)serverDic
{
    NSString *http = [serverDic bm_stringForKey:YSWhiteBoardWebProtocolKey];
    NSString *host = [serverDic bm_stringForKey:YSWhiteBoardWebHostKey];
    NSInteger port = [serverDic bm_intForKey:YSWhiteBoardWebPortKey];
    
    NSString *tUrl = [NSString stringWithFormat:@"%@://%@:%@%@", http, host, @(port), fileUrl];
    NSString *tdeletePathExtension = tUrl.stringByDeletingPathExtension;
    NSString *tNewURLString = [NSString stringWithFormat:@"%@-1.%@", tdeletePathExtension, tUrl.pathExtension];
    NSArray *tArray = [tNewURLString componentsSeparatedByString:@"/"];
    if ([tArray count] < 4)
    {
        return @"";
    }
    NSString *tNewURLString2 = [NSString stringWithFormat:@"%@//%@/%@/%@", [tArray objectAtIndex:0], [tArray objectAtIndex:1], [tArray objectAtIndex:2], [tArray objectAtIndex:3]];
    return tNewURLString2;
}

@end
