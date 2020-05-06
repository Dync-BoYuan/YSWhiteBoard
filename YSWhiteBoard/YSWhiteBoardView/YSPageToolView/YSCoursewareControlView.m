//
//  YSCoursewareControlView.m
//  YSWhiteBoard
//
//  Created by 马迪 on 2020/4/2.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import "YSCoursewareControlView.h"


@interface YSCoursewareControlView ()


///全屏按钮
@property (nonatomic, weak) UIButton *allScreenBtn;
///左翻页按钮
@property (nonatomic, weak) UIButton *leftTurnBtn;
///页码
@property (nonatomic, weak) UILabel *pageLabel;
///右翻页按钮
@property (nonatomic, weak) UIButton *rightTurnBtn;
///放大按钮
@property (nonatomic, weak) UIButton *augmentBtn;
///缩小按钮
@property (nonatomic, weak) UIButton *reduceBtn;
/// 总页数
@property (nonatomic, assign) NSInteger totalPage;
/// 当前页
@property (nonatomic, assign) NSInteger currentPage;
/// 缩放比例
@property (nonatomic, assign) CGFloat zoomScale;

///是否是白板
@property (nonatomic, assign) BOOL isWhiteBoard;

@end

@implementation YSCoursewareControlView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor = [UIColor colorWithRed:222/255.0 green:234/255.0 blue:255/255.0 alpha:0.8];
        self.layer.cornerRadius = frame.size.height/2;
        self.layer.masksToBounds = YES;
        
        self.isAllScreen = NO;
        self.allowTurnPage = YES;
        self.totalPage = 1;
        self.currentPage = 1;
        self.zoomScale = 1;
        
        [self setupUI];        
    }
    
    return self;
}

- (void)setupUI
{
    CGFloat btnHeight = 24;
    
    //刷新按钮
    UIButton * frashBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, btnHeight, btnHeight)];
    [frashBtn setImage:[UIImage imageNamed:@"WhiteBoardFrash_normal"] forState:UIControlStateNormal];
    [frashBtn setImage:[UIImage imageNamed:@"WhiteBoardFrash_selected"] forState:UIControlStateSelected];
    [frashBtn addTarget:self action:@selector(buttonsClick:) forControlEvents:UIControlEventTouchUpInside];
    frashBtn.tag = 1;
    [self addSubview:frashBtn];
    self.frashBtn = frashBtn;
    
    //全屏按钮
    UIButton * allScreenBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, btnHeight, btnHeight)];
    [allScreenBtn setImage:[UIImage imageNamed:@"WhiteBoardControl_allScreen_normal"] forState:UIControlStateNormal];
    [allScreenBtn setImage:[UIImage imageNamed:@"WhiteBoardControl_allScreen_highlighted"] forState:UIControlStateHighlighted];
    [allScreenBtn addTarget:self action:@selector(buttonsClick:) forControlEvents:UIControlEventTouchUpInside];
    allScreenBtn.tag = 2;
    [self addSubview:allScreenBtn];
    self.allScreenBtn = allScreenBtn;
    
    //左翻页按钮
    UIButton * leftTurnBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 17, 25)];
    [leftTurnBtn setImage:[UIImage imageNamed:@"WhiteBoardControl_leftTurn_normal"] forState:UIControlStateNormal];
    [leftTurnBtn setImage:[UIImage imageNamed:@"WhiteBoardControl_leftTurn_highlighted"] forState:UIControlStateHighlighted];
    [leftTurnBtn setImage:[UIImage imageNamed:@"WhiteBoardControl_leftTurn_disable"] forState:UIControlStateDisabled];
    leftTurnBtn.enabled = NO;
    [leftTurnBtn addTarget:self action:@selector(buttonsClick:) forControlEvents:UIControlEventTouchUpInside];
    leftTurnBtn.tag = 3;
    [self addSubview:leftTurnBtn];
    self.leftTurnBtn = leftTurnBtn;
    
    //页码
    UILabel * pageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 28)];
    pageLabel.textColor = [UIColor bm_colorWithHex:0x5A8CDC];
    pageLabel.textAlignment = NSTextAlignmentCenter;
    pageLabel.font = [UIFont systemFontOfSize:16];
    [self addSubview:pageLabel];
    self.pageLabel = pageLabel;
    
    //右翻页按钮
    UIButton * rightTurnBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 17, 25)];
    [rightTurnBtn setImage:[UIImage imageNamed:@"WhiteBoardControl_rightTurn_normal"] forState:UIControlStateNormal];
    [rightTurnBtn setImage:[UIImage imageNamed:@"WhiteBoardControl_rightTurn_highlighted"] forState:UIControlStateHighlighted];
    [rightTurnBtn setImage:[UIImage imageNamed:@"WhiteBoardControl_rightTurn_disable"] forState:UIControlStateDisabled];
    rightTurnBtn.enabled = NO;
    [rightTurnBtn addTarget:self action:@selector(buttonsClick:) forControlEvents:UIControlEventTouchUpInside];
    rightTurnBtn.tag = 4;
    [self addSubview:rightTurnBtn];
    self.rightTurnBtn = rightTurnBtn;
    
    //放大按钮
    UIButton * augmentBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, btnHeight, btnHeight)];
    [augmentBtn setImage:[UIImage imageNamed:@"SplitScreen_enlarge_normal"] forState:UIControlStateNormal];
    [augmentBtn setImage:[UIImage imageNamed:@"SplitScreen_enlarge_highlighted"] forState:UIControlStateHighlighted];
    [augmentBtn setImage:[UIImage imageNamed:@"SplitScreen_enlarge_disabled"] forState:UIControlStateDisabled];
    [augmentBtn addTarget:self action:@selector(buttonsClick:) forControlEvents:UIControlEventTouchUpInside];
    augmentBtn.tag = 5;
    [self addSubview:augmentBtn];
    self.augmentBtn = augmentBtn;
    
    //缩小按钮
    UIButton * reduceBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, btnHeight, btnHeight)];
    [reduceBtn setImage:[UIImage imageNamed:@"SplitScreen_minimize_normal"] forState:UIControlStateNormal];
    [reduceBtn setImage:[UIImage imageNamed:@"SplitScreen_minimize_highlighted"] forState:UIControlStateHighlighted];
    [reduceBtn setImage:[UIImage imageNamed:@"SplitScreen_minimize_disable"] forState:UIControlStateDisabled];
    [reduceBtn addTarget:self action:@selector(buttonsClick:) forControlEvents:UIControlEventTouchUpInside];
    reduceBtn.tag = 6;
    [self addSubview:reduceBtn];
    self.reduceBtn = reduceBtn;
    
    self.augmentBtn.enabled = YES;
    self.reduceBtn.enabled  = NO;
        
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.frashBtn.bm_left = 3;
    
    self.allScreenBtn.bm_left = self.frashBtn.bm_right + 10;;
    
    self.leftTurnBtn.bm_left = self.allScreenBtn.bm_right + 8;
    
    self.pageLabel.bm_left = self.leftTurnBtn.bm_right + 5;
    
    self.rightTurnBtn.bm_left = self.pageLabel.bm_right + 5;
    
    self.augmentBtn.bm_left = self.rightTurnBtn.bm_right + 8;
    
    self.reduceBtn.bm_left = self.augmentBtn.bm_right + 10;
    
    self.frashBtn.bm_centerY = self.allScreenBtn.bm_centerY = self.leftTurnBtn.bm_centerY = self.pageLabel.bm_centerY = self.rightTurnBtn.bm_centerY = self.augmentBtn.bm_centerY = self.reduceBtn.bm_centerY = self.bm_height * 0.5;
    
}

