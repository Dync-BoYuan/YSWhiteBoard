//
//  YSMediaFileModel.h
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/4/26.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YSMediaFileModel : NSObject

// Id
@property (nonatomic, strong) NSString *fileid;
// 文件名
@property (nonatomic, strong) NSString *filename;

// 音频
@property (nonatomic, assign) BOOL isAudio;
// 视频
@property (nonatomic, assign) BOOL isVideo;

@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;

// 暂停
@property (nonatomic, assign) BOOL isPause;


+ (nullable instancetype)mediaFileModelWithDic:(NSDictionary *)dic;
- (void)updateWithDic:(NSDictionary *)dic;

@end

NS_ASSUME_NONNULL_END
