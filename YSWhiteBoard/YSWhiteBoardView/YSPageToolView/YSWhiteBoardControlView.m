//
//  YSWhiteBoardControlView.m
//  YSWhiteBoard
//
//  Created by 马迪 on 2020/4/23.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import "YSWhiteBoardControlView.h"

@interface YSWhiteBoardControlView ()

///由全屏还原的按钮
@property (nonatomic, weak) UIButton * returnBtn;
///删除按钮
@property (nonatomic, weak) UIButton * cancleBtn;

@end


@implementation YSWhiteBoardControlView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor = [UIColor colorWithRed:222/255.0 green:234/255.0 blue:255/255.0 alpha:0.8];
        self.layer.cornerRadius = frame.size.height/2;
        self.layer.masksToBounds = YES;

        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    CGFloat btnHeight = 24;
    
    //由全屏还原的按钮
    UIButton * returnBtn = [[UIButton alloc]initWithFrame:CGRectMake(3, 0, btnHeight, btnHeight)];
    [returnBtn setImage:[UIImage imageNamed:@"SplitScreen_recovery"] forState:UIControlStateNormal];
    returnBtn.contentMode = UIViewContentModeScaleAspectFill;
    [returnBtn addTarget:self action:@selector(buttonsClick:) forControlEvents:UIControlEventTouchUpInside];
    returnBtn.tag = 1;
    [self addSubview:returnBtn];
    self.returnBtn = returnBtn;
    
    //删除按钮
    UIButton * cancleBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, btnHeight, btnHeight)];
    [cancleBtn setImage:[UIImage imageNamed:@"SplitScreen_close"] forState:UIControlStateNormal];
    cancleBtn.contentMode = UIViewContentModeScaleAspectFill;
    [cancleBtn addTarget:self action:@selector(buttonsClick:) forControlEvents:UIControlEventTouchUpInside];
    cancleBtn.tag = 2;
    [self addSubview:cancleBtn];
    self.cancleBtn = cancleBtn;
    
    self.cancleBtn.bm_right = self.bm_width - 3;
    
    self.returnBtn.bm_centerY = self.cancleBtn.bm_centerY = self.bm_height * 0.5;
    
}

- (void)buttonsClick:(UIButton *)sender
{
    switch (sender.tag)
    {
        case 1:
        {//由全屏还原的按钮
            if ([self.delegate respondsToSelector:@selector(whiteBoardfullScreenReturn)])
            {
                [self.delegate whiteBoardfullScreenReturn];
            }
        }
            break;
        case 2:
        {//删除按钮
            if ([self.delegate respondsToSelector:@selector(deleteWhiteBoardView)])
            {
                [self.delegate deleteWhiteBoardView];
            }
        }
            break;
    
        default:
            break;
    }
}


@end
