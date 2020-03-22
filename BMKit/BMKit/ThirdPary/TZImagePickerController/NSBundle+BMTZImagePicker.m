//
//  NSBundle+TZImagePicker.m
//  TZImagePickerController
//
//  Created by 谭真 on 16/08/18.
//  Copyright © 2016年 谭真. All rights reserved.
//

#import "NSBundle+BMTZImagePicker.h"
#import "BMTZImagePickerController.h"

@implementation NSBundle (BMTZImagePicker)

+ (NSBundle *)bmtz_imagePickerBundle {
    NSBundle *bundle = [NSBundle bundleForClass:[BMTZImagePickerController class]];
    NSURL *url = [bundle URLForResource:@"BMTZImagePickerController" withExtension:@"bundle"];
    bundle = [NSBundle bundleWithURL:url];
    return bundle;
}

+ (NSString *)bmtz_localizedStringForKey:(NSString *)key {
    return [self bmtz_localizedStringForKey:key value:@""];
}

+ (NSString *)bmtz_localizedStringForKey:(NSString *)key value:(NSString *)value {
    NSBundle *bundle = [BMTZImagePickerConfig sharedInstance].languageBundle;
    NSString *value1 = [bundle localizedStringForKey:key value:value table:nil];
    return value1;
}

@end
