//
//  YSFileModel.h
//  YSWhiteBoard
//
//  Created by MAC-MiNi on 2018/4/18.
//  Copyright © 2018年 MAC-MiNi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YSFileModel : NSObject

@property (nonatomic, strong) NSString *active;
@property (nonatomic, strong) NSString *animation;

@property (nonatomic, strong) NSString *companyid;
@property (nonatomic, strong) NSString *downloadpath;
@property (nonatomic, strong) NSString *fileid;

@property (nonatomic, strong) NSString *sourceInstanceId;

@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSString *filepath;
@property (nonatomic, strong) NSString *fileserverid;
@property (nonatomic, strong) NSString *filetype;
@property (nonatomic, strong) NSString *fileurl;
@property (nonatomic, assign) NSInteger isconvert;//NSInteger
@property (nonatomic, strong) NSString *newfilename;
@property (nonatomic, strong) NSString *size;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *swfpath;
@property (nonatomic, strong) NSString *type;// 1 默认文档
@property (nonatomic, strong) NSString *uploadtime;
@property (nonatomic, strong) NSString *uploaduserid;
@property (nonatomic, strong) NSString *uploadusername;
@property (nonatomic, strong) NSString *pdfpath;
@property (nonatomic, strong) NSString *dynamicppt;//1 是原动态ppt 2.新的

@property (nonatomic, assign) NSUInteger pagenum;
@property (nonatomic, assign) NSUInteger currpage;//NSInteger
@property (nonatomic, assign) NSUInteger pptslide;//1 当前页面
@property (nonatomic, assign) NSUInteger pptstep;//0 贞
@property (nonatomic, assign) NSUInteger steptotal;//总的

// pdf
@property (nonatomic, copy) NSString *cospdfpath;

//0:表示普通文档　１－２动态ppt(1: 第一版动态ppt 2: 新版动态ppt ）  3:h5文档
@property (nonatomic, assign) NSUInteger fileprop;

@property (nonatomic, strong) NSString *action;//show
@property (nonatomic, strong) NSString *isShow;//是否查看
@property (nonatomic, strong) NSString* duration;//BOOl

@property (nonatomic, strong) NSString *preloadingzip;


@property (nonatomic, assign) BOOL isDynamicPPT;
@property (nonatomic, assign) BOOL isGeneralFile;
@property (nonatomic, assign) BOOL isH5Document;
@property (nonatomic, assign) BOOL isMedia;
@property (nonatomic, assign) BOOL isContentDocument;
/**
 区分文件类型 0：课堂  1：系统
 */
@property (nonatomic, assign) NSUInteger filecategory;

+ (instancetype)fileModelWithServerDic:(NSDictionary *)dic;
- (void)updateWithServerDic:(NSDictionary *)dic;

- (void)dynamicpptUpdate;

+ (NSDictionary *)fileDataDocDic:(YSFileModel *)aDefaultDocment sourceInstanceId:(NSString *)sourceInstanceId;
+ (NSDictionary *)fileDataDocDic:(YSFileModel *)aDefaultDocment currentPage:(NSUInteger)currentPage sourceInstanceId:(NSString *)sourceInstanceId;

@end
