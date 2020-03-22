//
//  BMNoticeView.m
//  YSLive
//
//  Created by jiang deng on 2019/10/21.
//  Copyright © 2019 FS. All rights reserved.
//

#import "BMNoticeView.h"

#define BMNoticeViewMaskBgDefaultEffect [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]

#define BMNoticeViewMaskBgColor         [UIColor colorWithWhite:0 alpha:0.25]
#define BMNoticeViewBgColor             [UIColor colorWithWhite:0.9 alpha:1]


@interface BMNoticeViewStack ()

@property (nonatomic) NSMutableArray *noticeViews;

- (void)push:(BMNoticeView *)noticeView;
- (void)pop:(BMNoticeView *)noticeView;

@end

@interface BMNoticeView ()

@property (nonatomic, weak) UIView *noticeViewSuperView;

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIVisualEffectView *noticeMaskBgEffectView;
@property (nonatomic, strong) UIView *noticeView;

@property (nonatomic, strong) UIView *noticeContentView;

@property (nonatomic) UITapGestureRecognizer *tapOutside;

@end

@implementation BMNoticeView
@synthesize noticeMaskBgColor = _noticeMaskBgColor;

- (void)dealloc
{
    //NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    //[center removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.topDistance = 0;
        self.backgroundEdgeInsets = UIEdgeInsetsZero;
        
        self.shouldDismissOnTapOutside = YES;
        
        self.showAnimationType = BMNoticeViewShowAnimationFadeIn;
        self.hideAnimationType = BMNoticeViewHideAnimationFadeOut;
        
        CGRect frame = [self frameForOrientation];
        self.frame = frame;
        
        self.noticeMaskBgEffect = BMNoticeViewMaskBgDefaultEffect;
        self.noticeMaskBgEffectView = [[UIVisualEffectView alloc] initWithEffect:self.noticeMaskBgEffect];
        self.noticeMaskBgEffectView.alpha = 0.8f;
        self.noticeMaskBgEffectView.backgroundColor = [UIColor clearColor];
        self.noticeMaskBgEffectView.frame = self.bounds;
        [self addSubview:self.noticeMaskBgEffectView];
        self.noticeMaskBgEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.backgroundView = [[UIView alloc] initWithFrame:frame];
        self.backgroundView.backgroundColor = self.noticeMaskBgColor;
        [self addSubview:self.backgroundView];
        self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        self.noticeView = [[UIView alloc] init];
        self.noticeView.backgroundColor = [UIColor clearColor];
        [self addSubview:self.noticeView];
        
        [self setupGestures];
    }
    
    return self;
}

- (void)setupGestures
{
    self.tapOutside = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss:)];
    [self.tapOutside setNumberOfTapsRequired:1];
    self.tapOutside.enabled = self.shouldDismissOnTapOutside;
    
    self.backgroundView.userInteractionEnabled = YES;
    self.backgroundView.multipleTouchEnabled = NO;
    self.backgroundView.exclusiveTouch = YES;
    [self.backgroundView addGestureRecognizer:self.tapOutside];
}

- (CGRect)frameForOrientation
{
    return CGRectMake(0, 0, 100, 100);
}

- (void)centerNoticeView
{
    CGRect frame = self.superview.bounds;
    NSLog(@"frame: %@", NSStringFromCGRect(frame));
    
    //self.noticeMaskBgEffectView.frame = frame;
    frame = CGRectMake(frame.origin.x + self.backgroundEdgeInsets.left, frame.origin.y + self.backgroundEdgeInsets.top, frame.size.width - (self.backgroundEdgeInsets.left+self.backgroundEdgeInsets.right), frame.size.height - (self.backgroundEdgeInsets.top+self.backgroundEdgeInsets.bottom));
    self.frame = frame;
    
    if (self.topDistance)
    {
        [self.noticeView bm_centerHorizontallyInSuperViewWithTop:self.topDistance];
    }
    else
    {
        [self.noticeView bm_centerInSuperView];
    }
}

