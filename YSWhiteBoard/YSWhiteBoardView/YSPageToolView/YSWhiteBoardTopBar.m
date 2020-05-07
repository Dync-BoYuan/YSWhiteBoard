//
//  YSWhiteBoardTopBar.m
//  YSWhiteBoard
//
//  Created by 马迪 on 2020/4/9.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import "YSWhiteBoardTopBar.h"


@interface YSWhiteBoardTopBar ()

///关闭按钮
@property (nonatomic, strong) UIButton *closeBtn;
///全屏
@property (nonatomic, strong) UIButton *fullScreenBtn;
///最小化
@property (nonatomic, strong) UIButton *minimizeBtn;
///标题
@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation YSWhiteBoardTopBar


- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor = YSWhiteBoard_TopBarBackGroudColor;
        [self setupTitleBar];
        
        UIPanGestureRecognizer * panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panGestureToMoveView:)];
        [self addGestureRecognizer:panGesture];
        
        UITapGestureRecognizer *oneTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapToBringVideoToFont:)];
        oneTap.numberOfTapsRequired = 1;
        [self addGestureRecognizer:oneTap];
        
    }
    return self;
}

- (void)setupTitleBar
{
    ///关闭按钮
    UIButton *closeBtn = [[UIButton alloc]initWithFrame:CGRectMake(self.bm_width - self.bm_height - 10, 5, self.bm_height-5, self.bm_height-5)];
    closeBtn.bm_centerY = self.bm_height/2;
    [closeBtn addTarget:self action:@selector(buttonsClick:) forControlEvents:UIControlEventTouchUpInside];
    [closeBtn setImage:[UIImage imageNamed:@"SplitScreen_close"] forState:UIControlStateNormal];
    closeBtn.contentMode = UIViewContentModeScaleAspectFill;
    closeBtn.tag = 3;
    closeBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self addSubview:closeBtn];
    self.closeBtn = closeBtn;
    closeBtn.hidden = YES;
    
    ///全屏
    UIButton *fullScreenBtn = [[UIButton alloc]initWithFrame:CGRectMake(closeBtn.bm_originX - self.bm_height - 10, 5, self.bm_height-5, self.bm_height-5)];
    fullScreenBtn.bm_centerY = self.bm_height/2;
    [fullScreenBtn addTarget:self action:@selector(buttonsClick:) forControlEvents:UIControlEventTouchUpInside];
    [fullScreenBtn setImage:[UIImage imageNamed:@"SplitScreen_fullScreen"] forState:UIControlStateNormal];
    fullScreenBtn.contentMode = UIViewContentModeScaleAspectFill;
    fullScreenBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    fullScreenBtn.tag = 2;
    [self addSubview:fullScreenBtn];
    self.fullScreenBtn = fullScreenBtn;
    fullScreenBtn.hidden = YES;
    
    ///最小化
    UIButton *minimizeBtn = [[UIButton alloc]initWithFrame:CGRectMake(fullScreenBtn.bm_originX - self.bm_height - 10, 5, self.bm_height-5, self.bm_height-5)];
    minimizeBtn.bm_centerY = self.bm_height/2;
    [minimizeBtn addTarget:self action:@selector(buttonsClick:) forControlEvents:UIControlEventTouchUpInside];
    [minimizeBtn setImage:[UIImage imageNamed:@"SplitScreen_minimize_normal"] forState:UIControlStateNormal];
    minimizeBtn.contentMode = UIViewContentModeScaleAspectFill;
    minimizeBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    minimizeBtn.tag = 1;
    [self addSubview:minimizeBtn];
    self.minimizeBtn = minimizeBtn;
    minimizeBtn.hidden = YES;
    
    ///标题
    UILabel * titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, minimizeBtn.bm_originX - 15-2, self.bm_height)];
    titleLabel.bm_centerY = self.bm_height/2;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:14];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [self addSubview:titleLabel];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.titleLabel = titleLabel;
         
    if ([[YSWhiteBoardManager shareInstance] isCanControlWhiteBoardView])
    {
        closeBtn.hidden = NO;
        fullScreenBtn.hidden = NO;
        minimizeBtn.hidden = NO;
    }
}

- (void)setIsCurrent:(BOOL)isCurrent
{
    _isCurrent = isCurrent;
    
    if (isCurrent)
    {
        [self.closeBtn setImage:[UIImage imageNamed:@"SplitScreen_close"] forState:UIControlStateNormal];
        [self.fullScreenBtn setImage:[UIImage imageNamed:@"SplitScreen_fullScreen"] forState:UIControlStateNormal];
        [self.minimizeBtn setImage:[UIImage imageNamed:@"SplitScreen_minimize_normal"] forState:UIControlStateNormal];
    }
    else
    {
        [self.closeBtn setImage:[UIImage imageNamed:@"SplitScreen_close_noFocus"] forState:UIControlStateNormal];
        [self.fullScreenBtn setImage:[UIImage imageNamed:@"SplitScreen_fullScreen_noFocus"] forState:UIControlStateNormal];
        [self.minimizeBtn setImage:[UIImage imageNamed:@"SplitScreen_minimize_noFocus"] forState:UIControlStateNormal];
    }
}

- (void)setTitleString:(NSString *)titleString
{
    _titleString = titleString;
    self.titleLabel.text = titleString;
}


- (void)buttonsClick:(UIButton *)sender
{
    if (_barButtonsClick)
    {
        _barButtonsClick(sender);
    }
}

#pragma mark 拖拽 手势
///课件拖拽事件
- (void)panGestureToMoveView:(UIPanGestureRecognizer *)pan
{
    if (![[YSWhiteBoardManager shareInstance] isCanControlWhiteBoardView])
    {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(panToMoveWhiteBoardView:withGestureRecognizer:)])
    {
        [self.delegate panToMoveWhiteBoardView:self.superview withGestureRecognizer:pan];
    }
}

- (void)tapToBringVideoToFont:(UITapGestureRecognizer *)tapGesture
{
    if (![[YSWhiteBoardManager shareInstance] isCanControlWhiteBoardView])
    {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(clickToBringVideoToFront:)])
    {
        [self.delegate clickToBringVideoToFront:self.superview];
    }
}

@end
