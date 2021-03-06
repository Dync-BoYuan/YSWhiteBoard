//
//  BMTableViewLongTextCell.m
//  BMTableViewManagerSample
//
//  Created by DennisDeng on 2018/4/20.
//  Copyright © 2018年 DennisDeng. All rights reserved.
//

#import "BMTableViewLongTextCell.h"
#import "BMLongTextItem.h"

@interface BMTableViewLongTextCell ()

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL editable;

@property (nonatomic, strong) BMLongTextItem *item;
@property (nonatomic, strong) BMPlaceholderTextView *textView;

@end

@implementation BMTableViewLongTextCell
@synthesize item = _item;

+ (BOOL)canFocusWithItem:(BMLongTextItem *)item
{
    if (item.enabled)
    {
        return item.editable;
    }
    
    return NO;
}

- (void)dealloc
{
    if (_item != nil)
    {
        [_item removeObserver:self forKeyPath:@"enabled"];
        [_item removeObserver:self forKeyPath:@"editable"];
        [_item removeObserver:self forKeyPath:@"textViewTypingAttributes"];
    }
}

- (UIResponder *)responder
{
    return self.textView;
}

- (void)cellDidLoad
{
    [super cellDidLoad];
    self.textLabel.backgroundColor = [UIColor clearColor];
    
    self.textView = [[BMPlaceholderTextView alloc] initWithFrame:CGRectZero];
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.inputAccessoryView = self.actionBar;
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.textView.delegate = self;

//    self.textView.layer.cornerRadius = 4.0f;
//    self.textView.layer.borderWidth = SINGLE_LINE_WIDTH;
//    self.textView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
//    self.textView.layer.masksToBounds = YES;

    [self.contentView addSubview:self.textView];
}

- (void)cellWillAppear
{
    [super cellWillAppear];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.accessoryType = UITableViewCellAccessoryNone;
    self.accessoryView = nil;

    if (self.item.attributedValue)
    {
        self.textView.attributedText = self.item.attributedValue;
    }
    else
    {
        self.textView.text = self.item.value;
    }
    
    self.textView.placeholder = self.item.placeholder;
    
    if (!UIEdgeInsetsEqualToEdgeInsets(self.item.textViewTextContainerInset, UIEdgeInsetsZero))
    {
        self.textView.textContainerInset = self.item.textViewTextContainerInset;
    }
    
    if (self.item.textViewPlaceholderColor)
    {
        self.textView.placeholderColor = self.item.textViewPlaceholderColor;
    }
    self.textView.placeholderLineBreakMode = self.item.textViewPlaceholderLineBreakMode;

    // 分开设置typingAttributes
    if (self.item.textViewLinkTextAttributes)
    {
        self.textView.typingAttributes = self.item.textViewLinkTextAttributes;
    }
    else
    {
        self.textView.font = self.item.textViewFont;
        if (self.item.textViewTextColor)
        {
            self.textView.textColor = self.item.textViewTextColor;
        }
        self.textView.textAlignment = self.item.textViewTextAlignment;
    }
    
    if (self.item.textViewBgColor)
    {
        self.textView.backgroundColor = self.item.textViewBgColor;
    }

    self.textView.selectable = self.item.textViewSelectable;
    
    self.textView.autocapitalizationType = self.item.autocapitalizationType;
    self.textView.autocorrectionType = self.item.autocorrectionType;
    self.textView.spellCheckingType = self.item.spellCheckingType;
    self.textView.keyboardType = self.item.keyboardType;
    self.textView.keyboardAppearance = self.item.keyboardAppearance;
    self.textView.returnKeyType = self.item.returnKeyType;
    self.textView.enablesReturnKeyAutomatically = self.item.enablesReturnKeyAutomatically;
    self.textView.secureTextEntry = self.item.secureTextEntry;
    self.textView.hidden = self.item.hideInputView;

    self.actionBar.barStyle = self.item.keyboardAppearance == UIKeyboardAppearanceAlert ? UIBarStyleBlack : UIBarStyleDefault;
    
    self.enabled = self.item.enabled;
    self.editable = self.item.editable;

    if (self.item.showTextViewBorder)
    {
        self.textView.layer.cornerRadius = 4.0f;
        self.textView.layer.borderWidth = BMSINGLE_LINE_WIDTH;
        if (self.item.textViewBorderColor)
        {
            self.textView.layer.borderColor = [self.item.textViewBorderColor CGColor];
        }
        else
        {
            self.textView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        }
        self.textView.layer.masksToBounds = YES;
    }
    else
    {
        self.textView.layer.cornerRadius = 0.0f;
        self.textView.layer.borderWidth = 0.0f;
        self.textView.layer.masksToBounds = NO;
    }
    //self.textView.backgroundColor = [UIColor redColor];
}

- (void)cellLayoutSubviews
{
    [super cellLayoutSubviews];
    
    self.textLabel.bm_top = self.item.textLabelTopGap;
    self.textLabel.bm_height = self.textLabel.font.pointSize+8.0f;

    CGFloat top = self.item.textViewTopGap;
    CGFloat left = self.textLabel.bm_left + self.item.textViewLeftGap;
    CGRect frame;
    
    if ([[self.textLabel.text bm_trim] bm_isNotEmpty])
    {
        CGFloat top = self.textLabel.bm_top + self.textLabel.bm_height + self.item.textViewTopGap;
        frame = CGRectMake(left, top, self.textLabel.bm_width-2.0*self.item.textViewLeftGap, self.bm_height-top-self.item.textViewTopGap);
    }
    else
    {
        frame = CGRectMake(left, top, self.textLabel.bm_width-2.0*self.item.textViewLeftGap, self.bm_height-2*self.item.textViewTopGap);
    }
    
    self.textView.frame = frame;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    if (selected)
    {
        [self.textView becomeFirstResponder];
    }
}


