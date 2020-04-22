//
//  YSFileModel.h
//  YSWhiteBoard
//
//  Created by MAC-MiNi on 2018/4/18.
//  Copyright © 2018年 MAC-MiNi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YSFileModel : NSObject

@property (nonatomic, copy) NSString *active;
@property (nonatomic, copy) NSString *animation;
@property (nonatomic, copy) NSString *companyid;
@property (nonatomic, copy) NSString *downloadpath;
@property (nonatomic, strong) NSString *fileid;

@property (nonatomic, strong) NSString *sourceInstanceId;

@property (nonatomic, copy) NSString *filename;
@property (nonatomic, copy) NSString *filepath;
@property (nonatomic, copy) NSString *fileserverid;
@property (nonatomic, copy) NSString *filetype;
@property (nonatomic, copy) NSString *fileurl;
@property (nonatomic, copy) NSString* isconvert;//NSInteger
@property (nonatomic, copy) NSString *newfilename;
@property (nonatomic, copy) NSString *pagenum;
@property (nonatomic, copy) NSString *pdfpath;
@property (nonatomic, copy) NSString *size;
@property (nonatomic, copy) NSString *status;
@property (nonatomic, copy) NSString *swfpath;
@property (nonatomic, copy) NSString *type;// 1 默认文档
@property (nonatomic, copy) NSString *uploadtime;
@property (nonatomic, copy) NSString *uploaduserid;
@property (nonatomic, copy) NSString *uploadusername;
@property (nonatomic, copy) NSString* currpage;//NSInteger
@property (nonatomic, copy) NSString* dynamicppt;//1 是原动态ppt 2.新的
@property (nonatomic, copy) NSString* pptslide;//1 当前页面
@property (nonatomic, copy) NSString* pptstep;//0 贞
@property (nonatomic, copy) NSString *action;//show
//0:表示普通文档　１－２动态ppt(1: 第一版动态ppt 2: 新版动态ppt ）  3:h5文档
@property (nonatomic, copy) NSNumber *fileprop;
@property (nonatomic, copy) NSString* steptotal;//总的
@property (nonatomic, copy) NSString *isShow;//是否查看
@property (nonatomic, copy) NSString* duration;//BOOl
@property (nonatomic, copy) NSString* isDynamicPPT;
@property (nonatomic, copy) NSString* isGeneralFile;
@property (nonatomic, copy) NSString* isH5Document;
@property (nonatomic, copy) NSString* isMedia;
@property (nonatomic, copy) NSString *preloadingzip;
@property (nonatomic, strong) NSNumber  *isContentDocument;
/**
 区分文件类型 0：课堂  1：系统
 */
@property (nonatomic, copy) NSString *filecategory;


/// 是否播放中
@property (nonatomic, assign) BOOL isPlaying;

- (void)dynamicpptUpdate;

+ (NSDictionary *)fileDataDocDic:(YSFileModel *)aDefaultDocment sourceInstanceId:(NSString *)sourceInstanceId;
+ (NSDictionary *)fileDataDocDic:(YSFileModel *)aDefaultDocment currentPage:(NSUInteger)currentPage sourceInstanceId:(NSString *)sourceInstanceId;

@end
