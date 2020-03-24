//
//  YSFileModel.m
//  YSWhiteBoard
//
//  Created by MAC-MiNi on 2018/4/18.
//  Copyright © 2018年 MAC-MiNi. All rights reserved.
//

#import "YSFileModel.h"

@implementation YSFileModel

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    if ([key isEqualToString:@"fileid"]) {
        if ([value isKindOfClass:[NSString class]]) {
            [super setValue:(NSString *)value forKey:key];
        }
        
        if ([value isKindOfClass:[NSNumber class]]) {
            [super setValue:[NSString stringWithFormat:@"%@",(NSNumber *)value] forKey:key];
        }
        
        if ([value isEqual:[NSNull null]]) {
            [super setValue:@"0" forKey:key];
        }
    } else {
        [super setValue:value forKey:key];
    }
}

-(void)dynamicpptUpdate{
        //如果是动态ppt
    if ([_dynamicppt intValue]) {
        if (_downloadpath) {
            _swfpath = [_downloadpath copy];
        }
        _action = sYSSignalActionShow;
    }else{
        _action = @"";
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@---%@",self.fileid, self.filecategory];
}
@end
