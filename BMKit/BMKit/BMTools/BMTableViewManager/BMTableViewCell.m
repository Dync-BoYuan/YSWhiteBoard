//
//  BMTableViewCell.m
//  BMTableViewManagerSample
//
//  Created by DennisDeng on 2017/8/7.
//  Copyright © 2017年 DennisDeng. All rights reserved.
//

#import "BMTableViewCell.h"
#import "BMTableViewManager.h"
#import "BMTableViewItem.h"

#import "BMSingleLineView.h"

#import "UIImageView+BMWebCache.h"

#define Default_Text_Color          [UIColor bm_colorWithHex:0x666666]
#define Default_Text_Font           [UIFont systemFontOfSize:16.0f]

#define Default_DetailText_Color    [UIColor bm_colorWithHex:0x888888]
#define Default_DetailText_Font     [UIFont systemFontOfSize:14.0f]

#define IMAGE_LABLE_GAP     8.0f

@interface BMTableViewCell ()

@property (assign, readwrite, nonatomic) BOOL loaded;
@property (strong, readwrite, nonatomic) UIImageView *backgroundImageView;
@property (strong, readwrite, nonatomic) UIImageView *selectedBackgroundImageView;

@property (strong, readwrite, nonatomic) BMSingleLineView *singleLineView;

@end

@implementation BMTableViewCell

+ (CGFloat)heightWithItem:(BMTableViewItem *)item tableViewManager:(BMTableViewManager *)tableViewManager
{
    CGFloat cellHeight = 0;
    if ([item isKindOfClass:[BMTableViewItem class]])
    {
        if (item.cellHeight > 0)
        {
            cellHeight = item.cellHeight;
        }
        else if (item.cellHeight == 0)
        {
            cellHeight = item.section.style.cellHeight;
        }
    }
    
    if (cellHeight == 0)
    {
        cellHeight = tableViewManager.style.cellHeight;
    }
    
    return cellHeight;
}

+ (BOOL)canFocusWithItem:(BMTableViewItem *)item
{
    return NO;
}


#pragma mark - UI

- (void)addBackgroundImage
{
    self.tableViewManager.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.backgroundView = [[UIView alloc] initWithFrame:self.contentView.bounds];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.backgroundView.bounds.size.width, self.backgroundView.bounds.size.height + 1)];
    self.backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.backgroundView addSubview:self.backgroundImageView];
}

- (void)addSelectedBackgroundImage
{
    self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.contentView.bounds];
    self.selectedBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.selectedBackgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.selectedBackgroundView.bounds.size.width, self.selectedBackgroundView.bounds.size.height + 1)];
    self.selectedBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.selectedBackgroundView addSubview:self.selectedBackgroundImageView];
}

- (void)drawSingleLineView
{
    if (self.tableViewManager.tableView.separatorStyle != UITableViewCellSeparatorStyleNone)
    {
        return;
    }
    
    if (!self.singleLineView.superview)
    {
        CGRect frame = CGRectMake(0, 0, self.contentView.bm_width, 1);
        self.singleLineView = [[BMSingleLineView alloc] initWithFrame:frame];
        self.singleLineView.needGap = NO;
        [self addSubview:self.singleLineView];
    }
    
    self.singleLineView.isDash = self.item.underLineIsDash;
    if (self.item.underLineColor)
    {
        self.singleLineView.lineColor = self.item.underLineColor;
    }
    else
    {
        self.singleLineView.lineColor = BMUI_DEFAULT_LINECOLOR;
    }
    self.singleLineView.lineWidth = self.item.underLineWidth;
    if (self.item.underLineWidth > 1.0f)
    {
        self.singleLineView.bm_height = self.item.underLineWidth;
    }
    self.singleLineView.bm_top = self.contentView.bm_height;
    
    //self.singleLineView.hidden = !self.item.isDrawUnderLine;
}

