//
//  YSWBMp4ControlView.h
//  YSAll
//
//  Created by fzxm on 2020/1/7.
//  Copyright © 2020 YS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YSWBMediaControlviewDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface YSWBMp4ControlView : UIView

@property (nonatomic, weak) id <YSWBMediaControlviewDelegate> delegate;
@property (nonatomic, assign) BOOL isPlay;

- (void)setMediaStream:(NSTimeInterval)duration
                   pos:(NSTimeInterval)pos
                isPlay:(BOOL)isPlay
              fileName:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
