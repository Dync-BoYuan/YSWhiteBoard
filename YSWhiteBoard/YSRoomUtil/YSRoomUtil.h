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

/// 将数据转换成字典类型NSDictionary
+ (NSDictionary *)convertWithData:(id)data;

+ (NSString *)jsonStringWithDictionary:(NSDictionary *)dict;
+ (nullable NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;

+ (NSString *)getFileIdFromSourceInstanceId:(NSString *)sourceInstanceId;
+ (NSString *)getSourceInstanceIdFromFileId:(NSString *)fileId;
+ (NSString *)getwhiteboardIDFromFileId:(NSString *)fileId;

@end

NS_ASSUME_NONNULL_END
