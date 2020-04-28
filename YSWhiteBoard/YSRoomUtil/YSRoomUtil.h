//
//  YSRoomUtil.h
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/3/23.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YSRoomUtil : NSObject

/// 获取设备语言
+ (NSString *)getCurrentLanguage;

+ (BOOL)checkDataType:(id)data;

/// 将数据转换成字典类型NSDictionary
+ (NSDictionary *)convertWithData:(id)data;

+ (BOOL)checkIsMedia:(NSString *)filetype;
+ (BOOL)checkIsVideo:(NSString *)filetype;

+ (NSString *)jsonStringWithDictionary:(NSDictionary *)dict;
+ (nullable NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;

+ (NSString *)getFileIdFromSourceInstanceId:(NSString *)sourceInstanceId;
+ (NSString *)getSourceInstanceIdFromFileId:(NSString *)fileId;
+ (NSString *)getwhiteboardIDFromFileId:(NSString *)fileId;

+ (int)pubWhiteBoardMsg:(NSString *)msgName
                  msgID:(NSString *)msgID
                   data:(NSDictionary * _Nullable)dataDic
          extensionData:(NSDictionary * _Nullable)extensionData
        associatedMsgID:(NSString * _Nullable)associatedMsgID
                expires:(NSTimeInterval)expires
             completion:(completion_block _Nullable)completion;

+ (int)delWhiteBoardMsg:(NSString *)msgName
                  msgID:(NSString *)msgID
                   data:(NSObject * _Nullable)data
             completion:(completion_block _Nullable)completion;

+ (NSString *)absoluteFileUrl:(NSString*)fileUrl withServerDic:(NSDictionary *)serverDic;

@end

NS_ASSUME_NONNULL_END