- (void)buttonsClick:(UIButton *)sender
{
    switch (sender.tag)
    {
        case 1:
        {//刷新课件
            
            if (!sender.selected)
            {
                sender.selected = !sender.selected;
                if ([self.delegate respondsToSelector:@selector(coursewareFrashBtnClick)])
                {
                    [self.delegate coursewareFrashBtnClick];
                }
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (sender.selected)
                    {
                        sender.selected = NO;
                    }
                });
            }
        }
            break;
        case 2:
        {//全屏
            self.isAllScreen = !self.isAllScreen;
            
            if ((self != [YSWhiteBoardManager shareInstance].mainWhiteBoardView.pageControlView))
            {
                [YSWhiteBoardManager shareInstance].mainWhiteBoardView.pageControlView.isAllScreen = self.isAllScreen;
            }
            
            if ([self.delegate respondsToSelector:@selector(coursewarefullScreen:)])
            {
                [self.delegate coursewarefullScreen:self.isAllScreen];
            }
        }
            break;
        case 3:
        {//左翻页
            self.leftTurnBtn.enabled = (self.currentPage > 1);
            self.rightTurnBtn.enabled = self.currentPage < self.totalPage;
            if ([self.delegate respondsToSelector:@selector(coursewareTurnToPreviousPage)])
            {
                [self.delegate coursewareTurnToPreviousPage];
            }
        }
            break;
        case 4:
        {//右翻页
            self.leftTurnBtn.enabled = (self.currentPage > 1);
            self.rightTurnBtn.enabled = self.currentPage < self.totalPage;
            if ([self.delegate respondsToSelector:@selector(coursewareTurnToNextPage)])
            {
                [self.delegate coursewareTurnToNextPage];
            }
        }
            break;
        case 5:
        {//放大
            if ([self.delegate respondsToSelector:@selector(coursewareToEnlarge)])
            {
                [self.delegate coursewareToEnlarge];
            }
        }
            break;
        case 6:
        {//缩小
            if ([self.delegate respondsToSelector:@selector(coursewareToNarrow)])
            {
                [self.delegate coursewareToNarrow];
            }
        }
            break;
            
        default:
            break;
    }
}

#pragma mark -setter

