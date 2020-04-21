//
//  YSDrawView.m
//  YSWhiteBoard
//
//  Created by ys on 2019/4/1.
//  Copyright © 2019 MAC-MiNi. All rights reserved.
//

#import "YSDrawView.h"
#import "DrawBase.h"
#import "DrawText.h"
#import <YSRoomSDK/YSRoomSDK.h>
#import "DrawView.h"

@interface YSDrawView () <DrawViewDelegate>

@end
@implementation YSDrawView {
    DrawBase *_draw;

    YSDrawType _selectedType;
    NSString *_selectedHexColor;
    CGFloat _selectedProgress;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)init {
    if (self = [super init]) { [self create]; }

    return self;
}

- (instancetype)initWithDelegate:(nullable id<YSDrawViewDelegate>)delegate {
    if (self = [self init]) { _delegate = delegate; }

    return self;
}

- (void)create {
    _drawView                 = [[DrawView alloc] init];
    _drawView.delegate        = self;
    _drawView.backgroundColor = [UIColor clearColor];
    [self addSubview:_drawView];
    [_drawView bmmas_makeConstraints:^(BMMASConstraintMaker *make) {
        make.top.bmmas_equalTo(self.bmmas_top);
        make.left.bmmas_equalTo(self.bmmas_left);
        make.bottom.bmmas_equalTo(self.bmmas_bottom);
        make.right.bmmas_equalTo(self.bmmas_right);
    }];

    _rtDrawView                 = [[DrawView alloc] init];
    _rtDrawView.delegate        = self;
    _rtDrawView.backgroundColor = [UIColor clearColor];
    //    _rtDrawView.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.4f];
    _rtDrawView.mode = YSWorkModeControllor;
    [self addSubview:_rtDrawView];
    [_rtDrawView bmmas_makeConstraints:^(BMMASConstraintMaker *make) {
        make.top.bmmas_equalTo(self.bmmas_top);
        make.left.bmmas_equalTo(self.bmmas_left);
        make.bottom.bmmas_equalTo(self.bmmas_bottom);
        make.right.bmmas_equalTo(self.bmmas_right);
    }];

    [_rtDrawView addObserver:self
                  forKeyPath:@"iFontScale"
                     options:NSKeyValueObservingOptionNew
                     context:nil];
}

- (BOOL)hasDraw {
    if (_rtDrawView.draw) {
        return YES;
    } else {
        return NO;
    }
}

- (void)setMode:(YSWorkMode)mode {
    _drawView.mode = mode;
    if ([YSRoomInterface instance].localUser.role == YSUserType_Patrol) {
        _drawView.mode = YSWorkModeViewer;
    }
}

- (void)clearDrawWithMsg
{
    [_drawView clearDraw];
}

- (void)setDrawType:(YSDrawType)drawType hexColor:(NSString *)hexColor progress:(CGFloat)progress {
    _selectedType     = drawType;
    _selectedHexColor = hexColor;
    _selectedProgress = progress;

    _rtDrawView.hidden = NO;
    switch (drawType) {
        case YSDrawTypePen: {
            [_rtDrawView selectDraw:Draw_Pen];
            break;
        }
        case YSDrawTypeMarkPen: {
            [_rtDrawView selectDraw:Draw_MarkPen];
            break;
        }
        case YSDrawTypeLine: {
            [_rtDrawView selectDraw:Draw_Line];
            break;
        }
        case YSDrawTypeArrowLine: {
            [_rtDrawView selectDraw:Draw_Arrow];
            break;
        }
        case YSDrawTypeTextMS: {
            if (progress <= 0.15f) {
                progress = 0.15f;
            } else {
                progress = progress;
            }
            [_rtDrawView selectDraw:Draw_Text_Size];
            break;
        }
        case YSDrawTypeEmptyRectangle: {
            [_rtDrawView selectDraw:Draw_EmptyRect];
            break;
        }
        case YSDrawTypeFilledRectangle: {
            [_rtDrawView selectDraw:Draw_SolidRect];
            break;
        }
        case YSDrawTypeEmptyEllipse: {
            [_rtDrawView selectDraw:Draw_EmptyCircle];
            break;
        }
        case YSDrawTypeFilledEllipse: {
            [_rtDrawView selectDraw:Draw_SolidCircle];
            break;
        }
        case YSDrawTypeEraser: {
            _rtDrawView.hidden = YES;
            [_drawView selectDraw:Draw_Eraser];
            break;
        }
        default:
            break;
    }

    if (_rtDrawView.hidden) {
        DRAWDATA data           = _drawView.draw.drawData;
        RGBAType rgba           = [DrawBase rgbaColorFromColorString:hexColor];
        data.brush.color        = rgba;
        data.pen.lpWidth        = progress * 30 / _drawView.iFontScale;
        _drawView.draw.drawData = data;
    } else {
        DRAWDATA data             = _rtDrawView.draw.drawData;
        RGBAType rgba             = [DrawBase rgbaColorFromColorString:hexColor];
        data.brush.color          = rgba;
        data.pen.lpWidth          = progress * 30 / _rtDrawView.iFontScale;
        _rtDrawView.draw.drawData = data;
    }
}

