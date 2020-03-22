//
//  BMTabBarController.h
//  BMKit
//
//  Created by jiang deng on 2020/2/6.
//  Copyright © 2020 DennisDeng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BMTabBarController : UITabBarController

@property (nonatomic, strong) NSArray<__kindof BMTabItemClass *> *tab_ItemArray;

// 切换tab后是否把原tab的vc栈回退到root
@property (nonatomic, assign) BOOL bakRootWhenChangeTab;

- (instancetype)initWithArray:(NSArray<__kindof BMTabItemClass *> *)itemArray;

- (void)setViewControllers:(nullable NSArray<__kindof UIViewController *> *)viewControllers;

- (void)freshTabItemWithArray:(NSArray<__kindof BMTabItemClass *> *)itemArray;

- (void)hideOriginTabBar;

// 选中某个Tab
- (void)selectedTabWithIndex:(NSUInteger)index;

- (void)beforeSelectedIndexChangedFrom:(NSUInteger)findex to:(NSUInteger)tindex;
- (void)endSelectedIndexChangedFrom:(NSUInteger)findex to:(NSUInteger)tindex;

// 某个Tab上可能push了很多层，回到初始页面
- (void)backRootLeverView:(NSUInteger)index animated:(BOOL)animated;

- (BMNavigationController *)getCurrentNavigationController;
- (BMNavigationController *)getNavigationControllerAtTabIndex:(NSUInteger)index;

// 返回当前tab的RootVC
- (UIViewController *)getCurrentRootViewController;
// 返回当前tab的首层VC
- (UIViewController *)getCurrentViewController;
// 根据索引找到VC
- (UIViewController *)getRootViewControllerAtTabIndex:(NSUInteger)index;
- (UIViewController *)getViewControllerAtTabIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
