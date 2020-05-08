//
//  YSRoomConfiguration.m
//  YSLive
//
//  Created by jiang deng on 2019/10/15.
//  Copyright © 2019 FS. All rights reserved.
//

#import "YSRoomConfiguration.h"

@implementation YSRoomConfiguration

- (instancetype)initWithConfigurationString:(NSString *)configurationString
{
    if (![configurationString bm_isNotEmpty])
    {
        return nil;
    }
    
    if (self = [super init])
    {
        self.configurationString = configurationString;
        
        self.autoQuitClassWhenClassOverFlag     = [self cutOutStringWithIndex: 7];
        self.autoOpenAudioAndVideoFlag          = [self cutOutStringWithIndex: 23];
        self.autoStartClassFlag                 = [self cutOutStringWithIndex: 32];
        self.allowStudentCloseAV                = [self cutOutStringWithIndex: 33];
        self.hideClassBeginEndButton            = [self cutOutStringWithIndex: 34];
        self.assistantCanPublish                = [self cutOutStringWithIndex: 36];
        self.canDrawFlag                        = [self cutOutStringWithIndex: 37];
        self.canPageTurningFlag                 = [self cutOutStringWithIndex: 38];
        self.beforeClassPubVideoFlag            = [self cutOutStringWithIndex: 41];
        self.autoShowAnswerAfterAnswer          = [self cutOutStringWithIndex: 42];
        self.coursewareRemarkFlag               = [self cutOutStringWithIndex: 43];
        self.forbidLeaveClassFlag               = [self cutOutStringWithIndex: 47];
        self.customTrophyFlag                   = [self cutOutStringWithIndex: 44];
        self.videoWhiteboardFlag                = [self cutOutStringWithIndex: 48];
        self.coursewareFullSynchronize          = [self cutOutStringWithIndex: 50];
        self.pauseWhenOver                      = [self cutOutStringWithIndex: 52];
        self.documentCategoryFlag               = [self cutOutStringWithIndex: 56];
        self.isShowWriteUpTheName               = [self cutOutStringWithIndex: 58];
        self.endClassTimeFlag                   = [self cutOutStringWithIndex: 71];
        self.groupFlag                          = [self cutOutStringWithIndex: 75];
        self.hideClassEndBtn                    = [self cutOutStringWithIndex: 78];
        self.canChangedToAudioOnly              = [self cutOutStringWithIndex: 80];
        self.whiteboardColorFlag                = [self cutOutStringWithIndex: 81];
        self.coursewarePreload                  = [self cutOutStringWithIndex: 102];
        self.coursewareOpenInWhiteboard         = [self cutOutStringWithIndex: 104];
        self.isHiddenPageFlip                   = [self cutOutStringWithIndex: 112];
        self.shouldHideMouseOnDrawToolView      = [self cutOutStringWithIndex: 113];
        self.shouldHideShapeOnDrawToolView      = [self cutOutStringWithIndex: 114];
        self.shouldHideFontOnDrawSelectorView   = [self cutOutStringWithIndex: 115];
        self.sortSmallVideo                     = [self cutOutStringWithIndex: 116];
        self.unShowStudentNetState              = [self cutOutStringWithIndex: 117];
        self.onlyMeAndTeacherVideo              = [self cutOutStringWithIndex: 119];
        self.isChineseJapaneseTranslation       = [self cutOutStringWithIndex: 122];
        self.isPenCanPenetration                = [self cutOutStringWithIndex: 131];
        self.isHiddenKickOutStudentBtn          = [self cutOutStringWithIndex: 135];
        self.isRemindEyeCare                    = [self cutOutStringWithIndex: 141];
        self.isMultiCourseware                  = [self cutOutStringWithIndex: 150];
        self.isMultiCourseware = YES;
        self.isShowUserNum                      = [self cutOutStringWithIndex: 200];
        self.isChatBeforeClass                  = [self cutOutStringWithIndex: 201];
        self.isDisablePrivateChat               = [self cutOutStringWithIndex: 202];
    }
    
    return self;
}

- (BOOL)cutOutStringWithIndex:(NSUInteger)index
{
    if (self.configurationString.length > index)
    {
        //return [[self.configurationString substringWithRange:NSMakeRange(index, 1)] isEqualToString:@"1"] ? YES : NO;
        unichar c = [self.configurationString characterAtIndex:index];
        return (c-'0');
    }
    else
    {
        return NO;
    }
}

@end
