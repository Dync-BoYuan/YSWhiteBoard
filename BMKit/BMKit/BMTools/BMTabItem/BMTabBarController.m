//
//  BMTabBarController.m
//  BMKit
//
//  Created by jiang deng on 2020/2/6.
//  Copyright © 2020 DennisDeng. All rights reserved.
//

#import "BMTabBarController.h"

#define ITEM_TAG_START 100000

@interface BMTabBarController ()

// 自定义TabBar的背景Image
@property (nonatomic, strong) UIView *tabBarBgView;

@property (nonatomic, strong) NSMutableArray *tabButtonArray;

@end

@implementation BMTabBarController

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSGenericException reason:@"init not supported, use initWithArray: instead." userInfo:nil];
    return nil;
}

- (instancetype)initWithArray:(NSArray <BMTabItemClass *> *)itemArray
{
    self = [super init];
    
    if (self)
    {
        self.tab_ItemArray = itemArray;
        
        self.bakRootWhenChangeTab = YES;
        
        [self addReplaceTabBarView];
    }
    
    return self;
}

// 添加模拟的TabBar
- (void)addReplaceTabBarView
{
    UIImage *originImage = [UIImage imageNamed:@"bmtab_bg"];
    UIImage *resizeImage = [originImage stretchableImageWithLeftCapWidth:originImage.size.width/2 topCapHeight:originImage.size.height/2];
    
    [self.tabBar setBackgroundImage:[UIImage imageNamed:@"bmtab_clear_line"]];
    [self.tabBar setShadowImage:[UIImage imageNamed:@"bmtab_clear_line"]];
    
    // 设置背景图
    self.tabBarBgView = [[UIView alloc] initWithFrame:self.tabBar.bounds];
    self.tabBarBgView.userInteractionEnabled = YES;
    
    UIImageView *imageview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, UI_SCREEN_WIDTH, UI_TAB_BAR_HEIGHT)];
    imageview.image = resizeImage;
    [self.tabBarBgView addSubview:imageview];
    
    // 添加Item
    self.tabButtonArray = [NSMutableArray arrayWithCapacity:0];
    NSUInteger tab_Count = self.tab_ItemArray.count;
    if (tab_Count == 0)
    {
        return;
    }
    
    CGFloat width = UI_SCREEN_WIDTH/tab_Count;

    for (NSUInteger i=0; i<tab_Count; i++)
    {
        CGRect rect = CGRectMake(width * i, 0, width, UI_TAB_BAR_HEIGHT-UI_HOME_INDICATOR_HEIGHT);
        
        BMTabItemButton *item = [[BMTabItemButton alloc] initWithFrame:rect];
        
        [item addTarget:self action:@selector(selectedTab:) forControlEvents:UIControlEventTouchUpInside];
        
        BMTabItemClass *itemClass = self.tab_ItemArray[i];
        [item freshWithTabItem:itemClass];
        
        item.tag = ITEM_TAG_START+i;
        item.exclusiveTouch = YES;

        [self.tabBarBgView addSubview:item];
        [self.tabButtonArray addObject:item];
        
        if (i == 0)
        {
            // 默认选中第一个VC
            [item setSelected:YES];
        }
    }
    
    [self.tabBar addSubview:self.tabBarBgView];
}

// 隐藏原来的tabbar
- (void)hideOriginTabBar
{
    [self.tabBar.subviews enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[UIControl class]])
        {
            UIControl *control = (UIControl *)obj;
            dispatch_async(dispatch_get_main_queue(), ^{
                control.hidden = YES;
            });
        }
    }];
}

#pragma mark 横竖屏

