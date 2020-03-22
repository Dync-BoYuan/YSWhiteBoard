/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIButton+BMWebCache.h"

#if SD_UIKIT

#import "objc/runtime.h"
#import "UIView+BMWebCacheOperation.h"
#import "UIView+BMWebCache.h"

static char imageURLStorageKey;

typedef NSMutableDictionary<NSString *, NSURL *> SDStateImageURLDictionary;

static inline NSString * imageURLKeyForState(UIControlState state) {
    return [NSString stringWithFormat:@"image_%lu", (unsigned long)state];
}

static inline NSString * backgroundImageURLKeyForState(UIControlState state) {
    return [NSString stringWithFormat:@"backgroundImage_%lu", (unsigned long)state];
}

@implementation UIButton (BMWebCache)

#pragma mark - Image

- (nullable NSURL *)bm_currentImageURL {
    NSURL *url = self.imageURLStorage[imageURLKeyForState(self.state)];

    if (!url) {
        url = self.imageURLStorage[imageURLKeyForState(UIControlStateNormal)];
    }

    return url;
}

- (nullable NSURL *)bm_imageURLForState:(UIControlState)state {
    return self.imageURLStorage[imageURLKeyForState(state)];
}

- (void)bm_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state {
    [self bm_setImageWithURL:url forState:state placeholderImage:nil options:0 completed:nil];
}

- (void)bm_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder {
    [self bm_setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:nil];
}

- (void)bm_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(BMSDWebImageOptions)options {
    [self bm_setImageWithURL:url forState:state placeholderImage:placeholder options:options completed:nil];
}

- (void)bm_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state completed:(nullable BMSDExternalCompletionBlock)completedBlock {
    [self bm_setImageWithURL:url forState:state placeholderImage:nil options:0 completed:completedBlock];
}

- (void)bm_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder completed:(nullable BMSDExternalCompletionBlock)completedBlock {
    [self bm_setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)bm_setImageWithURL:(nullable NSURL *)url
                  forState:(UIControlState)state
          placeholderImage:(nullable UIImage *)placeholder
                   options:(BMSDWebImageOptions)options
                 completed:(nullable BMSDExternalCompletionBlock)completedBlock {
    if (!url) {
        [self.imageURLStorage removeObjectForKey:imageURLKeyForState(state)];
        return;
    }
    
    self.imageURLStorage[imageURLKeyForState(state)] = url;
    
    __weak typeof(self)weakSelf = self;
    [self bm_internalSetImageWithURL:url
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

- (nullable NSURL *)bm_currentBackgroundImageURL {
    NSURL *url = self.imageURLStorage[backgroundImageURLKeyForState(self.state)];
    
    if (!url) {
        url = self.imageURLStorage[backgroundImageURLKeyForState(UIControlStateNormal)];
    }
    
    return url;
}

- (nullable NSURL *)bm_backgroundImageURLForState:(UIControlState)state {
    return self.imageURLStorage[backgroundImageURLKeyForState(state)];
}

- (void)bm_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state {
    [self bm_setBackgroundImageWithURL:url forState:state placeholderImage:nil options:0 completed:nil];
}

- (void)bm_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder {
    [self bm_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:nil];
}

- (void)bm_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(BMSDWebImageOptions)options {
    [self bm_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:options completed:nil];
}

- (void)bm_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state completed:(nullable BMSDExternalCompletionBlock)completedBlock {
    [self bm_setBackgroundImageWithURL:url forState:state placeholderImage:nil options:0 completed:completedBlock];
}

- (void)bm_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder completed:(nullable BMSDExternalCompletionBlock)completedBlock {
    [self bm_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)bm_setBackgroundImageWithURL:(nullable NSURL *)url
                            forState:(UIControlState)state
                    placeholderImage:(nullable UIImage *)placeholder
                             options:(BMSDWebImageOptions)options
                           completed:(nullable BMSDExternalCompletionBlock)completedBlock {
    if (!url) {
        [self.imageURLStorage removeObjectForKey:backgroundImageURLKeyForState(state)];
        return;
    }
    
    self.imageURLStorage[backgroundImageURLKeyForState(state)] = url;
    
    __weak typeof(self)weakSelf = self;
    [self bm_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                        operationKey:[NSString stringWithFormat:@"UIButtonBackgroundImageOperation%@", @(state)]
                       setImageBlock:^(UIImage *image, NSData *imageData) {
                           [weakSelf setBackgroundImage:image forState:state];
                       }
                            progress:nil
                           completed:completedBlock];
}

- (void)bm_setImageLoadOperation:(id<BMSDWebImageOperation>)operation forState:(UIControlState)state {
    [self bm_setImageLoadOperation:operation forKey:[NSString stringWithFormat:@"UIButtonImageOperation%@", @(state)]];
}

- (void)bm_cancelImageLoadForState:(UIControlState)state {
    [self bm_cancelImageLoadOperationWithKey:[NSString stringWithFormat:@"UIButtonImageOperation%@", @(state)]];
}

- (void)bm_setBackgroundImageLoadOperation:(id<BMSDWebImageOperation>)operation forState:(UIControlState)state {
    [self bm_setImageLoadOperation:operation forKey:[NSString stringWithFormat:@"UIButtonBackgroundImageOperation%@", @(state)]];
}

- (void)bm_cancelBackgroundImageLoadForState:(UIControlState)state {
    [self bm_cancelImageLoadOperationWithKey:[NSString stringWithFormat:@"UIButtonBackgroundImageOperation%@", @(state)]];
}

- (SDStateImageURLDictionary *)imageURLStorage {
    SDStateImageURLDictionary *storage = objc_getAssociatedObject(self, &imageURLStorageKey);
    if (!storage) {
        storage = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &imageURLStorageKey, storage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return storage;
}

@end

#endif
