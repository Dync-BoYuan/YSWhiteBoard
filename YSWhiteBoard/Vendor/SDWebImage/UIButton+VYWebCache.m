/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIButton+VYWebCache.h"

#if SD_UIKIT

#import "objc/runtime.h"
#import "UIView+VYWebCacheOperation.h"
#import "UIView+VYWebCache.h"

static char imageURLStorageKey;

typedef NSMutableDictionary<NSNumber *, NSURL *> VYSDStateImageURLDictionary;

@implementation UIButton (VYWebCache)

- (nullable NSURL *)VYsd_currentImageURL {
    NSURL *url = self.VYimageURLStorage[@(self.state)];

    if (!url) {
        url = self.VYimageURLStorage[@(UIControlStateNormal)];
    }

    return url;
}

- (nullable NSURL *)VYsd_imageURLForState:(UIControlState)state {
    return self.VYimageURLStorage[@(state)];
}

#pragma mark - Image

- (void)VYsd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state {
    [self VYsd_setImageWithURL:url forState:state placeholderImage:nil options:0 completed:nil];
}

- (void)VYsd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder {
    [self VYsd_setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:nil];
}

- (void)VYsd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(VYSDWebImageOptions)options {
    [self VYsd_setImageWithURL:url forState:state placeholderImage:placeholder options:options completed:nil];
}

- (void)VYsd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state completed:(nullable VYSDExternalCompletionBlock)completedBlock {
    [self VYsd_setImageWithURL:url forState:state placeholderImage:nil options:0 completed:completedBlock];
}

- (void)VYsd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder completed:(nullable VYSDExternalCompletionBlock)completedBlock {
    [self VYsd_setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)VYsd_setImageWithURL:(nullable NSURL *)url
                  forState:(UIControlState)state
          placeholderImage:(nullable UIImage *)placeholder
                   options:(VYSDWebImageOptions)options
                 completed:(nullable VYSDExternalCompletionBlock)completedBlock {
    if (!url) {
        [self.VYimageURLStorage removeObjectForKey:@(state)];
        return;
    }
    
    self.VYimageURLStorage[@(state)] = url;
    
    __weak typeof(self)weakSelf = self;
    [self VYsd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                        operationKey:[NSString stringWithFormat:@"UIButtonImageOperation%@", @(state)]
                       setImageBlock:^(UIImage *image, NSData *imageData) {
                           [weakSelf setImage:image forState:state];
                       }
                            progress:nil
                           completed:completedBlock];
}

#pragma mark - Background image

- (void)VYsd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state {
    [self VYsd_setBackgroundImageWithURL:url forState:state placeholderImage:nil options:0 completed:nil];
}

- (void)VYsd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder {
    [self VYsd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:nil];
}

- (void)VYsd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(VYSDWebImageOptions)options {
    [self VYsd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:options completed:nil];
}

- (void)VYsd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state completed:(nullable VYSDExternalCompletionBlock)completedBlock {
    [self VYsd_setBackgroundImageWithURL:url forState:state placeholderImage:nil options:0 completed:completedBlock];
}

- (void)VYsd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder completed:(nullable VYSDExternalCompletionBlock)completedBlock {
    [self VYsd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)VYsd_setBackgroundImageWithURL:(nullable NSURL *)url
                            forState:(UIControlState)state
                    placeholderImage:(nullable UIImage *)placeholder
                             options:(VYSDWebImageOptions)options
                           completed:(nullable VYSDExternalCompletionBlock)completedBlock {
    if (!url) {
        [self.VYimageURLStorage removeObjectForKey:@(state)];
        return;
    }
    
    self.VYimageURLStorage[@(state)] = url;
    
    __weak typeof(self)weakSelf = self;
    [self VYsd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                        operationKey:[NSString stringWithFormat:@"UIButtonBackgroundImageOperation%@", @(state)]
                       setImageBlock:^(UIImage *image, NSData *imageData) {
                           [weakSelf setBackgroundImage:image forState:state];
                       }
                            progress:nil
                           completed:completedBlock];
}

- (void)VYsd_setImageLoadOperation:(id<VYSDWebImageOperation>)operation forState:(UIControlState)state {
    [self VYsd_setImageLoadOperation:operation forKey:[NSString stringWithFormat:@"UIButtonImageOperation%@", @(state)]];
}

- (void)VYsd_cancelImageLoadForState:(UIControlState)state {
    [self VYsd_cancelImageLoadOperationWithKey:[NSString stringWithFormat:@"UIButtonImageOperation%@", @(state)]];
}

- (void)VYsd_setBackgroundImageLoadOperation:(id<VYSDWebImageOperation>)operation forState:(UIControlState)state {
    [self VYsd_setImageLoadOperation:operation forKey:[NSString stringWithFormat:@"UIButtonBackgroundImageOperation%@", @(state)]];
}

- (void)VYsd_cancelBackgroundImageLoadForState:(UIControlState)state {
    [self VYsd_cancelImageLoadOperationWithKey:[NSString stringWithFormat:@"UIButtonBackgroundImageOperation%@", @(state)]];
}

- (VYSDStateImageURLDictionary *)VYimageURLStorage {
    VYSDStateImageURLDictionary *storage = objc_getAssociatedObject(self, &imageURLStorageKey);
    if (!storage) {
        storage = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &imageURLStorageKey, storage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return storage;
}

@end

#endif