- (void)sc_setTotalPage:(NSInteger)total currentPage:(NSInteger)currentPage isWhiteBoard:(BOOL)isWhiteBoard
{
    self.isWhiteBoard = isWhiteBoard;
    self.totalPage = total;
    if (self.totalPage < 1)
    {
        self.totalPage = 1;
    }
    
    self.currentPage = currentPage;
    if (self.currentPage < 1)
    {
        self.currentPage = 1;
    }
    self.pageLabel.text = [NSString stringWithFormat:@"%ld / %ld",(long)self.currentPage,(long)self.totalPage];
    
    YSRoomUser *localUser = [YSRoomInterface instance].localUser;
    
    if (localUser.role != YSUserType_Teacher)
    {
        NSDictionary *properties = [localUser.properties bm_dictionaryForKey:@"properties"];
        
        if ([properties bm_boolForKey:@"candraw"])
        {
            self.allowTurnPage = YES;
        }
        else
        {
            self.allowTurnPage = NO;
        }
    }
    else
    {
        self.allowTurnPage = YES;
    }    
}

- (void)sc_setTotalPage:(NSInteger)total currentPage:(NSInteger)currentPage canPrevPage:(BOOL)canPrevPage canNextPage:(BOOL)canNextPage isWhiteBoard:(BOOL)isWhiteBoard
{
    self.isWhiteBoard = isWhiteBoard;
    self.totalPage = total;
    if (self.totalPage < 1)
    {
        self.totalPage = 1;
    }
    
    self.currentPage = currentPage;
    if (self.currentPage < 1)
    {
        self.currentPage = 1;
    }
    self.pageLabel.text = [NSString stringWithFormat:@"%ld / %ld",(long)self.currentPage,(long)self.totalPage];
    
    YSRoomUser *localUser = [YSRoomInterface instance].localUser;
    
    if (localUser.role != YSUserType_Teacher)
    {
        NSDictionary *properties = [localUser.properties bm_dictionaryForKey:@"properties"];
        
        if ([properties bm_boolForKey:@"candraw"])
        {
            self.allowTurnPage = YES;
        }
        else
        {
            self.allowTurnPage = NO;
        }
    }
    else
    {
        self.allowTurnPage = YES;
    }
}

// 是否全屏
- (void)setIsAllScreen:(BOOL)isAllScreen
{
    _isAllScreen = isAllScreen;
    if (isAllScreen)
    {
        [self.allScreenBtn setImage:[UIImage imageNamed:@"WhiteBoardControl_normalScreen_normal"] forState:UIControlStateNormal];
        [self.allScreenBtn setImage:[UIImage imageNamed:@"WhiteBoardControl_normalScreen_highLighed"] forState:UIControlStateHighlighted];
    }
    else
    {
        [self.allScreenBtn setImage:[UIImage imageNamed:@"WhiteBoardControl_allScreen_normal"] forState:UIControlStateNormal];
        [self.allScreenBtn setImage:[UIImage imageNamed:@"WhiteBoardControl_allScreen_highlighted"] forState:UIControlStateHighlighted];
    }
}
// 是否可以翻页  (未开课前通过权限判断是否可以翻页  上课后永久不可以翻页)
- (void)setAllowTurnPage:(BOOL)allowTurnPage
{
    _allowTurnPage = allowTurnPage;
    if (allowTurnPage)
    {
        self.leftTurnBtn.enabled = (self.currentPage > 1);

        if ([YSWhiteBoardManager shareInstance].isBeginClass && self.isWhiteBoard && [YSRoomInterface instance].localUser.role == YSUserType_Teacher)
        {
            self.rightTurnBtn.enabled = YES;
        }
        else
        {
            self.rightTurnBtn.enabled = self.currentPage < self.totalPage;
        }
    }
    else
    {
        self.leftTurnBtn.enabled = NO;
        self.rightTurnBtn.enabled = NO;
    }
}

// 是否可以缩放
- (void)setAllowScaling:(BOOL)allowScaling
{
    _allowScaling = allowScaling;
    
    if (allowScaling)
    {
        [self changeZoomScale:self.zoomScale];
        
        
        self.bm_width = 232;
    }
    else
    {
        self.augmentBtn.enabled = NO;
        self.reduceBtn.enabled = NO;
        self.bm_width = 168;
    }
}

/// 重置缩放按钮
- (void)resetBtnStates
{
    self.augmentBtn.enabled = YES;
    self.reduceBtn.enabled = NO;
    [self changeZoomScale:YSWHITEBOARD_MINZOOMSCALE];
}


- (void)changeZoomScale:(CGFloat)zoomScale
{
    if (!self.allowScaling)
    {
        return;
    }
    
    self.zoomScale = zoomScale;

    if (self.zoomScale >= YSWHITEBOARD_MAXZOOMSCALE)
    {
        self.zoomScale = YSWHITEBOARD_MAXZOOMSCALE;
        self.augmentBtn.enabled = NO;
        self.reduceBtn.enabled = YES;
    }
    else if (self.zoomScale <= YSWHITEBOARD_MINZOOMSCALE)
    {
        self.zoomScale = YSWHITEBOARD_MINZOOMSCALE;
        self.augmentBtn.enabled = YES;
        self.reduceBtn.enabled  = NO;
    }
    else
    {
        self.augmentBtn.enabled = YES;
        self.reduceBtn.enabled = YES;
    }
}

@end
