//
//  DrawText.h
//  WhiteBoard
//
//  Created by macmini on 14/11/12.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import "DrawBase.h"

@interface DrawText : DrawBase
@property(nonatomic,strong) NSString* text;
@property(nonatomic,strong) NSString* fontString;
@property(nonatomic) CGRect textFrame;
@property (nonatomic, strong) NSString *pointString;

+ (DrawText *)deserializeData:(NSDictionary *)data;
- (NSMutableDictionary *)serializedData;
@end
