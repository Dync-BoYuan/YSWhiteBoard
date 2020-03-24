/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "VYSDWebImageCompat.h"

#if SD_UIKIT || SD_MAC

#import "VYSDWebImageManager.h"

typedef void(^VYSDSetImageBlock)(UIImage * _Nullable image, NSData * _Nullable imageData);

@interface UIView (VYWebCache)

/**
 * Get the current image URL.
 *
 * Note that because of the limitations of categories this property can get out of sync
 * if you use setImage: directly.
 */
- (nullable NSURL *)VYsd_imageURL;

/**
 * Set the imageView `image` with an `url` and optionally a placeholder image.
 *
 * The download is asynchronous and cached.
 *
 * @param url            The url for the image.
 * @param placeholder    The image to be set initially, until the image request finishes.
 * @param options        The options to use when downloading the image. @see SDWebImageOptions for the possible values.
 * @param operationKey   A string to be used as the operation key. If nil, will use the class name
 * @param setImageBlock  Block used for custom set image code
 * @param progressBlock  A block called while image is downloading
 *                       @note the progress block is executed on a background queue
 * @param completedBlock A block called when operation has been completed. This block has no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrieved from the local cache or from the network.
 *                       The fourth parameter is the original image url.
 */
- (void)VYsd_internalSetImageWithURL:(nullable NSURL *)url
                  placeholderImage:(nullable UIImage *)placeholder
                           options:(VYSDWebImageOptions)options
                      operationKey:(nullable NSString *)operationKey
                     setImageBlock:(nullable VYSDSetImageBlock)setImageBlock
                          progress:(nullable VYSDWebImageDownloaderProgressBlock)progressBlock
                         completed:(nullable VYSDExternalCompletionBlock)completedBlock;

/**
 * Cancel the current download
 */
- (void)VYsd_cancelCurrentImageLoad;

#if SD_UIKIT

#pragma mark - Activity indicator

/**
 *  Show activity UIActivityIndicatorView
 */
- (void)VYsd_setShowActivityIndicatorView:(BOOL)show;

/**
 *  set desired UIActivityIndicatorViewStyle
 *
 *  @param style The style of the UIActivityIndicatorView
 */
- (void)VYsd_setIndicatorStyle:(UIActivityIndicatorViewStyle)style;

- (BOOL)VYsd_showActivityIndicatorView;
- (void)VYsd_addActivityIndicator;
- (void)VYsd_removeActivityIndicator;

#endif

@end

#endif