- (void)freshNoticeView
{
    self.alpha = 1.0f;
    self.hidden = NO;
    [self bm_bringToFront];
    
    self.noticeMaskBgEffectView.effect = self.noticeMaskBgEffect;
    self.backgroundView.backgroundColor = self.noticeMaskBgColor;
    
    [self.noticeView bm_removeAllSubviews];
    
    if (self.noticeContentView)
    {
        [self.noticeView addSubview:self.noticeContentView];
        self.noticeContentView.bm_origin = CGPointZero;
        
        self.noticeView.bm_size = self.noticeContentView.bm_size;
    }
    
    [self centerNoticeView];
}


#pragma mark -
#pragma mark property

- (void)setNoticeMaskBgEffect:(UIVisualEffect *)noticeMaskBgEffect
{
    _noticeMaskBgEffect = noticeMaskBgEffect;
    
    self.noticeMaskBgEffectView.effect = noticeMaskBgEffect;
}

- (void)setShouldDismissOnTapOutside:(BOOL)shouldDismissOnTapOutside
{
    _shouldDismissOnTapOutside = shouldDismissOnTapOutside;
    self.tapOutside.enabled = shouldDismissOnTapOutside;
}

- (UIColor *)noticeMaskBgColor
{
    if (!_noticeMaskBgColor)
    {
        return BMNoticeViewMaskBgColor;
    }
    
    return _noticeMaskBgColor;
}

- (void)setNoticeMaskBgColor:(UIColor *)noticeMaskBgColor
{
    _noticeMaskBgColor = noticeMaskBgColor;
    
    self.backgroundView.backgroundColor = noticeMaskBgColor;
}


#pragma mark -
#pragma mark func

- (void)showWithView:(UIView *)contentView inView:(UIView *)inView
{
    [self showWithView:contentView inView:inView showBlock:nil];
}

- (void)showWithView:(UIView *)contentView inView:(UIView *)inView showBlock:(BMNoticeViewShowBlock)showBlock
{
    [self showWithView:contentView inView:inView showBlock:showBlock dismissBlock:nil];
}

- (void)showWithView:(UIView *)contentView inView:(UIView *)inView showBlock:(BMNoticeViewShowBlock)showBlock dismissBlock:(BMNoticeViewDismissBlock)dismissBlock
{
    if (!inView)
    {
        return;
    }
    
    self.noticeViewSuperView = inView;
    self.noticeContentView = contentView;
    self.showBlock = showBlock;
    self.dismissBlock = dismissBlock;

    [self showInView:inView];
}

- (void)showInView:(UIView *)inView
{
    if (self.superview)
    {
        [self removeFromSuperview];
    }
    [inView addSubview:self];
    self.frame = inView.bounds;

    [[BMNoticeViewStack sharedInstance] push:self];
}

- (void)showInternal
{
    switch (self.showAnimationType)
    {
        case BMNoticeViewShowAnimationFadeIn:
            [self fadeIn];
            break;
            
        case BMNoticeViewShowAnimationSlideInFromBottom:
            [self slideInFromBottom];
            break;
            
        case BMNoticeViewShowAnimationSlideInFromTop:
            [self slideInFromTop];
            break;
            
        case BMNoticeViewShowAnimationSlideInFromLeft:
            [self slideInFromLeft];
            break;
            
        case BMNoticeViewShowAnimationSlideInFromRight:
            [self slideInFromRight];
            break;
            
        default:
            [self showCompletion];
            break;
    }
}

- (void)showCompletion
{
    self.hidden = NO;
    
    [self showNoticeAnimation];
    
    if (self.showBlock)
    {
        self.showBlock();
    }
}

- (void)remove
{
    self.hidden = YES;
    
    if (self.superview)
    {
        [self removeFromSuperview];
    }
}

- (void)dismiss:(id)sender
{
    [self dismiss:sender dismissBlock:self.dismissBlock];
}

- (void)dismiss:(id)sender dismissBlock:(BMNoticeViewDismissBlock)dismissBlock
{
    [self dismiss:sender animated:YES dismissBlock:dismissBlock];
}

