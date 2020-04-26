//
//  YSWBMp4ControlView.h
//  YSAll
//
//  Created by fzxm on 2020/1/7.
//  Copyright © 2020 YS. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol YSWBMp4ControlViewDelegate <NSObject>

- (void)playYSMp4ControlViewPlay:(BOOL)isPlay;

- (void)sliderYSMp4ControlView:(NSInteger)value;

@end

@interface YSWBMp4ControlView : UIView

@property (nonatomic, weak) id <YSWBMp4ControlViewDelegate> delegate;
@property (nonatomic, assign) BOOL isPlay;

- (void)setMediaStream:(NSTimeInterval)duration
                   pos:(NSTimeInterval)pos
                isPlay:(BOOL)isPlay
              fileName:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
