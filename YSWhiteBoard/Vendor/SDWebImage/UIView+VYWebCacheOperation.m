/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIView+VYWebCacheOperation.h"

#if SD_UIKIT || SD_MAC

#import "objc/runtime.h"

static char loadOperationKey;

typedef NSMutableDictionary<NSString *, id> VYSDOperationsDictionary;

@implementation UIView (VYWebCacheOperation)

- (VYSDOperationsDictionary *)VYoperationDictionary {
    VYSDOperationsDictionary *operations = objc_getAssociatedObject(self, &loadOperationKey);
    if (operations) {
        return operations;
    }
    operations = [NSMutableDictionary dictionary];
    objc_setAssociatedObject(self, &loadOperationKey, operations, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return operations;
}

- (void)VYsd_setImageLoadOperation:(nullable id)operation forKey:(nullable NSString *)key {
    if (key) {
        [self VYsd_cancelImageLoadOperationWithKey:key];
        if (operation) {
            VYSDOperationsDictionary *operationDictionary = [self VYoperationDictionary];
            operationDictionary[key] = operation;
        }
    }
}

- (void)VYsd_cancelImageLoadOperationWithKey:(nullable NSString *)key {
    // Cancel in progress downloader from queue
    VYSDOperationsDictionary *operationDictionary = [self VYoperationDictionary];
    id operations = operationDictionary[key];
    if (operations) {
        if ([operations isKindOfClass:[NSArray class]]) {
            for (id <VYSDWebImageOperation> operation in operations) {
                if (operation) {
                    [operation cancel];
                }
            }
        } else if ([operations conformsToProtocol:@protocol(VYSDWebImageOperation)]){
            [(id<VYSDWebImageOperation>) operations cancel];
        }
        [operationDictionary removeObjectForKey:key];
    }
}

- (void)VYsd_removeImageLoadOperationWithKey:(nullable NSString *)key {
    if (key) {
        VYSDOperationsDictionary *operationDictionary = [self VYoperationDictionary];
        [operationDictionary removeObjectForKey:key];
    }
}

@end

#endif
