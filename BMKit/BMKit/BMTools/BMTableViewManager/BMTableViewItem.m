//
//  BMTableViewItem.m
//  BMTableViewManagerSample
//
//  Created by DennisDeng on 2017/4/20.
//  Copyright © 2017年 DennisDeng. All rights reserved.
//

#import "BMTableViewItem.h"
#import "BMTableViewManager.h"
#import "BMTableViewSection.h"

@implementation BMTableViewItem

+ (instancetype)item
{
    return [[self alloc] init];
}

+ (instancetype)itemWithTitle:(NSString *)title
{
    return [[self alloc] initWithTitle:title];
}

+ (instancetype)itemWithTitle:(NSString *)title accessoryType:(UITableViewCellAccessoryType)accessoryType selectionHandler:(tableViewSelectionHandler)selectionHandler
{
    return [[self alloc] initWithTitle:title accessoryType:accessoryType selectionHandler:selectionHandler accessoryButtonTapHandler:nil];
}

+ (instancetype)itemWithTitle:(NSString *)title accessoryType:(UITableViewCellAccessoryType)accessoryType selectionHandler:(tableViewSelectionHandler)selectionHandler accessoryButtonTapHandler:(tableViewAccessoryButtonTapHandler)accessoryButtonTapHandler
{
    return [[self alloc] initWithTitle:title accessoryType:accessoryType selectionHandler:selectionHandler accessoryButtonTapHandler:accessoryButtonTapHandler];
}

- (instancetype)initWithTitle:(NSString *)title
{
    return [self initWithTitle:title accessoryType:UITableViewCellAccessoryNone selectionHandler:nil accessoryButtonTapHandler:nil];
}

- (instancetype)initWithTitle:(NSString *)title accessoryType:(UITableViewCellAccessoryType)accessoryType selectionHandler:(tableViewSelectionHandler)selectionHandler
{
    return [self initWithTitle:title accessoryType:accessoryType selectionHandler:selectionHandler accessoryButtonTapHandler:nil];
}

- (instancetype)initWithTitle:(NSString *)title accessoryType:(UITableViewCellAccessoryType)accessoryType selectionHandler:(tableViewSelectionHandler)selectionHandler accessoryButtonTapHandler:(tableViewAccessoryButtonTapHandler)accessoryButtonTapHandler
{
    self = [self init];
    
    if (!self)
    {
        return nil;
    }
    
    self.title = title;
    self.accessoryType = accessoryType;
    self.selectionHandler = selectionHandler;
    self.accessoryButtonTapHandler = accessoryButtonTapHandler;
    
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.enabled = YES;
        
        self.cellHeight = 0.0f;
        
        self.cellStyle = UITableViewCellStyleDefault;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.editingStyle = UITableViewCellEditingStyleNone;
        
        self.cellBgColor = [UIColor whiteColor];
        
        self.textColor = [UIColor darkGrayColor];
        self.detailTextColor = [UIColor grayColor];
        self.textFont = [UIFont systemFontOfSize:16.0f];
        self.detailTextFont = [UIFont systemFontOfSize:12.0f];
        self.textAlignment = NSTextAlignmentLeft;
        self.titleLineBreakMode = NSLineBreakByCharWrapping;
        self.detailTextAlignment = NSTextAlignmentLeft;
        self.detailLineBreakMode = NSLineBreakByCharWrapping;
        
        //self.isDrawUnderLine = YES;
        self.underLineDrawType = BMTableViewCell_UnderLineDrawType_SeparatorInset;
        self.underLineIsDash = NO;
        self.underLineColor = BMUI_DEFAULT_LINECOLOR;
        self.underLineWidth = BMSINGLE_LINE_WIDTH;
        
        self.isShowSelectBg = NO;
        self.selectBgColor = BMUI_CELL_SELECT_BGCOLOR;
        self.isShowHighlightBg = YES;
        self.highlightBgColor = [BMUI_CELL_HIGHLIGHT_BGCOLOR colorWithAlphaComponent:0.15];

        self.contentTopBottomGap = 16.0f;
        self.contentMiddleGap = 8.0f;
        self.subtitleStyleImageAlignment = BMTableViewCell_SubtitleStyleImageAlignmentCenter;
    }
    
    return self;
}

