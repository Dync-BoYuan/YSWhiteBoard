//
//  NSBundle+TZImagePicker.h
//  TZImagePickerController
//
//  Created by 谭真 on 16/08/18.
//  Copyright © 2016年 谭真. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSBundle (BMTZImagePicker)

+ (NSBundle *)bmtz_imagePickerBundle;

+ (NSString *)bmtz_localizedStringForKey:(NSString *)key value:(NSString *)value;
+ (NSString *)bmtz_localizedStringForKey:(NSString *)key;

@end