#pragma mark -
#pragma mark Handle state

- (void)setItem:(BMLongTextItem *)item
{
    if (_item != nil)
    {
        [_item removeObserver:self forKeyPath:@"enabled"];
        [_item removeObserver:self forKeyPath:@"editable"];
        [_item removeObserver:self forKeyPath:@"textViewTypingAttributes"];
    }
    
    _item = item;
    
    [_item addObserver:self forKeyPath:@"enabled" options:NSKeyValueObservingOptionNew context:NULL];
    [_item addObserver:self forKeyPath:@"editable" options:NSKeyValueObservingOptionNew context:NULL];
    [_item addObserver:self forKeyPath:@"textViewTypingAttributes" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    
    self.userInteractionEnabled = _enabled;
    
    self.textLabel.enabled = _enabled;
    self.textView.editable = _enabled;
    
    //((UIControl *)self.responder).enabled = enabled;
}

- (void)setEditable:(BOOL)enabled
{
    if (!_enabled)
    {
        BMLog(@"Cell is disabled");
        enabled = NO;
    }
    
    _editable = enabled;
    
    self.userInteractionEnabled = _editable;
    
    self.textView.editable = _editable;
    //self.textView.userInteractionEnabled = _editable;
    
    //((UIControl *)self.responder).enabled = _editable;
    //((UIControl *)self.responder).userInteractionEnabled = _editable;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isKindOfClass:[BMLongTextItem class]] && [keyPath isEqualToString:@"enabled"])
    {
        BOOL newValue = [[change objectForKey: NSKeyValueChangeNewKey] boolValue];
        
        self.enabled = newValue;
    }
    else if ([object isKindOfClass:[BMLongTextItem class]] && [keyPath isEqualToString:@"editable"])
    {
        BOOL newValue = [[change objectForKey: NSKeyValueChangeNewKey] boolValue];
        
        self.editable = newValue;
    }
    else if ([object isKindOfClass:[BMLongTextItem class]] && [keyPath isEqualToString:@"textViewTypingAttributes"])
    {
        id newValue = [change objectForKey: NSKeyValueChangeNewKey];
        
        self.textView.typingAttributes = newValue;
    }
}



#pragma mark -
#pragma mark Text field events

- (void)textViewDidChange:(UITextView *)textView
{
    if (self.item.charactersLimit)
    {
        NSString *textViewText = textView.text;
        
        // ios7之前使用 [UITextInputMode currentInputMode].primaryLanguage
        NSString *lang = [[UIApplication sharedApplication]textInputMode].primaryLanguage;
        
        if ([lang isEqualToString:@"zh-Hans"])
        {
            // 中文输入
            UITextRange *selectedRange = textView.markedTextRange;
            UITextPosition *position = [textView positionFromPosition:selectedRange.start offset:0];
            // 没有高亮选择的字，则对已输入的文字进行字数统计和限制
            if (!position)
            {
                // 判断是否超过最大字数限制，如果超过就截断
                if (textViewText.length > self.item.charactersLimit)
                {
                    textView.text = [textViewText substringToIndex:self.item.charactersLimit];
                }
            }
        }
        else
        {
            // 中文输入法以外的直接对其统计限制即可，不考虑其他语种情况
            if (textViewText.length > self.item.charactersLimit)
            {
                textView.text = [textViewText substringToIndex:self.item.charactersLimit];
            }
        }
    }
    
    self.item.value = textView.text;
    if (self.item.onChange)
    {
        self.item.onChange(self.item);
    }
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    NSIndexPath *indexPath = [self indexPathForNextResponder];
    if (indexPath)
    {
        textView.returnKeyType = UIReturnKeyNext;
    }
    else
    {
        textView.returnKeyType = self.item.returnKeyType;
    }
    [self updateActionBarNavigationControl];
    [self.parentTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.rowIndex inSection:self.sectionIndex] atScrollPosition:UITableViewScrollPositionNone animated:NO];
    if (self.item.onBeginEditing)
    {
        self.item.onBeginEditing(self.item);
    }
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView;
{
    if (self.item.onEndEditing)
    {
        self.item.onEndEditing(self.item);
    }
    return YES;
}

//- (BOOL)textFieldShouldReturn:(UITextField *)textField
//{
//    if (self.item.onReturn)
//    {
//        self.item.onReturn(self.item);
//    }
//    //    if (self.item.onEndEditing)
//    //    {
//    //        self.item.onEndEditing(self.item);
//    //    }
//    NSIndexPath *indexPath = [self indexPathForNextResponder];
//    if (!indexPath)
//    {
//        [self endEditing:YES];
//        return YES;
//    }
//    BMTableViewCell *cell = (BMTableViewCell *)[self.parentTableView cellForRowAtIndexPath:indexPath];
//    [cell.responder becomeFirstResponder];
//    return YES;
//}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    BOOL shouldChange = YES;
    
#if (0)
    if (self.item.charactersLimit)
    {
        NSUInteger newLength = textView.text.length + text.length - range.length;
        shouldChange = newLength <= self.item.charactersLimit;
    }
#endif
    
    if (self.item.onChangeCharacterInRange && shouldChange)
    {
        shouldChange = self.item.onChangeCharacterInRange(self.item, range, text);
    }
    
    return shouldChange;
}

@end
