//
//  YSFileModel.m
//  YSWhiteBoard
//
//  Created by MAC-MiNi on 2018/4/18.
//  Copyright © 2018年 MAC-MiNi. All rights reserved.
//

#import "YSFileModel.h"

@implementation YSFileModel

+ (instancetype)fileModelWithServerDic:(NSDictionary *)dic
{
    if (![dic bm_isNotEmptyDictionary])
    {
        return nil;
    }
    
    NSString *fileId = [dic bm_stringTrimForKey:@"fileid"];
    if (![fileId bm_isNotEmpty])
    {
        return nil;
    }
    
    YSFileModel *fileModel = [[YSFileModel alloc] init];
    [fileModel updateWithServerDic:dic];
    
    if ([fileModel.fileid bm_isNotEmpty])
    {
        return fileModel;
    }
    else
    {
        return nil;
    }
}

- (void)updateWithServerDic:(NSDictionary *)dic
{
    if (![dic bm_isNotEmptyDictionary])
    {
        return;
    }

    if ([dic bm_containsObjectForKey:@"fileid"])
    {
        NSString *fileId = [dic bm_stringTrimForKey:@"fileid"];
        if (![fileId bm_isNotEmpty])
        {
            return;
        }
        
        self.fileid = fileId;
    }

    if ([dic bm_containsObjectForKey:@"active"])
    {
        self.active = [dic bm_stringTrimForKey:@"active"];
    }
    if ([dic bm_containsObjectForKey:@"animation"])
    {
        self.animation = [dic bm_stringTrimForKey:@"animation"];
    }

    if ([dic bm_containsObjectForKey:@"companyid"])
    {
        self.companyid = [dic bm_stringTrimForKey:@"companyid"];
    }
    if ([dic bm_containsObjectForKey:@"downloadpath"])
    {
        self.downloadpath = [dic bm_stringTrimForKey:@"downloadpath"];
    }

    if ([dic bm_containsObjectForKey:@"sourceInstanceId"])
    {
        self.sourceInstanceId = [dic bm_stringTrimForKey:@"sourceInstanceId"];
    }

    if ([dic bm_containsObjectForKey:@"filename"])
    {
        self.filename = [dic bm_stringTrimForKey:@"filename"];
    }
    if ([dic bm_containsObjectForKey:@"filepath"])
    {
        self.filepath = [dic bm_stringTrimForKey:@"filepath"];
    }
    if ([dic bm_containsObjectForKey:@"fileserverid"])
    {
        self.fileserverid = [dic bm_stringTrimForKey:@"fileserverid"];
    }
    if ([dic bm_containsObjectForKey:@"filetype"])
    {
        self.filetype = [dic bm_stringTrimForKey:@"filetype"];
    }
    if ([dic bm_containsObjectForKey:@"fileurl"])
    {
        self.fileurl = [dic bm_stringTrimForKey:@"fileurl"];
    }
    if ([dic bm_containsObjectForKey:@"isconvert"])
    {
        self.isconvert = [dic bm_intForKey:@"isconvert"];
    }
    
    if ([dic bm_containsObjectForKey:@"newfilename"])
    {
        self.newfilename = [dic bm_stringTrimForKey:@"newfilename"];
    }
    if ([dic bm_containsObjectForKey:@"size"])
    {
        self.size = [dic bm_stringTrimForKey:@"size"];
    }
    if ([dic bm_containsObjectForKey:@"status"])
    {
        self.status = [dic bm_stringTrimForKey:@"status"];
    }

    if ([dic bm_containsObjectForKey:@"swfpath"])
    {
        self.swfpath = [dic bm_stringTrimForKey:@"swfpath"];
    }

    if ([dic bm_containsObjectForKey:@"type"])
    {
        self.type = [dic bm_stringTrimForKey:@"type"];
    }
    if ([dic bm_containsObjectForKey:@"uploadtime"])
    {
        self.uploadtime = [dic bm_stringTrimForKey:@"uploadtime"];
    }
    if ([dic bm_containsObjectForKey:@"uploaduserid"])
    {
        self.uploaduserid = [dic bm_stringTrimForKey:@"uploaduserid"];
    }
    if ([dic bm_containsObjectForKey:@"uploadusername"])
    {
        self.uploadusername = [dic bm_stringTrimForKey:@"uploadusername"];
    }
    if ([dic bm_containsObjectForKey:@"pdfpath"])
    {
        self.pdfpath = [dic bm_stringTrimForKey:@"pdfpath"];
    }
    if ([dic bm_containsObjectForKey:@"dynamicppt"])
    {
        self.dynamicppt = [dic bm_stringTrimForKey:@"dynamicppt"];
    }

    if ([dic bm_containsObjectForKey:@"pagenum"])
    {
        self.pagenum = [dic bm_uintForKey:@"pagenum"];
    }
    if ([dic bm_containsObjectForKey:@"currpage"])
    {
        self.currpage = [dic bm_uintForKey:@"currpage"];
    }
    if ([dic bm_containsObjectForKey:@"pptslide"])
    {
        self.pptslide = [dic bm_uintForKey:@"pptslide"];
    }
    if ([dic bm_containsObjectForKey:@"pptstep"])
    {
        self.pptstep = [dic bm_uintForKey:@"pptstep"];
    }
    if ([dic bm_containsObjectForKey:@"steptotal"])
    {
        self.steptotal = [dic bm_uintForKey:@"steptotal"];
    }

    if ([dic bm_containsObjectForKey:@"cospdfpath"])
    {
        self.cospdfpath = [dic bm_stringTrimForKey:@"cospdfpath"];
    }
    
    //0:表示普通文档　１－２动态ppt(1: 第一版动态ppt 2: 新版动态ppt ）  3:h5文档
    if ([dic bm_containsObjectForKey:@"fileprop"])
    {
        self.fileprop = [dic bm_uintForKey:@"fileprop"];
    }

    if ([dic bm_containsObjectForKey:@"action"])
    {
        self.action = [dic bm_stringTrimForKey:@"action"];
    }
    if ([dic bm_containsObjectForKey:@"isShow"])
    {
        self.isShow = [dic bm_stringTrimForKey:@"isShow"];
    }
    if ([dic bm_containsObjectForKey:@"duration"])
    {
        self.duration = [dic bm_stringTrimForKey:@"duration"];
    }

    if ([dic bm_containsObjectForKey:@"preloadingzip"])
    {
        self.preloadingzip = [dic bm_stringTrimForKey:@"preloadingzip"];
    }

    if ([dic bm_containsObjectForKey:@"isDynamicPPT"])
    {
        self.isDynamicPPT = [dic bm_boolForKey:@"isDynamicPPT"];
    }
    if ([dic bm_containsObjectForKey:@"isGeneralFile"])
    {
        self.isGeneralFile = [dic bm_boolForKey:@"isGeneralFile"];
    }
    if ([dic bm_containsObjectForKey:@"isH5Document"])
    {
        self.isH5Document = [dic bm_boolForKey:@"isH5Document"];
    }
    if ([dic bm_containsObjectForKey:@"isMedia"])
    {
        self.isMedia = [dic bm_boolForKey:@"isMedia"];
    }
    if ([dic bm_containsObjectForKey:@"isContentDocument"])
    {
        self.isContentDocument = [dic bm_boolForKey:@"isContentDocument"];
    }
    /**
     区分文件类型 0：课堂  1：系统
     */
    if ([dic bm_containsObjectForKey:@"filecategory"])
    {
        self.filecategory = [dic bm_uintForKey:@"filecategory"];
    }
}