+ (instancetype)itemWithTitle:(NSString *)title selectionHandler:(void(^)(BMTableViewItem *item))selectionHandler
{
    return [self itemWithTitle:title underLineDrawType:BMTableViewCell_UnderLineDrawType_SeparatorInset selectionHandler:selectionHandler];
}

+ (instancetype)itemWithTitle:(NSString *)title underLineDrawType:(BMTableViewCell_UnderLineDrawType)underLineDrawType selectionHandler:(void(^)(BMTableViewItem *item))selectionHandler
{
    return [self itemWithTitle:title underLineDrawType:underLineDrawType accessoryView:nil selectionHandler:selectionHandler];
}

+ (instancetype)itemWithTitle:(NSString *)title underLineDrawType:(BMTableViewCell_UnderLineDrawType)underLineDrawType accessoryView:(UIView *)accessoryView selectionHandler:(void(^)(BMTableViewItem *item))selectionHandler
{
    return [self itemWithTitle:title imageName:nil underLineDrawType:underLineDrawType accessoryView:accessoryView selectionHandler:selectionHandler];
}

+ (instancetype)itemWithTitle:(NSString *)title imageName:(NSString *)imageName underLineDrawType:(BMTableViewCell_UnderLineDrawType)underLineDrawType accessoryView:(UIView *)accessoryView selectionHandler:(void(^)(BMTableViewItem *item))selectionHandler
{
    return [self itemWithTitle:title subTitle:nil imageName:imageName underLineDrawType:underLineDrawType accessoryView:accessoryView selectionHandler:selectionHandler];
}

+ (instancetype)itemWithTitle:(NSString *)title subTitle:(NSString *)subTitle imageName:(NSString *)imageName underLineDrawType:(BMTableViewCell_UnderLineDrawType)underLineDrawType accessoryView:(UIView *)accessoryView selectionHandler:(void(^)(BMTableViewItem *item))selectionHandler
{
    return [[self alloc] initWithTitle:title subTitle:subTitle imageName:imageName underLineDrawType:underLineDrawType accessoryView:accessoryView selectionHandler:selectionHandler];
}

- (instancetype)initWithTitle:(NSString *)title selectionHandler:(void(^)(BMTableViewItem *item))selectionHandler
{
    return [self initWithTitle:title underLineDrawType:BMTableViewCell_UnderLineDrawType_SeparatorInset selectionHandler:selectionHandler];
}

- (instancetype)initWithTitle:(NSString *)title underLineDrawType:(BMTableViewCell_UnderLineDrawType)underLineDrawType selectionHandler:(void(^)(BMTableViewItem *item))selectionHandler
{
    return [self initWithTitle:title underLineDrawType:underLineDrawType accessoryView:nil selectionHandler:selectionHandler];
}

- (instancetype)initWithTitle:(NSString *)title underLineDrawType:(BMTableViewCell_UnderLineDrawType)underLineDrawType accessoryView:(UIView *)accessoryView selectionHandler:(void(^)(BMTableViewItem *item))selectionHandler
{
    return [self initWithTitle:title imageName:nil underLineDrawType:underLineDrawType accessoryView:accessoryView selectionHandler:selectionHandler];
}

- (instancetype)initWithTitle:(NSString *)title imageName:(NSString *)imageName underLineDrawType:(BMTableViewCell_UnderLineDrawType)underLineDrawType accessoryView:(UIView *)accessoryView selectionHandler:(void(^)(BMTableViewItem *item))selectionHandler
{
    return [self initWithTitle:title subTitle:nil imageName:imageName underLineDrawType:underLineDrawType accessoryView:accessoryView selectionHandler:selectionHandler];
}

- (instancetype)initWithTitle:(NSString *)title subTitle:(NSString *)subTitle imageName:(NSString *)imageName underLineDrawType:(BMTableViewCell_UnderLineDrawType)underLineDrawType accessoryView:(UIView *)accessoryView selectionHandler:(void(^)(BMTableViewItem *item))selectionHandler
{
    self = [self init];
    
    if (!self)
    {
        return nil;
    }
    
    self.cellStyle = UITableViewCellStyleDefault;

    self.title = title;
    self.textFont = UI_BM_FONT(16.0f);
    self.textColor = [UIColor darkGrayColor];;
    self.titleNumberOfLines = 1;

    self.detailLabelText = subTitle;
    self.detailTextFont = UI_BM_FONT(12.0f);
    self.detailTextColor = [UIColor grayColor];
    self.detailNumberOfLines = 1;
    
    self.imageW = 30;
    self.imageH = 30;
    
    if ([imageName bm_isNotEmpty])
    {
        self.image = [UIImage imageNamed:imageName];
    }
    
    self.underLineDrawType = underLineDrawType;
    
    self.accessoryView = accessoryView;
    
    self.selectionHandler = selectionHandler;
    
    return self;
}


