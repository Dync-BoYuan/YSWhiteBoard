//
//  YSMp3Controlview.m
//  YSAll
//
//  Created by fzxm on 2020/1/8.
//  Copyright © 2020 YS. All rights reserved.
//

#import "YSWBMp3Controlview.h"
#import "YSWBMediaSlider.h"

@interface YSWBMp3Controlview ()

//@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) YSWBMediaSlider *sliderView;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, strong) UIButton *closeBtn;

@end

@implementation YSWBMp3Controlview

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
    if ([UIDevice bm_isiPad])
    {
        self.playBtn.frame = CGRectMake(30, 20, 26, 33);
        
//        self.closeBtn.frame = CGRectMake(self.bm_width - 30, 25, 25, 25);
        
        self.nameLabel.frame = CGRectMake(CGRectGetMaxX(self.playBtn.frame) + 12, 18, self.bm_width - 220, 17);
        //    self.nameLabel.bm_left = self.playBtn.bm_right + 12;
        
        self.timeLabel.frame = CGRectMake( 0, 18, 100, 17);
        self.timeLabel.bm_right = self.bm_width - 60;
        
        [self.nameLabel bm_setLeft:self.playBtn.bm_right + 12 right:self.timeLabel.bm_left - 5];
        
        self.sliderView.frame = CGRectMake(0, 0,self.bm_width - 130, 10);
        self.sliderView.bm_top = self.nameLabel.bm_bottom + 10;
        self.sliderView.bm_left = self.playBtn.bm_right + 12;
        
//        self.closeBtn.frame = CGRectMake(0, 25, 25, 25);
        self.closeBtn.bm_right = self.bm_width - 20;
    }
    else
    {
        self.playBtn.frame = CGRectMake(15, 20, 20, 20);
        
        self.closeBtn.frame = CGRectMake(self.bm_width - 30, 20, 20, 20);
        
        self.timeLabel.font = [UIFont fontWithName:@"Helvetica" size:10];
        self.timeLabel.frame = CGRectMake( 0, 10, 65, 17);
        self.timeLabel.bm_right = self.closeBtn.bm_left - 5;
        
        self.nameLabel.font = [UIFont systemFontOfSize:10];
        self.nameLabel.frame = CGRectMake(10, 10, 10, 17);
        [self.nameLabel bm_setLeft:self.playBtn.bm_right + 5 right:self.timeLabel.bm_left - 5];
        
        self.sliderView.frame = CGRectMake(0, 0,self.bm_width - 45 - 30, 5);
        self.sliderView.bm_top = self.nameLabel.bm_bottom + 10;
        self.sliderView.bm_left = self.playBtn.bm_right + 5;
    }
}

- (void)setup
{
    UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self addSubview:playBtn];

    self.playBtn = playBtn;
    [playBtn setBackgroundImage:[UIImage imageNamed:@"scteacher_media_play_Selected"] forState:UIControlStateNormal];
    [playBtn setBackgroundImage:[UIImage imageNamed:@"scteacher_media_play_Normal"] forState:UIControlStateSelected];
    [playBtn addTarget:self action:@selector(playBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *nameLabel = [[UILabel alloc] init];
    [self addSubview:nameLabel];
    self.nameLabel = nameLabel;
    nameLabel.font = [UIFont systemFontOfSize:12];
    nameLabel.textColor = [UIColor whiteColor];
    nameLabel.textAlignment = NSTextAlignmentLeft;

    UILabel *timeLabel =  [[UILabel alloc] initWithFrame:CGRectMake( 0, 18, 100, 17)];
    [self addSubview:timeLabel];
    self.timeLabel = timeLabel;
    timeLabel.font = [UIFont systemFontOfSize:12];
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

    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeBtn = closeBtn;
    [self addSubview:self.closeBtn];
    self.closeBtn.frame = CGRectMake(0, 25, 25, 25);
    [self.closeBtn setBackgroundImage:[UIImage imageNamed:@"ysteacher_closemp4_normal"] forState:UIControlStateNormal];
    [self.closeBtn addTarget:self action:@selector(closeBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setMediaStream:(NSTimeInterval)duration pos:(NSTimeInterval)pos isPlay:(BOOL)isPlay fileName:(nonnull NSString *)fileName
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
    self.isPlay = isPlay;
    [self.sliderView setValue:value animated:NO];
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

    if ([self.delegate respondsToSelector:@selector(sliderMp3ControlView:)])
    {
        [self.delegate sliderMp3ControlView:sender.value * self.duration];
    }
    
    [[YSRoomInterface instance] pauseMediaFile:NO];
}

- (void)playBtnClicked:(UIButton *)btn
{
    btn.selected = !btn.selected;
    if ([self.delegate respondsToSelector:@selector(playMp3ControlViewPlay:)])
    {
        [self.delegate playMp3ControlViewPlay:btn.selected];
    }
}

- (void)closeBtnClicked:(UIButton *)btn
{
    if ([self.delegate respondsToSelector:@selector(closeMp3ControlView)])
    {
        [self.delegate closeMp3ControlView];
    }
}

- (NSString *)countDownStringDateFromTs:(NSUInteger)count
{
    if (count <= 0)
    {
        return @"00:00";
    }

    NSUInteger min = count / BMSECONDS_IN_MINUTE;
    NSUInteger second = count % BMSECONDS_IN_MINUTE;
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)min, (long)second];
}

@end