- (void)doCompletion:(id)sender
{
    NSUInteger index = 0;
    if (sender != self.tapOutside)
    {
        sender = self.noticeContentView;
        index = 1;
    }
    
    if (self.dismissBlock)
    {
        self.dismissBlock(sender, index);
    }
}

- (void)dismissCompletion:(id)sender
{
    [self doCompletion:sender];
    
    [[BMNoticeViewStack sharedInstance] pop:self];
}

- (void)dismiss:(id)sender animated:(BOOL)animated dismissBlock:(BMNoticeViewDismissBlock)dismissBlock
{
    self.dismissBlock = dismissBlock;
    
    if (self.notDismissOnCancel)
    {
        self.hidden = NO;
        
        [self doCompletion:sender];
        
        return;
    }
    
    self.hidden = YES;
    
    if (animated)
    {
        switch (self.hideAnimationType)
        {
            case BMNoticeViewHideAnimationFadeOut:
                [self fadeOut:sender];
                break;
                
            case BMNoticeViewHideAnimationSlideOutToBottom:
                [self slideOutToBottom:sender];
                break;
                
            case BMNoticeViewHideAnimationSlideOutToTop:
                [self slideOutToTop:sender];
                break;
                
            case BMNoticeViewHideAnimationSlideOutToLeft:
                [self slideOutToLeft:sender];
                break;
                
            case BMNoticeViewHideAnimationSlideOutToRight:
                [self slideOutToRight:sender];
                break;
                
            default:
                [self dismissCompletion:sender];
                break;
        }
    }
    else
    {
        [self dismissCompletion:sender];
    }
}

- (void)showNoticeAnimation
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    animation.values = @[ [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 1)],
                          [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.05, 1.05, 1)],
                          [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1)] ];
    animation.keyTimes = @[ @0, @0.5, @1 ];
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.duration = 0.3;
    
    [self.noticeView.layer addAnimation:animation forKey:@"showNotice"];
}

- (void)dismissNoticeAnimation
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    animation.values = @[ [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1)],
                          [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.95, 0.95, 1)],
                          [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.8, 0.8, 1)] ];
    animation.keyTimes = @[ @0, @0.5, @1 ];
    animation.fillMode = kCAFillModeRemoved;
    animation.duration = 0.2;
    
    [self.noticeView.layer addAnimation:animation forKey:@"dismissNotice"];
}


#pragma mark -
#pragma mark Show Animations

- (void)fadeIn
{
    self.alpha = 0.0f;
    
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.alpha = 1.0f;
                     }
                     completion:^(BOOL finished) {
                         [self showCompletion];
                     }];
}

- (void)slideInFromBottom
{
    self.alpha = 1.0f;
    
    //From Frame
    CGRect frame = self.bounds;
    self.noticeView.bm_top = frame.size.height;
    
    [UIView animateWithDuration:0.3f
                     animations:^{
                         
                         //To Frame
                         [self centerNoticeView];
                         
                     }
                     completion:^(BOOL completed) {
                         [self showCompletion];
                     }];
}

- (void)slideInFromTop
{
    self.alpha = 1.0f;
    // From Frame
    self.noticeView.bm_top = -self.noticeView.bm_height;
    
    [UIView animateWithDuration:0.3f
                     animations:^{
                         
                         //To Frame
                         [self centerNoticeView];
                         
                     }
                     completion:^(BOOL completed) {
                         [self showCompletion];
                     }];
}

- (void)slideInFromLeft
{
    self.alpha = 1.0f;
    //From Frame
    self.noticeView.bm_left = -self.noticeView.bm_width;
    
    [UIView animateWithDuration:0.3f
                     animations:^{
                         
                         //To Frame
                         [self centerNoticeView];
                         
                     }
                     completion:^(BOOL completed) {
                         [self showCompletion];
                     }];
}