- (BMTableViewCell_PositionType)positionType
{
    if (self.rowIndex == 0 && self.section.items.count == 1)
    {
        return BMTableViewCell_PositionType_Single;
    }
    
    if (self.rowIndex == 0 && self.section.items.count > 1)
    {
        return BMTableViewCell_PositionType_First;
    }
    
    if (self.rowIndex > 0 && self.rowIndex < self.section.items.count - 1 && self.section.items.count > 2)
    {
        return BMTableViewCell_PositionType_Middle;
    }
    
    if (self.rowIndex == self.section.items.count - 1 && self.section.items.count > 1)
    {
        return BMTableViewCell_PositionType_Last;
    }
    
    return BMTableViewCell_PositionType_None;
}

#pragma mark -
#pragma mark Cell life cycle

// item == nil
- (void)cellDidLoad
{
    self.loaded = YES;
    
    self.actionBar = [[BMTableViewActionBar alloc] initWithDelegate:self];
    
    self.selectionStyle = self.tableViewManager.style.defaultCellSelectionStyle;
    
    if ([self.tableViewManager.style hasCustomBackgroundImage])
    {
        [self addBackgroundImage];
    }
    
    if ([self.tableViewManager.style hasCustomSelectedBackgroundImage])
    {
        [self addSelectedBackgroundImage];
    }
}

// item != nil
- (void)cellWillAppear
{
    [self updateActionBarNavigationControl];
    
    self.selectionStyle = self.section.style.defaultCellSelectionStyle;
    
    self.backgroundColor = self.item.cellBgColor;
    
    if ([self.item isKindOfClass:[NSString class]])
    {
        self.textLabel.text = (NSString *)self.item;
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else
    {
        BMTableViewItem *item = (BMTableViewItem *)self.item;
     
        if (self.selectionStyle != UITableViewCellSelectionStyleNone)
        {
            self.selectionStyle = item.selectionStyle;
        }
        
        if (item.titleAttrStr)
        {
            self.textLabel.attributedText = item.titleAttrStr;
        }
        else
        {
            self.textLabel.text = item.title;

            if (item.textFont)
            {
                self.textLabel.font = item.textFont;
            }
            else
            {
                self.textLabel.font = Default_Text_Font;
            }

            self.textLabel.backgroundColor = [UIColor clearColor];

            if (item.textColor)
            {
                self.textLabel.textColor = item.textColor;
            }
            else
            {
                self.textLabel.textColor = Default_Text_Color;
            }
        }
        self.textLabel.textAlignment = item.textAlignment;
        
        self.textLabel.numberOfLines = item.titleNumberOfLines;
        self.textLabel.lineBreakMode = item.titleLineBreakMode;

        if (item.detailAttrStr)
        {
            self.detailTextLabel.attributedText = item.detailAttrStr;
        }
        else
        {
            self.detailTextLabel.text = item.detailLabelText;
            
            if (item.detailTextFont)
            {
                self.detailTextLabel.font = item.detailTextFont;
            }
            else
            {
                self.detailTextLabel.font = Default_DetailText_Font;
            }

            self.detailTextLabel.backgroundColor = [UIColor clearColor];
            
            if (item.detailTextColor)
            {
                self.detailTextLabel.textColor = item.detailTextColor;
            }
            else
            {
                self.detailTextLabel.textColor = Default_DetailText_Color;
            }
        }
        self.detailTextLabel.textAlignment = item.detailTextAlignment;
        
        self.detailTextLabel.numberOfLines = item.detailNumberOfLines;
        self.detailTextLabel.lineBreakMode = item.detailLineBreakMode;

        self.accessoryType = item.accessoryType;
        self.accessoryView = item.accessoryView;
        
        self.imageView.image = item.image;
        if (item.imageUrl)
        {
            [self.imageView bm_setImageWithURL:[NSURL URLWithString:item.imageUrl] placeholderImage:item.image options:BMSDWebImageRetryFailed|BMSDWebImageLowPriority completed:^(UIImage *image, NSError *error, BMSDImageCacheType cacheType, NSURL *imageURL) {
            }];
        }
        
        self.imageView.highlightedImage = item.highlightedImage;
        if (item.highlightedImageUrl)
        {
            BMWeakSelf
            [[BMSDWebImageManager sharedManager] loadImageWithURL:[NSURL URLWithString:item.highlightedImageUrl] options:BMSDWebImageRetryFailed|BMSDWebImageLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL *targetURL) {
            } completed:^(UIImage *image, NSData *data, NSError *error, BMSDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (image)
                    {
                        BMStrongSelf
                        strongSelf.imageView.highlightedImage = image;
                    }
                });
            }];
        }
        
        [self drawSingleLineView];
        
        if (![self.tableViewManager.style hasCustomBackgroundImage])
        {
            if (self.item.isShowSelectBg)
            {
                self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
                self.selectedBackgroundView.backgroundColor = [UIColor clearColor];
                UIView *view = [[UIView alloc] initWithFrame:self.bounds];
                view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

                //if (self.item.isDrawUnderLine && self.item.underLineDrawType != BMTableViewCell_UnderLineDrawType_None)
                if (self.item.underLineDrawType != BMTableViewCell_UnderLineDrawType_None)
                {
                    view.bm_height = self.bm_height-1;
                }
                else
                {
                    view.bm_height = self.bm_height;
                }
                view.backgroundColor = self.item.selectBgColor;
                
                [self.selectedBackgroundView addSubview:view];
            }
            else
            {
                self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
                self.selectedBackgroundView.backgroundColor = [UIColor clearColor];
            }
        }
        
        self.userInteractionEnabled = self.item.enabled;
    }
    
    if (self.textLabel.text.length == 0)
    {
        self.textLabel.text = @" ";
    }
}

