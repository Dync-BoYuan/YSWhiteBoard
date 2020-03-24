/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImageView+VYHighlightedWebCache.h"

#if SD_UIKIT

#import "UIView+VYWebCacheOperation.h"
#import "UIView+VYWebCache.h"

@implementation UIImageView (VYHighlightedWebCache)

- (void)VYsd_setHighlightedImageWithURL:(nullable NSURL *)url {
    [self VYsd_setHighlightedImageWithURL:url options:0 progress:nil completed:nil];
}

- (void)VYsd_setHighlightedImageWithURL:(nullable NSURL *)url options:(VYSDWebImageOptions)options {
    [self VYsd_setHighlightedImageWithURL:url options:options progress:nil completed:nil];
}

- (void)VYsd_setHighlightedImageWithURL:(nullable NSURL *)url completed:(nullable VYSDExternalCompletionBlock)completedBlock {
    [self VYsd_setHighlightedImageWithURL:url options:0 progress:nil completed:completedBlock];
}

- (void)VYsd_setHighlightedImageWithURL:(nullable NSURL *)url options:(VYSDWebImageOptions)options completed:(nullable VYSDExternalCompletionBlock)completedBlock {
    [self VYsd_setHighlightedImageWithURL:url options:options progress:nil completed:completedBlock];
}

- (void)VYsd_setHighlightedImageWithURL:(nullable NSURL *)url
                              options:(VYSDWebImageOptions)options
                             progress:(nullable VYSDWebImageDownloaderProgressBlock)progressBlock
                            completed:(nullable VYSDExternalCompletionBlock)completedBlock {
    __weak typeof(self)weakSelf = self;
    [self VYsd_internalSetImageWithURL:url
                    placeholderImage:nil
                             options:options
                        operationKey:@"UIImageViewImageOperationHighlighted"
                       setImageBlock:^(UIImage *image, NSData *imageData) {
                           weakSelf.highlightedImage = image;
                       }
                            progress:progressBlock
                           completed:completedBlock];
}

@end

#endif
