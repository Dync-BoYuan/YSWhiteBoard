//
//  YSPreloadProgressView.m
//  EduClass
//
//  Created by ys on 2019/5/8.
//  Copyright © 2019 roadofcloud. All rights reserved.
//

#import "YSPreloadProgressView.h"

NSString *const YSWhiteBoardPreloadExit                  = @"YSWhiteBoardPreloadExit";
@implementation YSPreloadProgressView
{
    UILabel *_progressLabel;
    UIImageView *_underImage;
    UIImageView *_aboveImage;
    void(^_skipBlock)(void);
}

- (instancetype)initWithSkipBlock:(void (^)(void))block
{
    if (self = [super init]) {
        _skipBlock = block;
        [self create];
    }
    
    return self;
}

- (void)create
{
    //NSString *colorid = [[NSUserDefaults standardUserDefaults] objectForKey:@"com.tingxins.sakura.current.name"];
    UIView *naviView = [[UIView alloc] init];
    //naviView.backgroundColor = [colorid isEqualToString:@"black"] ? [UIColor colorWithRed:44 / 255.0f green:44 / 255.0f blue:48 / 255.0f alpha:1] : [colorid isEqualToString:@"purple"] ? [UIColor colorWithRed:79 / 255.0f green:61 / 255.0f blue:132 / 255.0f alpha:1] : [UIColor colorWithRed:229 / 255.0f green:229 / 255.0f blue:229 / 255.0f alpha:1];
    naviView.backgroundColor = [UIColor colorWithRed:44 / 255.0f green:44 / 255.0f blue:48 / 255.0f alpha:1];
    [self addSubview:naviView];
    [naviView bmmas_makeConstraints:^(BMMASConstraintMaker *make) {
        make.left.bmmas_equalTo(self.bmmas_left);
        make.right.bmmas_equalTo(self.bmmas_right);
        make.top.bmmas_equalTo(self.bmmas_top);
        make.height.bmmas_equalTo(@(44));
    }];
    
    
    UIButton *exitBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    //[exitBtn setBackgroundImage:[colorid isEqualToString:@"black"] ? [UIImage imageNamed:@"ys_common_icon_return_black"] : [colorid isEqualToString:@"purple"] ? [UIImage imageNamed:@"ys_common_icon_return_cartoon"] : [UIImage imageNamed:@"ys_common_icon_return_orange"] forState:UIControlStateNormal];
    [exitBtn setBackgroundImage:[UIImage imageNamed:@"ys_common_icon_return"] forState:UIControlStateNormal];
    [self addSubview:exitBtn];
    [exitBtn bmmas_makeConstraints:^(BMMASConstraintMaker *make) {
        make.left.bmmas_equalTo(self.bmmas_left).bmmas_offset(20);
        make.top.bmmas_equalTo(self.bmmas_top);
        make.size.bmmas_equalTo([NSValue valueWithCGSize:CGSizeMake(44, 44)]);
    }];
    [exitBtn addTarget:self action:@selector(exit) forControlEvents:UIControlEventTouchUpInside];
    
    
    UIView *dimView = [[UIView alloc] init];
    dimView.backgroundColor = [UIColor blackColor];
    [self addSubview:dimView];
    [dimView bmmas_makeConstraints:^(BMMASConstraintMaker *make) {
        make.left.bmmas_equalTo(self.bmmas_left);
        make.right.bmmas_equalTo(self.bmmas_right);
        make.top.bmmas_equalTo(naviView.bmmas_bottom);
        make.bottom.bmmas_equalTo(self.bmmas_bottom);
    }];
    
    UIView *islandView = [[UIView alloc] init];
    islandView.backgroundColor = UIColor.clearColor;
    [self addSubview:islandView];
    
    _underImage = [[UIImageView alloc] init];
    _underImage.layer.cornerRadius = 5;
    _underImage.layer.masksToBounds = YES;
    _underImage.image = [UIImage imageNamed:@"ys_progressUnder"];
    [islandView addSubview:_underImage];
    [_underImage bmmas_makeConstraints:^(BMMASConstraintMaker *make) {
        make.left.bmmas_equalTo(islandView.bmmas_left);
        make.right.bmmas_equalTo(islandView.bmmas_right);
        make.height.bmmas_equalTo(@(10));
        make.top.bmmas_equalTo(islandView.bmmas_top);
    }];
    
    _progressLabel = [[UILabel alloc] init];
    _progressLabel.font = [UIFont systemFontOfSize:16];
    _progressLabel.textColor = UIColor.whiteColor;
    [islandView addSubview:_progressLabel];
    [_progressLabel bmmas_makeConstraints:^(BMMASConstraintMaker *make) {
        make.centerX.bmmas_equalTo(self->_underImage.bmmas_centerX);
        make.top.bmmas_equalTo(self->_underImage.bmmas_bottom).bmmas_offset(30);
    }];
    
    [islandView bmmas_makeConstraints:^(BMMASConstraintMaker *make) {
        make.centerX.bmmas_equalTo(self.bmmas_centerX);
        make.centerY.bmmas_equalTo(self.bmmas_centerY);
        make.width.bmmas_equalTo(self.bmmas_width).multipliedBy(1.0f / 3).priorityHigh();
    }];
    
    _aboveImage = [[UIImageView alloc] init];
    _aboveImage.image = [UIImage imageNamed:@"ys_progressAbove"];
    [_underImage addSubview:_aboveImage];
    [_aboveImage bmmas_makeConstraints:^(BMMASConstraintMaker *make) {
        make.left.bmmas_equalTo(self->_underImage.bmmas_left);
        make.width.bmmas_equalTo(@(0));
        make.top.bmmas_equalTo(self->_underImage.bmmas_top);
        make.height.bmmas_equalTo(self->_underImage.bmmas_height);
    }];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.titleLabel.font = [UIFont systemFontOfSize:18];
    btn.layer.cornerRadius = 22;
    btn.layer.borderColor = UIColor.whiteColor.CGColor;
    btn.layer.borderWidth = 2;
    [btn setTitle:YSWBLocalized(@"YSPreload.skip") forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(skip) forControlEvents:UIControlEventTouchUpInside];
    [islandView addSubview:btn];
    [btn bmmas_makeConstraints:^(BMMASConstraintMaker *make) {
        make.centerX.bmmas_equalTo(islandView.bmmas_centerX);
        make.top.bmmas_equalTo(self->_progressLabel.bmmas_bottom).bmmas_offset(25);
        make.size.bmmas_equalTo([NSValue valueWithCGSize:CGSizeMake(75, 44)]);
        make.bottom.bmmas_equalTo(islandView.bmmas_bottom);
    }];
}

- (void)setDownloadProgress:(float)downloadProgress unzipProgress:(float)unzipProgress
{
    float width = _underImage.frame.size.width;
    
    if (downloadProgress > 0 && downloadProgress < 1) {
        _progressLabel.text = [NSString stringWithFormat:@"%@: %d%%", YSWBLocalized(@"YSPreload.downloading"), (int)(downloadProgress * 100)];
        [_aboveImage bmmas_updateConstraints:^(BMMASConstraintMaker *make) {
            make.width.bmmas_equalTo(@(width * downloadProgress));
        }];
    }
    if (unzipProgress > 0 && unzipProgress < 1) {
        _progressLabel.text = [NSString stringWithFormat:@"%@: %d%%", YSWBLocalized(@"YSPreload.unzipping"), (int)(unzipProgress * 100)];
        [_aboveImage bmmas_updateConstraints:^(BMMASConstraintMaker *make) {
            make.width.bmmas_equalTo(@(width * unzipProgress));
        }];
    }
}

- (void)skip
{
    [self removeFromSuperview];
    if (_skipBlock) {
        _skipBlock();
    }
}

- (void)exit
{
    [[NSNotificationCenter defaultCenter] postNotificationName:YSWhiteBoardPreloadExit object:nil];
}

@end