- (void)cellDidDisappear
{
    
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self cellLayoutSubviews];
    
    if ([self.tableViewManager.delegate respondsToSelector:@selector(tableView:willLayoutCellSubviews:forRowAtIndexPath:)])
    {
        [self.tableViewManager.delegate tableView:self.tableViewManager.tableView willLayoutCellSubviews:self forRowAtIndexPath:[self.tableViewManager.tableView indexPathForCell:self]];
    }
}
    
- (void)cellLayoutSubviews
{
    // Set content frame
    //
    CGRect contentFrame = self.contentView.bounds;
    contentFrame.origin.x = contentFrame.origin.x + self.section.style.contentViewMargin;
    contentFrame.size.width = contentFrame.size.width - self.section.style.contentViewMargin * 2;
    self.contentView.bounds = contentFrame;
    
    // iOS 7 textLabel margin fix
    //
    if (self.section.style.contentViewMargin > 0)
    {
        if (self.imageView.image)
        {
            if (self.item.imageAtback)
            {
                self.textLabel.frame = CGRectMake(self.section.style.contentViewMargin, self.textLabel.frame.origin.y, self.textLabel.frame.size.width, self.textLabel.frame.size.height);
                
                CGFloat width = [self.textLabel bm_labelSizeToFitWidth:BMUI_SCREEN_WIDTH].width;
               self.imageView.frame = CGRectMake(self.section.style.contentViewMargin + width + IMAGE_LABLE_GAP, self.imageView.frame.origin.y, self.imageView.frame.size.width, self.imageView.frame.size.height);
             }
            else
            {
                self.imageView.frame = CGRectMake(self.section.style.contentViewMargin, self.imageView.frame.origin.y, self.imageView.frame.size.width, self.imageView.frame.size.height);
                self.textLabel.frame = CGRectMake(self.section.style.contentViewMargin + self.imageView.frame.size.width + IMAGE_LABLE_GAP, self.textLabel.frame.origin.y, self.textLabel.frame.size.width, self.textLabel.frame.size.height);
            }
        }
        else
        {
            self.textLabel.frame = CGRectMake(self.section.style.contentViewMargin, self.textLabel.frame.origin.y, self.textLabel.frame.size.width, self.textLabel.frame.size.height);
        }
    }
    else
    {
        if (self.imageView.image)
        {
            if (self.item.imageAtback)
            {
                self.textLabel.bm_left = self.imageView.bm_left;

                if (self.item.imageW > 0 && self.item.imageH > 0)
                {
                    self.imageView.bm_width = self.item.imageW;
                    self.imageView.bm_height = self.item.imageH;
                    self.imageView.bm_centerY = self.bm_height * 0.5;
                }
                CGFloat width = [self.textLabel bm_labelSizeToFitWidth:BMUI_SCREEN_WIDTH].width;
                self.imageView.bm_left = self.textLabel.bm_left + width + IMAGE_LABLE_GAP;
            }
            else
            {
                if (self.item.imageW > 0 && self.item.imageH > 0)
                {
                    self.imageView.bm_width = self.item.imageW;
                    self.imageView.bm_height = self.item.imageH;
                    self.imageView.bm_centerY = self.bm_height * 0.5;
                }
                
                CGFloat width = self.imageView.bm_width;
                
                self.textLabel.bm_left = self.imageView.bm_left + width + IMAGE_LABLE_GAP;
            }
                
            if (self.item.cellStyle == UITableViewCellStyleSubtitle)
            {
                self.detailTextLabel.bm_left = self.textLabel.bm_left;
            }
        }
    }
    
    if (self.tableViewManager.tableView.separatorStyle == UITableViewCellSeparatorStyleNone)
    {
        UIEdgeInsets separatorInset = self.tableViewManager.tableView.separatorInset;
        self.singleLineView.bm_left = separatorInset.left;
        self.singleLineView.bm_bottom = self.contentView.bm_height;
        
        self.singleLineView.hidden = NO;
        if ([self.item isKindOfClass:[BMTableViewItem class]])
        {
            switch (self.item.underLineDrawType)
            {
                case BMTableViewCell_UnderLineDrawType_SeparatorAllLeftInset:
                {
                    self.singleLineView.bm_width = self.bm_width - separatorInset.left*2;
                    break;
                }
                case BMTableViewCell_UnderLineDrawType_Image:
                {
                    self.singleLineView.bm_left = self.textLabel.bm_left;
                    self.singleLineView.bm_width = self.bm_width - self.textLabel.bm_left;
                    break;
                }
                case BMTableViewCell_UnderLineDrawType_ImageInset:
                {
                    self.singleLineView.bm_left = self.textLabel.bm_left;
                    self.singleLineView.bm_width = self.bm_width - separatorInset.left - self.textLabel.bm_left;
                    break;
                }
                case BMTableViewCell_UnderLineDrawType_SeparatorInset:
                {
                    self.singleLineView.bm_width = self.contentView.bm_width - separatorInset.left - separatorInset.right;
                    break;
                }
                case BMTableViewCell_UnderLineDrawType_SeparatorLeftInset:
                {
                    self.singleLineView.bm_width = self.bm_width - separatorInset.left;
                    break;
                }
                case BMTableViewCell_UnderLineDrawType_Full:
                {
                    self.singleLineView.bm_left = 0;
                    self.singleLineView.bm_width = self.bm_width;
                    break;
                }
                case BMTableViewCell_UnderLineDrawType_None:
                default:
                {
                    self.singleLineView.hidden = YES;
                }
            }
        }
    }
    
    if ([self.section.style hasCustomBackgroundImage])
    {
        self.backgroundColor = [UIColor clearColor];
        if (!self.backgroundImageView)
        {
            [self addBackgroundImage];
        }
        self.backgroundImageView.image = [self.section.style backgroundImageForCellPositionType:self.positionType];
    }
    
    if ([self.section.style hasCustomSelectedBackgroundImage])
    {
        if (!self.selectedBackgroundImageView)
        {
            [self addSelectedBackgroundImage];
        }
        self.selectedBackgroundImageView.image = [self.section.style selectedBackgroundImageForCellPositionType:self.positionType];
    }
    
    // Set background frame
    //
    CGRect backgroundFrame = self.backgroundImageView.frame;
    backgroundFrame.origin.x = self.section.style.backgroundImageMargin;
    backgroundFrame.size.width = self.backgroundView.frame.size.width - self.section.style.backgroundImageMargin * 2;
    self.backgroundImageView.frame = backgroundFrame;
    self.selectedBackgroundImageView.frame = backgroundFrame;
    
    if (self.item.cellStyle == UITableViewCellStyleValue2)
    {
        self.textLabel.textAlignment = self.item.textAlignment;
        if (self.item.contentMiddleGap > 1)
        {
            self.detailTextLabel.bm_left = self.textLabel.bm_right + self.item.contentMiddleGap;
        }
    }
    else if (self.item.cellStyle == UITableViewCellStyleSubtitle)
    {
        self.textLabel.bm_top = self.textLabel.bm_top-self.item.contentMiddleGap*0.5;
        self.detailTextLabel.bm_top = self.textLabel.bm_bottom+self.item.contentMiddleGap;
        
        switch (self.item.subtitleStyleImageAlignment)
        {
            case BMTableViewCell_SubtitleStyleImageAlignmentTop:
                self.imageView.bm_top = self.textLabel.bm_top;
                break;
                
            case BMTableViewCell_SubtitleStyleImageAlignmentBottom:
                self.imageView.bm_top = self.detailTextLabel.bm_bottom-self.imageView.bm_height;
                break;
                
            case BMTableViewCell_SubtitleStyleImageAlignmentCenter:
            default:
                break;
        }
    }
}

