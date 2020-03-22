/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImageView+BMWebCache.h"

#if SD_UIKIT || SD_MAC

#import "objc/runtime.h"
#import "UIView+BMWebCacheOperation.h"
#import "UIView+BMWebCache.h"

@implementation UIImageView (WebCache)

- (void)bm_setImageWithURL:(nullable NSURL *)url {
    [self bm_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)bm_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder {
    [self bm_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)bm_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(BMSDWebImageOptions)options {
    [self bm_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)bm_setImageWithURL:(nullable NSURL *)url completed:(nullable BMSDExternalCompletionBlock)completedBlock {
    [self bm_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)bm_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder completed:(nullable BMSDExternalCompletionBlock)completedBlock {
    [self bm_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

- (void)bm_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(BMSDWebImageOptions)options completed:(nullable BMSDExternalCompletionBlock)completedBlock {
    [self bm_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)bm_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(BMSDWebImageOptions)options
                  progress:(nullable BMSDWebImageDownloaderProgressBlock)progressBlock
                 completed:(nullable BMSDExternalCompletionBlock)completedBlock {
    [self bm_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                        operationKey:nil
                       setImageBlock:nil
                            progress:progressBlock
                           completed:completedBlock];
}

- (void)bm_setImageWithPreviousCachedImageWithURL:(nullable NSURL *)url
                                 placeholderImage:(nullable UIImage *)placeholder
                                          options:(BMSDWebImageOptions)options
                                         progress:(nullable BMSDWebImageDownloaderProgressBlock)progressBlock
                                        completed:(nullable BMSDExternalCompletionBlock)completedBlock {
    NSString *key = [[BMSDWebImageManager sharedManager] cacheKeyForURL:url];
    UIImage *lastPreviousCachedImage = [[BMSDImageCache sharedImageCache] imageFromCacheForKey:key];
    
    [self bm_setImageWithURL:url placeholderImage:lastPreviousCachedImage ?: placeholder options:options progress:progressBlock completed:completedBlock];    
}

#if SD_UIKIT

#pragma mark - Animation of multiple images

- (void)bm_setAnimationImagesWithURLs:(nonnull NSArray<NSURL *> *)arrayOfURLs {
    [self bm_cancelCurrentAnimationImagesLoad];
    __weak __typeof(self)wself = self;

    NSMutableArray<id<BMSDWebImageOperation>> *operationsArray = [[NSMutableArray alloc] init];

    [arrayOfURLs enumerateObjectsUsingBlock:^(NSURL *logoImageURL, NSUInteger idx, BOOL * _Nonnull stop) {
        id <BMSDWebImageOperation> operation = [BMSDWebImageManager.sharedManager loadImageWithURL:logoImageURL options:0 progress:nil completed:^(UIImage *image, NSData *data, NSError *error, BMSDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (!wself) return;
            dispatch_main_async_safe(^{
                __strong UIImageView *sself = wself;
                [sself stopAnimating];
                if (sself && image) {
                    NSMutableArray<UIImage *> *currentImages = [[sself animationImages] mutableCopy];
                    if (!currentImages) {
                        currentImages = [[NSMutableArray alloc] init];
                    }
                    
                    // We know what index objects should be at when they are returned so
                    // we will put the object at the index, filling any empty indexes
                    // with the image that was returned too "early". These images will
                    // be overwritten. (does not require additional sorting datastructure)
                    while ([currentImages count] < idx) {
                        [currentImages addObject:image];
                    }
                    
                    currentImages[idx] = image;

                    sself.animationImages = currentImages;
                    [sself setNeedsLayout];
                }
                [sself startAnimating];
            });
        }];
        [operationsArray addObject:operation];
    }];

    [self bm_setImageLoadOperation:[operationsArray copy] forKey:@"UIImageViewAnimationImages"];
}

- (void)bm_cancelCurrentAnimationImagesLoad {
    [self bm_cancelImageLoadOperationWithKey:@"UIImageViewAnimationImages"];
}
#endif

@end

#endif
