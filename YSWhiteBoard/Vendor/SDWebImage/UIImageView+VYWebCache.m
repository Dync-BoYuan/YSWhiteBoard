/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImageView+VYWebCache.h"

#if SD_UIKIT || SD_MAC

#import "objc/runtime.h"
#import "UIView+VYWebCacheOperation.h"
#import "UIView+VYWebCache.h"

@implementation UIImageView (VYWebCache)

- (void)VYsd_setImageWithURL:(nullable NSURL *)url {
    [self VYsd_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)VYsd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder {
    [self VYsd_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)VYsd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(VYSDWebImageOptions)options {
    [self VYsd_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)VYsd_setImageWithURL:(nullable NSURL *)url completed:(nullable VYSDExternalCompletionBlock)completedBlock {
    [self VYsd_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)VYsd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder completed:(nullable VYSDExternalCompletionBlock)completedBlock {
    [self VYsd_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

- (void)VYsd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(VYSDWebImageOptions)options completed:(nullable VYSDExternalCompletionBlock)completedBlock {
    [self VYsd_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)VYsd_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(VYSDWebImageOptions)options
                  progress:(nullable VYSDWebImageDownloaderProgressBlock)progressBlock
                 completed:(nullable VYSDExternalCompletionBlock)completedBlock {
    [self VYsd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                        operationKey:nil
                       setImageBlock:nil
                            progress:progressBlock
                           completed:completedBlock];
}

- (void)VYsd_setImageWithPreviousCachedImageWithURL:(nullable NSURL *)url
                                 placeholderImage:(nullable UIImage *)placeholder
                                          options:(VYSDWebImageOptions)options
                                         progress:(nullable VYSDWebImageDownloaderProgressBlock)progressBlock
                                        completed:(nullable VYSDExternalCompletionBlock)completedBlock {
    NSString *key = [[VYSDWebImageManager sharedManager] cacheKeyForURL:url];
    UIImage *lastPreviousCachedImage = [[VYSDImageCache sharedImageCache] imageFromCacheForKey:key];
    
    [self VYsd_setImageWithURL:url placeholderImage:lastPreviousCachedImage ?: placeholder options:options progress:progressBlock completed:completedBlock];
}

#if SD_UIKIT

#pragma mark - Animation of multiple images

- (void)VYsd_setAnimationImagesWithURLs:(nonnull NSArray<NSURL *> *)arrayOfURLs {
    [self VYsd_cancelCurrentAnimationImagesLoad];
    __weak __typeof(self)wself = self;

    NSMutableArray<id<VYSDWebImageOperation>> *operationsArray = [[NSMutableArray alloc] init];

    for (NSURL *logoImageURL in arrayOfURLs) {
        id <VYSDWebImageOperation> operation = [VYSDWebImageManager.sharedManager loadImageWithURL:logoImageURL options:0 progress:nil completed:^(UIImage *image, NSData *data, NSError *error, VYSDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (!wself) return;
            dispatch_main_async_safe(^{
                __strong UIImageView *sself = wself;
                [sself stopAnimating];
                if (sself && image) {
                    NSMutableArray<UIImage *> *currentImages = [[sself animationImages] mutableCopy];
                    if (!currentImages) {
                        currentImages = [[NSMutableArray alloc] init];
                    }
                    [currentImages addObject:image];

                    sself.animationImages = currentImages;
                    [sself setNeedsLayout];
                }
                [sself startAnimating];
            });
        }];
        [operationsArray addObject:operation];
    }

    [self VYsd_setImageLoadOperation:[operationsArray copy] forKey:@"UIImageViewAnimationImages"];
}

- (void)VYsd_cancelCurrentAnimationImagesLoad {
    [self VYsd_cancelImageLoadOperationWithKey:@"UIImageViewAnimationImages"];
}
#endif

@end

#endif
