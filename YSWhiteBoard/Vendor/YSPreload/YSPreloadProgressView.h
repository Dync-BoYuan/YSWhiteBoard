//
//  YSPreloadProgressView.h
//  EduClass
//
//  Created by ys on 2019/5/8.
//  Copyright © 2019 roadofcloud. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YSPreloadProgressView : UIView

- (instancetype)initWithSkipBlock:(void(^)(void))block;

- (void)setDownloadProgress:(float)downloadProgress unzipProgress:(float)unzipProgress;

@end

NS_ASSUME_NONNULL_END
