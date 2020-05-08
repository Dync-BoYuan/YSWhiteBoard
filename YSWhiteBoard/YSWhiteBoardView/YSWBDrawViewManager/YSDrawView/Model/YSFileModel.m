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
        else if ([value isKindOfClass:[NSNumber class]]) {
            [super setValue:[NSString stringWithFormat:@"%@",(NSNumber *)value] forKey:key];
        }
        else if ([value isEqual:[NSNull null]]) {
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

+ (NSDictionary *)fileDataDocDic:(YSFileModel *)aDefaultDocment sourceInstanceId:(NSString *)sourceInstanceId
{
    return [self fileDataDocDic:aDefaultDocment currentPage:0 sourceInstanceId:sourceInstanceId];
}

+ (NSDictionary *)fileDataDocDic:(YSFileModel *)aDefaultDocment currentPage:(NSUInteger)currentPage sourceInstanceId:(NSString *)sourceInstanceId
{
    if (![sourceInstanceId bm_isNotEmpty])
    {
        sourceInstanceId = YSDefaultWhiteBoardId;
    }
    if (!aDefaultDocment)
    {
        // 白板
        NSDictionary *tDataDic = @{
                                   @"isGeneralFile":@(true),
                                   @"isDynamicPPT":@(false),
                                   @"isH5Document":@(false),
                                   @"action":@"",
                                   @"fileid":@(0),
                                   @"sourceInstanceId":YSDefaultWhiteBoardId,
                                   @"mediaType":@"",
                                   @"isMedia":@(false),
                                   @"filedata":@{
                                           @"fileid"   :@(0),
                                           @"filename" :@"whiteboard",//MTLocalized(@"Title.whiteBoard"),
                                           //                                           @"filetype" :MTLocalized(@"Title.whiteBoard"),
                                           @"filetype" :@"whiteboard",
                                           @"fileprop" : @(0),
                                           @"currpage" :@(1),
                                           @"pagenum"  :@(1),
                                           @"pptslide" :@(1),
                                           @"pptstep"  :@(0),
                                           @"steptotal":@(0),
                                           @"isContentDocument":@(0),
                                           @"swfpath"  :@""
                                           }
                                   };
        return tDataDic;
    }
    
    // isH5Document isH5Docment
    // 0:表示普通文档　１－２动态ppt(1: 第一版动态ppt 2: 新版动态ppt ）  3:h5文档
    NSString *prop = nil;
    if (!aDefaultDocment.fileprop || [aDefaultDocment isEqual:[NSNull null]])
    {
        prop = @"0";
    }
    else
    {
        prop = [NSString stringWithFormat:@"%@", aDefaultDocment.fileprop];
    }
//    NSString *tFileProp = [NSString stringWithFormat:@"%@",[aDefaultDocment.fileprop isEqual:[NSNull null]] ? @"0" : aDefaultDocment.fileprop];

    BOOL isGeneralFile = [prop isEqualToString:@"0"]? true : false;
    BOOL isDynamicPPT  = ([prop isEqualToString:@"1"] ||[prop isEqualToString:@"2"] )? true : false ;
    BOOL isH5Document  = [prop isEqualToString:@"3"]? true : false ;
    NSString *action   =  isH5Document ? sYSSignalActionShow : @"";
    NSString *downloadpath = aDefaultDocment.downloadpath?aDefaultDocment.downloadpath:@"";
    
    NSString *mediaType     =  @"";
    NSInteger fileCurrpage = [aDefaultDocment.currpage integerValue];
    if (fileCurrpage <= 0)
    {
        fileCurrpage = 1;
    }
    NSInteger filePagenum = [aDefaultDocment.pagenum integerValue];
    NSInteger filePptslide = [aDefaultDocment.pptslide integerValue];
    if (filePptslide <= 0)
    {
        filePptslide = 1;
    }
    NSInteger filePptstep = [aDefaultDocment.pptstep integerValue];
    NSInteger fileSteptotal = [aDefaultDocment.steptotal integerValue];
    
    NSMutableDictionary *filedata = [NSMutableDictionary dictionaryWithDictionary:@{
        @"fileid":aDefaultDocment.fileid?aDefaultDocment.fileid:@(0),
        @"filename":aDefaultDocment.filename?aDefaultDocment.filename:@"",
        @"filetype": aDefaultDocment.filetype?aDefaultDocment.filetype:@"",
        @"fileprop" : aDefaultDocment.fileprop?aDefaultDocment.fileprop:@(0),
        @"currpage": @(fileCurrpage),
        @"pagenum"  : @(filePagenum),
        @"pptslide": @(filePptslide),
        @"pptstep": @(filePptstep),
        @"steptotal": @(fileSteptotal),
        @"isContentDocument":aDefaultDocment.isContentDocument?aDefaultDocment.isContentDocument:@(0),
        @"swfpath"  :  aDefaultDocment.swfpath?aDefaultDocment.swfpath:@""
    }];
    if (currentPage > 0)
    {
        [filedata setObject:@(currentPage) forKey:@"currpage"];
        [filedata setObject:@(currentPage) forKey:@"pptslide"];
    }
    
//    NSString *type = nil;
//    if (isH5Document)
//    {
//        type = @"/index.html";
//    }
//    else if (isDynamicPPT)
//    {
//        type = @"/newppt.html";
//    }
//    
//    if(isPredownload && [[NSFileManager defaultManager] fileExistsAtPath:[[NSTemporaryDirectory() stringByAppendingPathComponent:@"YSFile"] stringByAppendingPathComponent:aDefaultDocment.fileid]])
//    {
//
//        [filedata setObject:[NSURL fileURLWithPath:[[[NSTemporaryDirectory() stringByAppendingPathComponent:@"YSFile"] stringByAppendingPathComponent:aDefaultDocment.fileid] stringByAppendingPathComponent:type]].absoluteString forKey:@"baseurl"];
//    }
    
    NSDictionary *tDataDic = @{
                               @"isGeneralFile":@(isGeneralFile),
                               @"isDynamicPPT":@(isDynamicPPT),
                               @"isH5Document":@(isH5Document),
                               @"action":action,
                               @"downloadpath":downloadpath,
                               @"fileid":aDefaultDocment.fileid?aDefaultDocment.fileid:@(0),
                               @"sourceInstanceId":sourceInstanceId,
                               @"mediaType":mediaType,
                               @"isMedia":@(false),
                               @"filedata":filedata
                               };
    return tDataDic;
}

@end
