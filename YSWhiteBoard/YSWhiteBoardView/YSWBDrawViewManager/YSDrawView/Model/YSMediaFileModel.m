//
//  YSMediaFileModel.m
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/4/26.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import "YSMediaFileModel.h"

@implementation YSMediaFileModel

+ (instancetype)mediaFileModelWithDic:(NSDictionary *)dic
{
    if (![dic bm_isNotEmptyDictionary])
    {
        return nil;
    }
    
    NSString *fileId = [dic bm_stringTrimForKey:@"fileid"];
    if (![fileId bm_isNotEmpty])
    {
        return nil;
    }
    
    YSMediaFileModel *mediaModel = [[YSMediaFileModel alloc] init];
    [mediaModel updateWithDic:dic];
    
    if ([mediaModel.fileid bm_isNotEmpty])
    {
        return mediaModel;
    }
    else
    {
        return nil;
    }
}

- (void)updateWithDic:(NSDictionary *)dic
{
    if (![dic bm_isNotEmptyDictionary])
    {
        return;
    }
    
    // id不存在不修改
    
    // 文件Id
    NSString *fileid = [dic bm_stringTrimForKey:@"fileid"];
    if (![fileid bm_isNotEmpty])
    {
        return;
    }
    self.fileid = fileid;

    // 文件名
    self.filename = [dic bm_stringTrimForKey:@"filename"];

    // 音频
    self.isAudio = [dic bm_boolForKey:@"audio"];
    // 视频
    self.isVideo = [dic bm_boolForKey:@"video"];

    self.width = [dic bm_doubleForKey:@"width"];
    self.height = [dic bm_doubleForKey:@"height"];
}

@end
