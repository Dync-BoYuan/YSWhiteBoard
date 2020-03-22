//
//  BMTabItemButton.h
//  BMKit
//
//  Created by jiang deng on 2020/2/5.
//  Copyright © 2020 DennisDeng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BMTabItemClass : NSObject

@property (nullable, nonatomic, strong) NSString *title;

//@property (nullable, nonatomic, strong) UIFont *titleFont;

@property (nullable, nonatomic, strong) UIColor *normalColor;
@property (nullable, nonatomic, strong) UIColor *selectedColor;

@property (nullable, nonatomic, strong) NSString *normalIcon;
@property (nullable, nonatomic, strong) NSString *selectedIcon;

@property (nullable, nonatomic, strong) NSString *normalIconUrl;
@property (nullable, nonatomic, strong) NSString *selectedIconUrl;

@end

@interface BMTabItemButton : UIButton

@property (nullable, nonatomic, strong) NSString *itemTitle;

@property (nullable, nonatomic, strong) UIColor *titleNormalColor;
@property (nullable, nonatomic, strong) UIColor *titleHighlightColor;
@property (nullable, nonatomic, strong) UIColor *titleSelectedColor;

@property (nullable, nonatomic, strong) NSString *normalIcon;
@property (nullable, nonatomic, strong) NSString *highlightIcon;
@property (nullable, nonatomic, strong) NSString *selectedIcon;

@property (nullable, nonatomic, strong) NSString *normalIconUrl;
@property (nullable, nonatomic, strong) NSString *highlightIconUrl;
@property (nullable, nonatomic, strong) NSString *selectedIconUrl;

- (void)setTitle:(nullable NSString *)title
     normalColor:(nullable UIColor *)normalColor
  highLightColor:(nullable UIColor *)highLightColor
   selectedColor:(nullable UIColor *)selectedColor;

- (void)setNormalIconName:(nullable NSString *)normal
        highLightIconName:(nullable NSString *)high
         selectedIconName:(nullable NSString *)selected;

- (void)setNormalIconUrl:(nullable NSString *)normal
        highLightIconUrl:(nullable NSString *)high
         selectedIconUrl:(nullable NSString *)selected;


- (void)freshWithTabItem:(nullable BMTabItemClass *)tabItem;

@end

NS_ASSUME_NONNULL_END