- (void)layoutDetailView:(UIView *)view minimumWidth:(CGFloat)minimumWidth
{
    CGFloat cellOffset = 15.0;

    if (self.accessoryView)
    {
        cellOffset = 0.0f;
    }
    
    CGFloat fieldOffset = 6.0;
    
    if (self.section.style.contentViewMargin <= 0)
    {
        cellOffset += 5.0;
    }
    
    UIFont *font = self.textLabel.font;
    
    CGRect frame = CGRectMake(0, self.textLabel.frame.origin.y, 0, self.textLabel.frame.size.height);
    if (self.item.title.length > 0)
    {
        frame.origin.x = self.textLabel.bm_left + [self.section maximumTitleWidthWithFont:font] + fieldOffset;
    }
    else if (self.item.titleAttrStr.length > 0)
    {
        frame.origin.x = self.textLabel.bm_left + [self.section maximumTitleWidthWithFont:font] + fieldOffset;
    }
    else
    {
        //frame.origin.x = cellOffset;
        if (self.imageView.image)
        {
            frame.origin.x = self.imageView.bm_right + fieldOffset;
        }
        else
        {
            frame.origin.x = cellOffset;
        }
    }

    frame.size.width = self.contentView.frame.size.width - frame.origin.x - cellOffset;
    if (frame.size.width < minimumWidth)
    {
        CGFloat diff = minimumWidth - frame.size.width;
        frame.origin.x = frame.origin.x - diff;
        frame.size.width = minimumWidth;
    }
    
    view.frame = frame;
}

