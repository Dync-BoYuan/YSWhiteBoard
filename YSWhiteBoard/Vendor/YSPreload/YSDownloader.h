//
//  YSDownloader.h
//  Download
//
//  Created by ys on 2019/4/25.
//  Copyright © 2019 ys. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^ysProgressBlock)(float downloadProgress, float unzipProgress, NSString * _Nullable location, NSError * _Nullable error);

NS_ASSUME_NONNULL_BEGIN

@interface YSDownloader : NSObject <NSURLSessionDelegate, NSURLSessionDataDelegate>
@property (nonatomic, strong) NSString *fileID;

@property (nonatomic, strong) NSURLSessionDataTask *task;

+ (instancetype)sharedInstance;

/**
 下载文档

 @param url 文档地址
 @param block 下载回调：
                    downloadProgress:下载进度
                    unzipProgress:解压进度
                    location:解压完成地址
                    error:错误回报
 */
- (void)downloadWithURL:(NSURL *)url
                 fileID:(NSString *)fileID
          progressBlock:(ysProgressBlock)block;

- (void)cancelDownload;
- (void)removeLastPreloadFile;

@end

NS_ASSUME_NONNULL_END