#pragma mark -
#pragma mark BMImageTextView

+ (BMImageTextView *)DefaultAccessoryView
{
    return [[BMImageTextView alloc] initWithImage:@"BMTableView_arrows_rightBlack" height:BMTABLE_CELL_HEIGHT];
}

+ (BMImageTextView *)DefaultAccessoryViewWithClicked:(BMImageTextViewClicked)clicked
{
    BMImageTextView *imageTextView = [[BMImageTextView alloc] initWithImage:@"BMTableView_arrows_rightBlack" height:BMTABLE_CELL_HEIGHT];
    imageTextView.imageTextViewClicked = clicked;
    return imageTextView;
}

+ (instancetype)itemWithTitle:(NSString *)title useDefaultAccessoryView:(BOOL)useDefaultAccessoryView selectionHandler:(void(^)(BMTableViewItem *item))selectionHandler
{
    return [self itemWithTitle:title underLineDrawType:BMTableViewCell_UnderLineDrawType_SeparatorInset useDefaultAccessoryView:useDefaultAccessoryView selectionHandler:selectionHandler];
}

+ (instancetype)itemWithTitle:(NSString *)title underLineDrawType:(BMTableViewCell_UnderLineDrawType)underLineDrawType useDefaultAccessoryView:(BOOL)useDefaultAccessoryView selectionHandler:(void(^)(BMTableViewItem *item))selectionHandler
{
    return [self itemWithTitle:title imageName:nil underLineDrawType:underLineDrawType useDefaultAccessoryView:useDefaultAccessoryView selectionHandler:selectionHandler];
}

+ (instancetype)itemWithTitle:(NSString *)title imageName:(NSString *)imageName underLineDrawType:(BMTableViewCell_UnderLineDrawType)underLineDrawType useDefaultAccessoryView:(BOOL)useDefaultAccessoryView selectionHandler:(void(^)(BMTableViewItem *item))selectionHandler
{
    return [self itemWithTitle:title subTitle:nil imageName:imageName underLineDrawType:underLineDrawType useDefaultAccessoryView:useDefaultAccessoryView selectionHandler:selectionHandler];
}

+ (instancetype)itemWithTitle:(NSString *)title subTitle:(NSString *)subTitle imageName:(NSString *)imageName underLineDrawType:(BMTableViewCell_UnderLineDrawType)underLineDrawType useDefaultAccessoryView:(BOOL)useDefaultAccessoryView selectionHandler:(void(^)(BMTableViewItem *item))selectionHandler
{
    return [[self alloc] initWithTitle:title subTitle:subTitle imageName:imageName underLineDrawType:underLineDrawType useDefaultAccessoryView:useDefaultAccessoryView selectionHandler:selectionHandler];
}

- (instancetype)initWithTitle:(NSString *)title subTitle:(NSString *)subTitle imageName:(NSString *)imageName underLineDrawType:(BMTableViewCell_UnderLineDrawType)underLineDrawType useDefaultAccessoryView:(BOOL)useDefaultAccessoryView selectionHandler:(void(^)(BMTableViewItem *item))selectionHandler
{
    BMImageTextView *imageTextView = nil;
    if (useDefaultAccessoryView)
    {
        imageTextView = [BMTableViewItem DefaultAccessoryView];
    }
    
    return [self initWithTitle:title subTitle:subTitle imageName:imageName underLineDrawType:underLineDrawType accessoryView:imageTextView selectionHandler:selectionHandler];
}

