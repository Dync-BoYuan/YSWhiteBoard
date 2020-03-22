//
//  NSBundle+BMResource.h
//  Pods
//
//  Created by DennisDeng on 2018/3/29.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*本地化字符串 （默认 Localizable.string ）*/
// NSLocalizedString(key, comment)
/*使用指定的 string 文件的本地化字符串*/
// NSLocalizedStringFromTable(key, tbl, comment)
/*使用某个包里的的本地化字符串*/
// NSLocalizedStringFromTableInBundle(key, tbl, bundle, comment)
/*用默认值得本地化字符串*/
// NSLocalizedStringWithDefaultValue(key, tbl, bundle, val, comment)

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (BMResource)

#pragma mark image

// imageName不带扩展名默认为png
// 其他会自动补齐相应扩展名

/// 从bundle文件中获取图片
+ (nullable UIImage *)bm_bundleImageFromBundleNamed:(NSString *)bundleName imageName:(NSString *)imageName;
/// 从bundle文件中的xcassets中获取图片
+ (nullable UIImage *)bm_bundleAssetsImageFromeBundleName:(NSString *)bundleName assetsName:(NSString *)assetsName imageName:(NSString *)imageName;

/// 从app的resourcePath中获取图片
- (nullable UIImage *)bm_imageWithImageName:(NSString *)imageName;
/// 从xcassets中获取图片
- (nullable UIImage *)bm_imageWithAssetsName:(NSString *)assetsName imageName:(NSString *)imageName;

#pragma mark localizedString

+ (NSBundle *)bm_mainLocalizedBundle;
+ (NSBundle *)bm_mainLocalizedBundleWithLanguage:(nullable NSString *)language;

+ (nullable NSBundle *)bm_localizedBundleWithBundleName:(NSString *)bundleName;
+ (nullable NSBundle *)bm_localizedBundleWithBundleName:(NSString *)bundleName language:(nullable NSString *)language;

+ (NSBundle *)bm_localizedBundleWithBundle:(NSBundle *)bundle;
+ (nullable NSBundle *)bm_localizedBundleWithBundle:(NSBundle *)bundle language:(nullable NSString *)language;

/// 返回某个包里的的本地化字符串 默认table: Localizable 未找到返回value默认值
+ (nullable NSString *)bm_localizedStringFromBundleNamed:(NSString *)bundleName forKey:(NSString *)key value:(nullable NSString *)value;
+ (nullable NSString *)bm_localizedStringFromBundleNamed:(NSString *)bundleName forKey:(NSString *)key value:(nullable NSString *)value table:(nullable NSString *)table;

- (nullable NSString *)bm_localizedLanguageStringForKey:(NSString *)key value:(nullable NSString *)value;
- (nullable NSString *)bm_localizedLanguageStringForKey:(NSString *)key value:(nullable NSString *)value table:(nullable NSString *)table;

@end

NS_ASSUME_NONNULL_END

