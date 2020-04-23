//
//  YSWhiteBoardControlView.h
//  YSWhiteBoard
//
//  Created by 马迪 on 2020/4/23.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol YSWhiteBoardControlViewDelegate <NSObject>

/// 由全屏还原的按钮
- (void)whiteBoardfullScreenReturn;
/// 删除按钮
- (void)deleteWhiteBoardView;

@end

@interface YSWhiteBoardControlView : UIView

@property (nonatomic, weak) id <YSWhiteBoardControlViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