- (BOOL)shouldAutorotate
{
    return [self.selectedViewController shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.selectedViewController supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return [self.selectedViewController preferredInterfaceOrientationForPresentation];
}


- (void)freshTabItemWithArray:(NSArray *)itemArray
{
    if (self.tab_ItemArray.count != itemArray.count)
    {
        return;
    }
    
    for (NSUInteger index = 0; index<self.tab_ItemArray.count; index++)
    {
        BMTabItemButton *item = self.tabButtonArray[index];
        [item freshWithTabItem:itemArray[index]];
    }
}

- (void)setViewControllers:(NSArray *)viewControllers
{
    [super setViewControllers:viewControllers];
    
    [self hideOriginTabBar];
    
    if (self.viewControllers.count > 0)
    {
        return;
    }
    
    [self selectedTabWithIndex:0];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)unselectedTab:(NSUInteger)index
{
    if (index < self.tab_ItemArray.count)
    {
        BMTabItemButton *item = self.tabButtonArray[index];
        item.selected = NO;
    }
}

- (void)selectedTab:(BMTabItemButton *)item
{
    NSUInteger index = [self.tabButtonArray indexOfObject:item];
    
    [self selectedTabWithIndex:index];
}

- (void)selectedTabWithIndex:(NSUInteger)index
{
    if (index == NSNotFound )
    {
        return;
    }

    if (index == self.selectedIndex )
    {
        return;
    }

    [self beforeSelectedIndexChangedFrom:self.selectedIndex to:index];
    
    [self unselectedTab:self.selectedIndex];
    
    BMTabItemButton *item = self.tabButtonArray[index];
    item.selected = YES;
    
    NSUInteger oldIndex = self.selectedIndex;
    self.selectedIndex = index;
    
    [self endSelectedIndexChangedFrom:oldIndex to:index];

    [self.tabBarBgView bm_bringToFront];
}

- (void)beforeSelectedIndexChangedFrom:(NSUInteger)findex to:(NSUInteger)tindex
{
}

- (void)endSelectedIndexChangedFrom:(NSUInteger)findex to:(NSUInteger)tindex
{
    // 切换tab是否回到rootVC
    if (self.bakRootWhenChangeTab)
    {
        BMNavigationController *nav = [self.viewControllers objectAtIndex:findex];
        if (nav.viewControllers.count > 1)
        {
            [nav popToRootViewControllerAnimated:NO];
        }
    }
}

- (void)backRootLeverView:(NSUInteger)index animated:(BOOL)animated
{
    BMNavigationController *navCtl = [self getCurrentNavigationController];
    if (navCtl.viewControllers.count > 1)
    {
        if (self.selectedIndex == index)
        {
            [navCtl popToRootViewControllerAnimated:animated];
        }
        else
        {
            [navCtl popToRootViewControllerAnimated:NO];
        }
    }
    
    [self selectedTabWithIndex:index];
}

- (BMNavigationController *)getCurrentNavigationController
{
    if ([self.selectedViewController isKindOfClass:[BMNavigationController class]])
    {
        return (BMNavigationController *)self.selectedViewController;
    }
    else
    {
        return nil;
    }
}

- (BMNavigationController *)getNavigationControllerAtTabIndex:(NSUInteger)index
{
    if (index >= self.viewControllers.count)
    {
        return nil;
    }
    
    id navCtl = [self.viewControllers objectAtIndex:index];
    
    if ([navCtl isKindOfClass:[BMNavigationController class]])
    {
        return (BMNavigationController *)navCtl;
    }
    else
    {
        return nil;
    }
}

// 根据索引找到VC
- (UIViewController *)getRootViewControllerAtTabIndex:(NSUInteger)index
{
    BMNavigationController *navCtl = [self getNavigationControllerAtTabIndex:index];
    
    NSArray *carray = navCtl.viewControllers;
    if (![carray bm_isNotEmpty])
    {
        return nil;
    }
    
    UIViewController *vc = [carray lastObject];
    return vc;
}

- (UIViewController *)getViewControllerAtTabIndex:(NSUInteger)index
{
    BMNavigationController *navCtl = [self getNavigationControllerAtTabIndex:index];
    
    NSArray *carray = navCtl.viewControllers;
    if (![carray bm_isNotEmpty])
    {
        return nil;
    }
    
    UIViewController *vc = [carray firstObject];
    return vc;
}

// 此函数只是返回当前tab的RootVC
- (UIViewController *)getCurrentRootViewController
{
    BMNavigationController *navCtl = [self getCurrentNavigationController];

    NSArray *carray = navCtl.viewControllers;
    if (![carray bm_isNotEmpty])
    {
        return nil;
    }
    
    // 获取rootVC
    UIViewController *vc = [carray firstObject];
    return vc;
}

- (UIViewController *)getCurrentViewController
{
    BMNavigationController *navCtl = [self getCurrentNavigationController];
    
    NSArray *carray = navCtl.viewControllers;
    if (![carray bm_isNotEmpty])
    {
        return nil;
    }
    
    // 获取topVC
    UIViewController *vc = [carray lastObject];
    return vc;
}

@end