- (void)addDrawData:(NSDictionary *)data refreshImmediately:(BOOL)refresh {
    [_drawView addDrawSharpData:data isUpdate:refresh];
    NSString *shapeId = [data objectForKey:@"shapeId"];
    [_rtDrawView removeOneDraw:shapeId];
}

- (void)undoDraw {
    [_drawView undoDrawMap];
}

- (void)clearDraw:(NSString *)clearID {
    [_drawView clearDrawMapByClearID:clearID];
}

- (void)switchToFileID:(NSString *)fileID pageID:(int)pageID refreshImmediately:(BOOL)refresh {
    [_drawView switchFileID:fileID andCurrentPage:pageID updateImmediately:refresh];
    [_rtDrawView switchFileID:fileID andCurrentPage:pageID updateImmediately:refresh];
}

- (void)setWorkMode:(YSWorkMode)mode {
    _rtDrawView.mode = mode;
    _drawView.mode   = YSWorkModeControllor;
}

- (void)clearDataAfterClass {
    [_drawView clearDataAfterClass];
    _rtDrawView.textView.text = @"";
    [_rtDrawView.textView removeFromSuperview];
}

- (void)clearOnePageWithFileID:(NSString *)fileID pageNum:(int)pageNum {
    [_drawView clearOnePageWithFileID:fileID pageNum:pageNum];
}

- (NSString *)fileid {
    return _rtDrawView.fileid;
}

- (void)setFileid:(NSString *)fileid {
    _drawView.fileid   = fileid;
    _rtDrawView.fileid = fileid;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"iFontScale"]) {
        if ([_rtDrawView.draw isKindOfClass:[DrawText class]]) { return; }
        NSNumber *iFontScale = [change objectForKey:NSKeyValueChangeNewKey];
        if (isnan(iFontScale.floatValue)) { return; }
        self.iFontScale = iFontScale.floatValue;
    }
}

- (void)setIFontScale:(float)iFontScale {
    //    _drawView.iFontScale = iFontScale;
    //    _rtDrawView.iFontScale = iFontScale;
    _iFontScale = iFontScale;
    [self setDrawType:_selectedType hexColor:_selectedHexColor progress:_selectedProgress];
}

- (DrawBase *)draw {
    return _rtDrawView.draw;
}

- (void)addSharpWithFileID:(NSString *)fileid
                   shapeID:(NSString *)shapeID
                 shapeData:(NSData *)shapeData {
    if (_delegate &&
        [_delegate respondsToSelector:@selector(addSharpWithFileID:shapeID:shapeData:)]) {
        [_delegate addSharpWithFileID:fileid shapeID:shapeID shapeData:shapeData];
    }
}

- (void)dealloc {
    [_rtDrawView removeObserver:self forKeyPath:@"iFontScale"];
}
@end