#pragma mark - HighlightedAnimation

- (void)showHighlightedAnimation
{
    UIView *tmpView = [[UIView alloc] initWithFrame:self.bounds];
    tmpView.backgroundColor = self.item.highlightBgColor;
    tmpView.alpha = 0.f;
    [self addSubview:tmpView];
    
    [UIView animateWithDuration:0.20 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        
        tmpView.alpha = 0.8f;
        
    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:0.20 delay:0.1 options:UIViewAnimationOptionCurveEaseOut animations:^{
            
            tmpView.alpha = 0.f;
            
        } completion:^(BOOL finished) {
            
            [tmpView removeFromSuperview];
        }];
    }];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    //[super setHighlighted:highlighted animated:animated];
    
    if ([self.item isKindOfClass:[BMTableViewItem class]])
    {
        if (highlighted && self.item.isShowHighlightBg)
        {
            [self showHighlightedAnimation];
        }
        else
        {
            [super setHighlighted:highlighted animated:animated];
        }
    }
    else
    {
        [super setHighlighted:highlighted animated:animated];
    }
}

#pragma mark - ActionBar

- (UIResponder *)responder
{
    return nil;
}

- (void)updateActionBarNavigationControl
{
    [self.actionBar.navigationControl setEnabled:[self indexPathForPreviousResponder] != nil forSegmentAtIndex:0];
    [self.actionBar.navigationControl setEnabled:[self indexPathForNextResponder] != nil forSegmentAtIndex:1];
    if (self.item.actionBarTitle)
    {
        [self.actionBar setActionBarTitle:self.item.actionBarTitle];
    }
    else
    {
        [self.actionBar setActionBarTitle:self.item.title];
    }
}

