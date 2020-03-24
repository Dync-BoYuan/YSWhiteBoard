//
//  DrawLine.h
//  WhiteBoard
//
//  Created by macmini on 14/11/7.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import "DrawBase.h"
#define ARROWLENGTH 10.0
@interface DrawLine : DrawBase
+ (DrawLine *)deserializeData:(NSDictionary *)data;
- (NSMutableDictionary *)serializedData;
@end
