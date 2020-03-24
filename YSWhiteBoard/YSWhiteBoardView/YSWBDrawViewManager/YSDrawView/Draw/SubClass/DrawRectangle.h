//
//  DrawRectangle.h
//  WhiteBoard
//
//  Created by macmini on 14/11/10.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import "DrawBase.h"

@interface DrawRectangle : DrawBase
+ (DrawRectangle *)deserializeData:(NSDictionary *)data;
- (NSMutableDictionary *)serializedData;
@end
