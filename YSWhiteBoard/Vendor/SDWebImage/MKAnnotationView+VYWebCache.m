/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "MKAnnotationView+VYWebCache.h"

#if SD_UIKIT || SD_MAC

#import "objc/runtime.h"
#import "UIView+VYWebCacheOperation.h"
#import "UIView+VYWebCache.h"

@implementation MKAnnotationView (VYWebCache)

- (void)VYsd_setImageWithURL:(nullable NSURL *)url {
    [self VYsd_setImageWithURL:url placeholderImage:nil options:0 completed:nil];
}

- (void)VYsd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder {
    [self VYsd_setImageWithURL:url placeholderImage:placeholder options:0 completed:nil];
}

- (void)VYsd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(VYSDWebImageOptions)options {
    [self VYsd_setImageWithURL:url placeholderImage:placeholder options:options completed:nil];
}

- (void)VYsd_setImageWithURL:(nullable NSURL *)url completed:(nullable VYSDExternalCompletionBlock)completedBlock {
    [self VYsd_setImageWithURL:url placeholderImage:nil options:0 completed:completedBlock];
}

- (void)VYsd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder completed:(nullable VYSDExternalCompletionBlock)completedBlock {
    [self VYsd_setImageWithURL:url placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)VYsd_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(VYSDWebImageOptions)options
                 completed:(nullable VYSDExternalCompletionBlock)completedBlock {
    __weak typeof(self)weakSelf = self;
    [self VYsd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                        operationKey:nil
                       setImageBlock:^(UIImage *image, NSData *imageData) {
                           weakSelf.image = image;
                       }
                            progress:nil
                           completed:completedBlock];
}

@end

#endif
