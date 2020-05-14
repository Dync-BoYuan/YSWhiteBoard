//
//  YSRoomConfiguration.h
//  YSLive
//
//  Created by jiang deng on 2019/10/15.
//  Copyright © 2019 FS. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#
#pragma mark - YSRoomConfiguration 房间设置的相关配置项
#

//配置项
@interface YSRoomConfiguration : NSObject

@property (nonatomic, strong) NSString *configurationString;

/**
 自动上课
 */
@property (nonatomic, assign) BOOL autoStartClassFlag;

/**
 课堂结束时自动退出房间
 */
@property (nonatomic, assign) BOOL autoQuitClassWhenClassOverFlag;

/**
 是否允许学生关闭音视频
 */
@property (nonatomic, assign) BOOL allowStudentCloseAV;

/**
 画笔权限
 */
@property (nonatomic, assign) BOOL canDrawFlag;

/**
 学生是否有翻页权限
 */
@property (nonatomic, assign) BOOL canPageTurningFlag;

/**
 是否隐藏上下课按钮
 */
@property (nonatomic, assign) BOOL hideClassBeginEndButton;

/**
 助教是否可以上台
 */
@property (nonatomic, assign) BOOL assistantCanPublish;

/**
 上课前是否发布视频
 */
@property (nonatomic, assign) BOOL beforeClassPubVideoFlag;

/**
 答题结束后自动展示答案
 */
@property (nonatomic, assign) BOOL autoShowAnswerAfterAnswer;

/**
 下课后不允许离开课堂
 */
@property (nonatomic, assign) BOOL forbidLeaveClassFlag;

/**
 自动开启音视频
 */
@property (nonatomic, assign) BOOL autoOpenAudioAndVideoFlag;

/**
 视频标注
 */
@property (nonatomic, assign) BOOL videoWhiteboardFlag;

/**
 课件备注
 */
@property (nonatomic, assign) BOOL coursewareRemarkFlag;

/**
 MP4播放结束时是否自动关闭MP4播放的视频
 */
@property (nonatomic, assign) BOOL pauseWhenOver;

/**
 文档分类
 */
@property (nonatomic, assign) BOOL documentCategoryFlag;

/**
 按下课时间结束课堂
 */
@property (nonatomic, assign) BOOL endClassTimeFlag;

/**
 分组
 */
@property (nonatomic, assign) BOOL groupFlag;

/**
 自定义白板底色
 */
@property (nonatomic, assign) BOOL whiteboardColorFlag;

/**
 自定义奖杯
 */
@property (nonatomic, assign) BOOL customTrophyFlag;

/**
 巡课身份隐藏下课按钮
 */
@property (assign, nonatomic) BOOL hideClassEndBtn;

/**
 切换纯音频教室
 */
@property (assign, nonatomic) BOOL canChangedToAudioOnly;

/**
 在白板中播放视频
 */
@property (nonatomic) BOOL coursewareOpenInWhiteboard;

/**
 课件全屏同步
 */
@property (assign, nonatomic) BOOL coursewareFullSynchronize;

/**
 在白板进行涂鸦的用户会在右下角显示用户昵称3秒
 3秒后昵称小时, 且自己无法看到自己的昵称显示,仅显示其他用户昵称
 */
@property (assign, nonatomic) BOOL isShowWriteUpTheName;

/**
 排序小视频
 */
@property (nonatomic, assign) BOOL sortSmallVideo;

/**
 学生端不显示网络状态
 */
@property (nonatomic, assign) BOOL unShowStudentNetState;

/**
 只看老师和自己的视频
 */
@property (nonatomic, assign) BOOL onlyMeAndTeacherVideo;

/**
 禁用翻页
 */
@property (nonatomic, assign) BOOL isHiddenPageFlip;

/**
 0:中英互译/1:中日互译
 */
@property (nonatomic, assign) BOOL isChineseJapaneseTranslation;

/**
 是否隐藏画笔工具形状
 */
@property (nonatomic, assign) BOOL shouldHideShapeOnDrawToolView;

/**
 是否隐藏画笔选择工具鼠标
 */
@property (nonatomic, assign) BOOL shouldHideMouseOnDrawToolView;

/**
 是否隐藏画笔调色盘字体字号选择
 */
@property (nonatomic, assign) BOOL shouldHideFontOnDrawSelectorView;

/**
 画笔穿透
 */
@property (nonatomic, assign) BOOL isPenCanPenetration;

/**
 隐藏踢人
 */
@property (nonatomic, assign) BOOL isHiddenKickOutStudentBtn;

/**
 课件预加载
 */
@property (nonatomic, assign) BOOL coursewarePreload;

/// 护眼模式 141
@property (nonatomic, assign) BOOL isRemindEyeCare;

/// 是否显示房间人数 200
@property (nonatomic, assign) BOOL isShowUserNum;

/// 是否允许课前互动 201
@property (nonatomic, assign) BOOL isChatBeforeClass;

/// 是否禁止观众私聊 202
@property (nonatomic, assign) BOOL isDisablePrivateChat;

/// 是否多课件 150
@property (nonatomic, assign) BOOL isMultiCourseware;

- (instancetype)initWithConfigurationString:(NSString *)configurationString;

@end

NS_ASSUME_NONNULL_END