+ (instancetype)itemWithTitle:(NSString *)title subTitle:(NSString *)subTitle imageName:(NSString *)imageName underLineDrawType:(BMTableViewCell_UnderLineDrawType)underLineDrawType rightAttributedText:(NSAttributedString *)attributedText rightImage:(NSString *)image  imageTextViewType:(BMImageTextViewType)imageTextViewType selectionHandler:(void(^)(BMTableViewItem *item))selectionHandler
{
    return [[self alloc] initWithTitle:title subTitle:subTitle imageName:imageName underLineDrawType:underLineDrawType rightAttributedText:attributedText rightImage:image imageTextViewType:imageTextViewType selectionHandler:selectionHandler];
}

- (instancetype)initWithTitle:(NSString *)title subTitle:(NSString *)subTitle imageName:(NSString *)imageName underLineDrawType:(BMTableViewCell_UnderLineDrawType)underLineDrawType rightAttributedText:(NSAttributedString *)attributedText rightImage:(NSString *)image  imageTextViewType:(BMImageTextViewType)imageTextViewType selectionHandler:(void(^)(BMTableViewItem *item))selectionHandler
{
    BMImageTextView *imageTextView = [[BMImageTextView alloc] initWithImage:image attributedText:attributedText type:imageTextViewType height:0 gap:6.0f];

    return [self initWithTitle:title subTitle:subTitle imageName:imageName underLineDrawType:underLineDrawType accessoryView:imageTextView selectionHandler:selectionHandler];
}


- (NSIndexPath *)indexPath
{
    return [NSIndexPath indexPathForRow:[self.section.items indexOfObject:self] inSection:self.section.index];
}


#pragma mark -
#pragma mark Manipulating table view row

- (void)selectRowAnimated:(BOOL)animated
{
    [self selectRowAnimated:animated scrollPosition:UITableViewScrollPositionNone];
}

- (void)selectRowAnimated:(BOOL)animated scrollPosition:(UITableViewScrollPosition)scrollPosition
{
    [self.section.tableViewManager.tableView selectRowAtIndexPath:self.indexPath animated:animated scrollPosition:scrollPosition];
}

- (void)deselectRowAnimated:(BOOL)animated
{
    [self.section.tableViewManager.tableView deselectRowAtIndexPath:self.indexPath animated:animated];
}

- (void)reloadRowWithAnimation:(UITableViewRowAnimation)animation
{
    [self.section.tableViewManager.tableView reloadRowsAtIndexPaths:@[self.indexPath] withRowAnimation:animation];
}

- (void)deleteRowWithAnimation:(UITableViewRowAnimation)animation
{
    BMTableViewSection *section = self.section;
    NSInteger row = self.indexPath.row;
    [section removeItemAtIndex:self.indexPath.row];
    [section.tableViewManager.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:section.index]] withRowAnimation:animation];
}

- (void)caleCellHeightWithTableView:(UITableView *)tableView
{
    if (self.cellStyle == UITableViewCellStyleDefault)
    {
        return;
    }
    if (self.detailNumberOfLines == 1 && self.titleNumberOfLines == 1)
    {
        return;
    }
    
    CGFloat height = self.contentTopBottomGap;

    CGFloat titleWidth = BMUI_SCREEN_WIDTH-(tableView.contentInset.left+tableView.contentInset.right)-30.0f;
    
    CGFloat titleHeight;
    if (self.titleAttrStr)
    {
        CGSize maxSize = CGSizeMake(titleWidth, CGFLOAT_MAX);
        titleHeight = ceil([self.titleAttrStr bm_sizeToFit:maxSize lineBreakMode:NSLineBreakByCharWrapping].height);
    }
    else
    {
        titleHeight = ceil([self.title bm_heightToFitWidth:titleWidth withFont:self.textFont]);
    }
    
    height += titleHeight;
    
    height += self.contentMiddleGap;

    CGFloat itemWidth = titleWidth;
    CGFloat itemHeight;
    if (self.detailAttrStr)
    {
        CGSize maxSize = CGSizeMake(itemWidth, CGFLOAT_MAX);
        itemHeight = ceil([self.detailAttrStr bm_sizeToFit:maxSize lineBreakMode:NSLineBreakByCharWrapping].height);
    }
    else
    {
        itemHeight = ceil([self.detailLabelText bm_heightToFitWidth:itemWidth withFont:self.detailTextFont]);
    }
    
    height += itemHeight;
    
    height += self.contentTopBottomGap;

    self.cellHeight = height;
}

@end