- (void)slideInFromRight
{
    self.alpha = 1.0f;
    
    //From Frame
    CGRect frame = [self frameForOrientation];
    self.noticeView.bm_left = frame.size.width;
    
    [UIView animateWithDuration:0.3f
                     animations:^{
                         
                         //To Frame
                         [self centerNoticeView];
                         
                     }
                     completion:^(BOOL completed) {
                         [self showCompletion];
                     }];
}


#pragma mark -
#pragma mark Hide Animations

- (void)fadeOut:(id)sender
{
    [UIView animateWithDuration:0.3f
                     animations:^{
                         self.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [self dismissCompletion:sender];
                     }];
}

- (void)slideOutToBottom:(id)sender
{
    [UIView animateWithDuration:0.3f
                     animations:^{
                         
                         self.alpha = 0;
                         
                         CGRect frame = self.bounds;
                         self.noticeView.bm_top = frame.size.height;
                         
                     }
                     completion:^(BOOL completed) {
                         [self dismissCompletion:sender];
                     }];
}

- (void)slideOutToTop:(id)sender
{
    [UIView animateWithDuration:0.3f
                     animations:^{
                         
                         self.alpha = 0;
                         
                         self.noticeView.bm_top = -self.noticeView.bm_height;
                         
                     }
                     completion:^(BOOL completed) {
                         [self dismissCompletion:sender];
                     }];
}

- (void)slideOutToLeft:(id)sender
{
    [UIView animateWithDuration:0.3f
                     animations:^{
                         
                         self.alpha = 0;
                         
                         self.noticeView.bm_left = -self.noticeView.bm_width;
                         
                     }
                     completion:^(BOOL completed) {
                         [self dismissCompletion:sender];
                     }];
}

- (void)slideOutToRight:(id)sender
{
    [UIView animateWithDuration:0.3f
                     animations:^{
                         
                         self.alpha = 0;
                         
                         CGRect frame = [self frameForOrientation];
                         self.noticeView.bm_left = frame.size.width;
                         
                     }
                     completion:^(BOOL completed) {
                         [self dismissCompletion:sender];
                     }];
}

@end



@implementation BMNoticeViewStack

+ (instancetype)sharedInstance
{
    static BMNoticeViewStack *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[BMNoticeViewStack alloc] init];
        _sharedInstance.noticeViews = [NSMutableArray array];
    });
    
    return _sharedInstance;
}

- (void)push:(BMNoticeView *)noticeView
{
    @synchronized(self.noticeViews)
    {
        for (BMNoticeView *nv in self.noticeViews)
        {
            // 有置顶警告时，不再显示其他警告
            if (nv.notDismissOnCancel)
            {
                [nv freshNoticeView];
                return;
            }
            
            if (nv != noticeView)
            {
                nv.hidden = YES;
            }
            else
            {
                [nv freshNoticeView];
                return;
            }
        }
        
        [noticeView freshNoticeView];
        [self.noticeViews addObject:noticeView];
        [noticeView showInternal];
    }
}

- (void)pop:(BMNoticeView *)noticeView
{
    @synchronized(self.noticeViews)
    {
        [noticeView remove];
        
        [self.noticeViews removeObject:noticeView];
        
        BMNoticeView *last = [self.noticeViews lastObject];
        if (last)
        {
            [last freshNoticeView];
            [last showInternal];
        }
    }
}

- (void)closeAllNoticeViews
{
    BMNoticeView *last = [self.noticeViews lastObject];
    while (last)
    {
        if (last.notDismissOnCancel)
        {
            break;
        }
        
        [self closeNoticeView:last animated:NO];
        last = [self.noticeViews lastObject];
    }
}

- (void)closeNoticeView:(BMNoticeView *)noticeView
{
    [self closeNoticeView:noticeView animated:YES];
}

- (void)closeNoticeView:(BMNoticeView *)noticeView animated:(BOOL)animated
{
    [noticeView dismiss:nil animated:animated dismissBlock:nil];
}

- (NSUInteger)getNoticeViewCount
{
    return self.noticeViews.count;
}

- (void)bringAllViewsToFront
{
    for (BMNoticeView *noticeView in self.noticeViews)
    {
        [noticeView bm_bringToFront];
    }
}

@end