//- (void)setValue:(id)value forUndefinedKey:(NSString *)key
//{
//    
//}
//
//- (void)setValue:(id)value forKey:(NSString *)key
//{
//    if ([key isEqualToString:@"fileid"]) {
//        if ([value isKindOfClass:[NSString class]]) {
//            [super setValue:(NSString *)value forKey:key];
//        }
//        else if ([value isKindOfClass:[NSNumber class]]) {
//            [super setValue:[NSString stringWithFormat:@"%@",(NSNumber *)value] forKey:key];
//        }
//        else if ([value isEqual:[NSNull null]]) {
//            [super setValue:@"0" forKey:key];
//        }
//    } else {
//        [super setValue:value forKey:key];
//    }
//}

- (void)dynamicpptUpdate{
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
    return [NSString stringWithFormat:@"%@---%@", self.fileid, @(self.filecategory)];
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
    BOOL isGeneralFile = aDefaultDocment.fileprop == 0 ? YES : NO;
    BOOL isDynamicPPT  = (aDefaultDocment.fileprop == 1 || aDefaultDocment.fileprop == 2) ? YES : NO;
    BOOL isH5Document  = aDefaultDocment.fileprop == 3 ? YES : NO;
 
    NSString *action   =  isH5Document ? sYSSignalActionShow : @"";
    NSString *downloadpath = aDefaultDocment.downloadpath?aDefaultDocment.downloadpath:@"";
    
    NSString *mediaType     =  @"";
    NSInteger fileCurrpage = aDefaultDocment.currpage;
    if (fileCurrpage <= 0)
    {
        fileCurrpage = 1;
    }
    NSInteger filePagenum = aDefaultDocment.pagenum ;
    NSInteger filePptslide = aDefaultDocment.pptslide;
    if (filePptslide <= 0)
    {
        filePptslide = 1;
    }
    NSInteger filePptstep = aDefaultDocment.pptstep;
    NSInteger fileSteptotal = aDefaultDocment.steptotal;
    
    NSMutableDictionary *filedata = [NSMutableDictionary dictionaryWithDictionary:@{
        @"fileid":aDefaultDocment.fileid?aDefaultDocment.fileid:@(0),
        @"filename":aDefaultDocment.filename?aDefaultDocment.filename:@"",
        @"filetype": aDefaultDocment.filetype?aDefaultDocment.filetype:@"",
        @"fileprop" : @(aDefaultDocment.fileprop),
        @"currpage": @(fileCurrpage),
        @"pagenum"  : @(filePagenum),
        @"pptslide": @(filePptslide),
        @"pptstep": @(filePptstep),
        @"steptotal": @(fileSteptotal),
        @"isContentDocument":@(aDefaultDocment.isContentDocument),
        @"swfpath"  :  aDefaultDocment.swfpath?aDefaultDocment.swfpath:@""
    }];
    
    if (currentPage > 0)
    {
        [filedata bm_setInteger:currentPage forKey:@"currpage"];
        [filedata bm_setInteger:currentPage forKey:@"pptslide"];
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