- (NSIndexPath *)indexPathForPreviousResponderInSectionIndex:(NSUInteger)sectionIndex
{
    BMTableViewSection *section = self.tableViewManager.sections[sectionIndex];
    NSUInteger indexInSection =  [section isEqual:self.section] ? [section.items indexOfObject:self.item] : section.items.count;
    for (NSInteger i = indexInSection - 1; i >= 0; i--)
    {
        BMTableViewItem *item = section.items[i];
        if ([item isKindOfClass:[BMTableViewItem class]])
        {
            Class class = [self.tableViewManager classForCellAtIndexPath:item.indexPath];
            if ([class canFocusWithItem:item])
            {
                return [NSIndexPath indexPathForRow:i inSection:sectionIndex];
            }
        }
    }
    return nil;
}

- (NSIndexPath *)indexPathForPreviousResponder
{
    for (NSInteger i = self.sectionIndex; i >= 0; i--)
    {
        NSIndexPath *indexPath = [self indexPathForPreviousResponderInSectionIndex:i];
        if (indexPath)
        {
            return indexPath;
        }
    }
    return nil;
}

- (NSIndexPath *)indexPathForNextResponderInSectionIndex:(NSUInteger)sectionIndex
{
    BMTableViewSection *section = self.tableViewManager.sections[sectionIndex];
    NSUInteger indexInSection =  [section isEqual:self.section] ? [section.items indexOfObject:self.item] : -1;
    for (NSInteger i = indexInSection + 1; i < section.items.count; i++)
    {
        BMTableViewItem *item = section.items[i];
        if ([item isKindOfClass:[BMTableViewItem class]])
        {
            Class class = [self.tableViewManager classForCellAtIndexPath:item.indexPath];
            if ([class canFocusWithItem:item])
            {
                return [NSIndexPath indexPathForRow:i inSection:sectionIndex];
            }
        }
    }
    return nil;
}

- (NSIndexPath *)indexPathForNextResponder
{
    for (NSInteger i = self.sectionIndex; i < self.tableViewManager.sections.count; i++)
    {
        NSIndexPath *indexPath = [self indexPathForNextResponderInSectionIndex:i];
        if (indexPath)
        {
            return indexPath;
        }
    }
    return nil;
}

#pragma mark -
#pragma mark REActionBar delegate

- (void)actionBar:(BMTableViewActionBar *)actionBar navigationControlValueChanged:(UISegmentedControl *)navigationControl
{
    NSIndexPath *indexPath = navigationControl.selectedSegmentIndex == 0 ? [self indexPathForPreviousResponder] : [self indexPathForNextResponder];
    if (indexPath)
    {
        BMTableViewCell *cell = (BMTableViewCell *)[self.parentTableView cellForRowAtIndexPath:indexPath];
        if (!cell)
        {
            [self.parentTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
        }
        //cell = (BMTableViewCell *)[self.parentTableView cellForRowAtIndexPath:indexPath];
        [cell.responder becomeFirstResponder];
    }
    if (self.item.actionBarNavButtonTapHandler)
    {
        self.item.actionBarNavButtonTapHandler(self.item);
    }
}

- (void)actionBar:(BMTableViewActionBar *)actionBar doneButtonPressed:(UIBarButtonItem *)doneButtonItem
{
    if (self.item.actionBarDoneButtonTapHandler)
    {
        self.item.actionBarDoneButtonTapHandler(self.item);
    }
    
    [self endEditing:YES];
}

@end
