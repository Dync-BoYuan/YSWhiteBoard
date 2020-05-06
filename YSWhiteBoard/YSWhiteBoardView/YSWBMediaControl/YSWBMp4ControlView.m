//
//  YSMp4ControlView.m
//  YSAll
//
//  Created by fzxm on 2020/1/7.
//  Copyright © 2020 YS. All rights reserved.
//

#import "YSWBMp4ControlView.h"
#import "YSWBMediaSlider.h"

@interface YSWBMp4ControlView ()

@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) YSWBMediaSlider *sliderView;
@property (nonatomic, assign) NSInteger duration;

@end

@implementation YSWBMp4ControlView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self setup];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.playBtn.frame = CGRectMake(20, 11, 20, 20);
//    self.playBtn.bm_centerY = self.bm_centerY;
    
    self.nameLabel.frame = CGRectMake( CGRectGetMaxX(self.playBtn.frame) + 15, 4, self.bm_width - 140, 10);
//    self.nameLabel.bm_left = self.playBtn.bm_right + 12;
    
    self.timeLabel.frame = CGRectMake(CGRectGetMaxX(self.nameLabel.frame) + 10 , 4, self.bm_width - self.nameLabel.bm_right - 30, 10);
//    self.timeLabel.bm_right = self.bm_right - 40;
    
    self.sliderView.frame = CGRectMake(0, 0, self.bm_width - 65, 10);
    self.sliderView.bm_top = self.nameLabel.bm_bottom + 10;
    self.sliderView.bm_left = self.playBtn.bm_right + 15;
}

- (void)setup
{
    
    self.backgroundColor = [UIColor bm_colorWithHex:0x6D7278 alpha:0.39];
    UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self addSubview:playBtn];

    self.playBtn = playBtn;
    [playBtn setBackgroundImage:[UIImage imageNamed:@"scteacher_media_play_Selected"] forState:UIControlStateNormal];
    [playBtn setBackgroundImage:[UIImage imageNamed:@"scteacher_media_play_Normal"] forState:UIControlStateSelected];
    [playBtn addTarget:self action:@selector(playBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *nameLabel = [[UILabel alloc] init];
    [self addSubview:nameLabel];
    self.nameLabel = nameLabel;
    nameLabel.font = [UIFont systemFontOfSize:8];
    nameLabel.textColor = [UIColor whiteColor];
    nameLabel.textAlignment = NSTextAlignmentLeft;

    UILabel *timeLabel =  [[UILabel alloc] initWithFrame:CGRectMake( 0, 18, 100, 17)];
    [self addSubview:timeLabel];
    self.timeLabel = timeLabel;
    timeLabel.font = [UIFont systemFontOfSize:8];
    timeLabel.textColor = [UIColor whiteColor];
    timeLabel.textAlignment = NSTextAlignmentRight;
    
    YSWBMediaSlider *sliderView = [[YSWBMediaSlider alloc] init];
    [self addSubview:sliderView];
    self.sliderView = sliderView;
//    sliderView.continuous = NO;
    sliderView.minimumTrackTintColor = [UIColor bm_colorWithHex:0xFFE895];
    sliderView.maximumTrackTintColor = [UIColor bm_colorWithHex:0xDEEAFF];
//    sliderView.thumbTintColor = [UIColor bm_colorWithHex:0x9DBEF3];
    [sliderView setThumbImage:[UIImage imageNamed:@"scteacher_sliderView_Normal"] forState:UIControlStateNormal];
    [sliderView addTarget:self action:@selector(sliderViewChange:) forControlEvents:UIControlEventValueChanged];
    [sliderView addTarget:self action:@selector(sliderViewStart:) forControlEvents:UIControlEventTouchDown];
    [sliderView addTarget:self action:@selector(sliderViewEnd:) forControlEvents:UIControlEventTouchUpInside];
    [sliderView addTarget:self action:@selector(sliderViewEnd:) forControlEvents:UIControlEventTouchUpOutside];
}

- (void)setMediaStream:(NSTimeInterval)duration pos:(NSTimeInterval)pos isPlay:(BOOL)isPlay fileName:(nonnull NSString *)fileName
{
    if (isPlay)
    {
        self.duration = duration;
        self.nameLabel.text = fileName;
        NSInteger current = pos;
        if (current <= 0)
        {
            current = 0;
        }
        NSString *currentTime = [self countDownStringDateFromTs:current/1000];
        NSString *totalTime = [self countDownStringDateFromTs:duration/1000];
        self.timeLabel.text = [NSString stringWithFormat:@"%@/%@",currentTime,totalTime];
        
        CGFloat value = pos / duration;
        [self.sliderView setValue:value animated:NO];
    }
    
    self.isPlay = isPlay;
}

- (void)setIsPlay:(BOOL)isPlay
{
    _isPlay = isPlay;
    self.playBtn.selected = !isPlay;
}

- (void)sliderViewChange:(YSWBMediaSlider *)sender
{
    NSString *currentTime = [self countDownStringDateFromTs:self.duration * sender.value/1000];
    NSString *totalTime = [self countDownStringDateFromTs:self.duration/1000];
    self.timeLabel.text = [NSString stringWithFormat:@"%@/%@",currentTime,totalTime];
}

- (void)sliderViewStart:(YSWBMediaSlider *)sender
{
    [[YSRoomInterface instance] pauseMediaFile:YES];
}

- (void)sliderViewEnd:(YSWBMediaSlider *)sender
{
    BMLog(@"sliderViewEnd: %@ ===========================", @(sender.value));

    if ([self.delegate respondsToSelector:@selector(mediaControlviewSlider:)])
    {
        [self.delegate mediaControlviewSlider:sender.value * self.duration];
    }
    
    [[YSRoomInterface instance] pauseMediaFile:NO];
}

- (void)playBtnClicked:(UIButton *)btn
{
    btn.selected = !btn.selected;
    if ([self.delegate respondsToSelector:@selector(mediaControlviewPlay:)])
    {
        [self.delegate mediaControlviewPlay:btn.selected];
    }
}

- (void)hideMp4ControlViewOutsidePause:(BOOL)hide
{
    if (hide)
    {
        self.backgroundColor = [UIColor clearColor];
    }
    else
    {
        self.backgroundColor = [UIColor bm_colorWithHex:0x6D7278 alpha:0.39];
    }
    self.nameLabel.hidden = hide;
    self.timeLabel.hidden = hide;
    self.sliderView.hidden = hide;

}

- (NSString *)countDownStringDateFromTs:(NSUInteger)count
{
    if (count <= 0)
    {
        return @"00:00";
    }

    NSUInteger min = count/BMSECONDS_IN_MINUTE;
    NSUInteger second = count%BMSECONDS_IN_MINUTE;
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)min, (long)second];
}

@end
