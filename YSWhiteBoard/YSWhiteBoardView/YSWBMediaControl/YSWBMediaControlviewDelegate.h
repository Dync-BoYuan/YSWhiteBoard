//
//  YSWBMediaControlviewDelegate.h
//  YSWhiteBoard
//
//  Created by jiang deng on 2020/4/27.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#ifndef YSWBMediaControlviewDelegate_h
#define YSWBMediaControlviewDelegate_h

@protocol YSWBMediaControlviewDelegate <NSObject>

@optional

- (void)mediaControlviewPlay:(BOOL)isPlay;

- (void)mediaControlviewSlider:(NSTimeInterval)value;

- (void)mediaControlviewClose;

@end

#endif /* YSWBMediaControlviewDelegate_h */
