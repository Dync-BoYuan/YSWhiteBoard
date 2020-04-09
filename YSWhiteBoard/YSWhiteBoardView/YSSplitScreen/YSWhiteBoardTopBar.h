//
//  YSWhiteBoardTopBar.h
//  YSWhiteBoard
//
//  Created by 马迪 on 2020/4/9.
//  Copyright © 2020 jiang deng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YSWhiteBoardTopBar : UIView

///按钮点击事件
@property(nonatomic,copy) void(^barButtonsClick)(UIButton *sender);

/// 课件 title
@property (nonatomic, copy) NSString  *titleString;

@end

NS_ASSUME_NONNULL_END
