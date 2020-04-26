//
//  YSMp3Controlview.h
//  YSAll
//
//  Created by fzxm on 2020/1/8.
//  Copyright © 2020 YS. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol YSWBMp3ControlviewDelegate <NSObject>

- (void)playMp3ControlViewPlay:(BOOL)isPlay;

- (void)sliderMp3ControlView:(NSInteger)value;
- (void)closeMp3ControlView;

@end

@interface YSWBMp3Controlview : UIView
@property (nonatomic, weak) id <YSWBMp3ControlviewDelegate> delegate;
@property (nonatomic, strong) UIButton *playBtn;

@property (nonatomic, assign) BOOL isPlay;

- (void)setMediaStream:(NSTimeInterval)duration
                   pos:(NSTimeInterval)pos
                isPlay:(BOOL)isPlay
              fileName:(NSString *)fileName;
@end

NS_ASSUME_NONNULL_END
