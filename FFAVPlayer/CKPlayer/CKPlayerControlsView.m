//
//  CKPlayerControlsView.m
//  FFAVPlayer
//
//  Created by cts on 2018/5/2.
//  Copyright © 2018年 cts. All rights reserved.
//

#import "CKPlayerControlsView.h"
#import <MediaPlayer/MPVolumeView.h>
#import "CKPlayerConfiguration.h"
#import "Masonry.h"


@interface CKPlayerControlsView ()

@property (nonatomic ,strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic ,weak) UISlider *volumeSlider;// 系统音量提示框
@property (nonatomic ,strong) MPVolumeView *volumeView; // 音量操作
@property (nonatomic ,assign) CKPlayerChange changeKind; // Gesture 屏幕操作要改变的内容
@property (nonatomic ,assign) CGPoint lastPoint; // 开始时手势触摸的点


@end


@implementation CKPlayerControlsView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addSwipeView];
        [self setupBottomControlsViews];
    }
    return self;
}
- (void)setIsFullScreen:(BOOL)isFullScreen {
    _isFullScreen = isFullScreen;
   
    if (!_fullScreenButton) {
        return;
    }
    if (isFullScreen) {
        _fullScreenButton.selected = YES;
    }else {
        _fullScreenButton.selected = NO;
    }
}

- (void)setPlaybackControlsWithPlayTime:(NSInteger)playTime totalTime:(NSInteger)totalTime sliderValue:(CGFloat)sliderValue {
    //当前时长进度progress
    NSInteger proMin = playTime / 60;//当前秒
    NSInteger proSec = playTime % 60;//当前分钟
    //duration 总时长
    NSInteger durMin = totalTime / 60;//总秒
    NSInteger durSec = totalTime % 60;//总分钟
    
    //更新当前播放时间
    self.playDuration.text = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
    //更新总时间
    self.playTotalDuration.text = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
}

#pragma mark -----------------------------------------
#pragma mark - 底部面板
- (void)setupBottomControlsViews {
    [self addSubview:self.controlButton];
    [self addSubview:self.playDuration];
    [self addSubview:self.playTotalDuration];
    [self addSubview:self.fullScreenButton];
    
    [_controlButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.mas_left).offset(0);
        make.bottom.mas_equalTo(self.mas_bottom).offset(0);
        make.height.width.mas_equalTo(30);
    }];
    [_playDuration mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(_controlButton.mas_centerY);
        make.left.mas_equalTo(_controlButton.mas_right).offset(0);
        make.width.mas_equalTo(50);
    }];
    [_fullScreenButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.mas_right).offset(0);
        make.bottom.mas_equalTo(self.mas_bottom).offset(0);
        make.height.width.mas_equalTo(30);
    }];
    [_playTotalDuration mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(_fullScreenButton.mas_centerY);
        make.right.mas_equalTo(_fullScreenButton.mas_left).offset(0);
        make.width.mas_equalTo(50);
    }];
}

-(UIButton *)controlButton {
    if (_controlButton == nil) {
        _controlButton = [[UIButton alloc]init];
        [_controlButton setImage:[UIImage imageNamed:@"al_play_start"] forState:UIControlStateNormal];
    }
    return _controlButton;
}
- (UILabel *)playDuration {
    if (_playDuration == nil) {
        _playDuration = [[UILabel alloc]init];
        _playDuration.text = @"00:00";
        _playDuration.textColor = [UIColor whiteColor];
        _playDuration.font = [UIFont systemFontOfSize:13];
        _playDuration.textAlignment = NSTextAlignmentLeft;
    }
    return _playDuration;
}
- (UILabel *)playTotalDuration {
    if (_playTotalDuration == nil) {
        _playTotalDuration = [[UILabel alloc]init];
        _playTotalDuration.text = @"00:00";
        _playTotalDuration.textColor = [UIColor whiteColor];
        _playTotalDuration.font = [UIFont systemFontOfSize:13];
        _playTotalDuration.textAlignment = NSTextAlignmentRight;
    }
    return _playTotalDuration;
}
- (UIButton *)fullScreenButton {
    if (_fullScreenButton == nil) {
        _fullScreenButton = [[UIButton alloc]init];
        [_fullScreenButton setImage:[UIImage imageNamed:@"ic_turn_screen_white_18x18_"] forState:UIControlStateNormal];
        [_fullScreenButton setImage:[UIImage imageNamed:@"ic_zoomout_screen_white_18x18_"] forState:UIControlStateSelected];
    }
    return _fullScreenButton;
}

#pragma mark - 手势
- (void)addSwipeView {
     UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(swipeAction:)];
    [self addGestureRecognizer:panGesture];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self addGestureRecognizer:tap];
    [tap requireGestureRecognizerToFail:panGesture];
}
- (void)tapAction:(UITapGestureRecognizer *)tap {
  
}

#pragma mak - 滑动操作
- (void)swipeAction:(UISwipeGestureRecognizer *)gesture {
//    if (!_isFullScreen) {
//        return;
//    }
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            _changeKind = CKPlayerChangeNone;
            _lastPoint = [gesture locationInView:self];
        } break;
        case  UIGestureRecognizerStateChanged: {
            [self getChangeKindValue:[gesture locationInView:self]];
        } break;
        case UIGestureRecognizerStateEnded: {
            if (_changeKind == CKPlayerChangeCMTime) {
                [self changeEndForCMTime:[gesture locationInView:self]];
            }
            _changeKind = CKPlayerChangeNone;
            _lastPoint = CGPointZero;
        } break;
        default: break;
    }
}
- (void)getChangeKindValue:(CGPoint)pointNow {
    switch (_changeKind) {
        case CKPlayerChangeNone: {
            [self changeForNone:pointNow];
        } break;
        case CKPlayerChangeCMTime: {
            [self changeForCMTime:pointNow];
        } break;
        case CKPlayerChangeLigth: {
            [self changeForLigth:pointNow];
        } break;
        case CKPlayerChangeVoice: {
            [self changeForVoice:pointNow];
        } break;
        default:
            break;
    }
}
- (void)changeForNone:(CGPoint) pointNow {
    if (fabs(pointNow.x - _lastPoint.x) > fabs(pointNow.y - _lastPoint.y)) {
        _changeKind = CKPlayerChangeCMTime;
    } else {
        float halfWight = self.bounds.size.width / 2;
        if (_lastPoint.x < halfWight) {
            _changeKind = CKPlayerChangeLigth;
        } else {
            _changeKind = CKPlayerChangeVoice;
        }
        _lastPoint = pointNow;
    }
}
- (void)changeForCMTime:(CGPoint) pointNow {
    float number = fabs(pointNow.x - _lastPoint.x);
    if (pointNow.x > _lastPoint.x && number > 10) {
        NSLog(@"forwart to  changeTo  time:%f",number);
    } else if (pointNow.x < _lastPoint.x && number > 10) {
        NSLog(@"back to  time:%f",number);
    }
}
- (void)changeEndForCMTime:(CGPoint)pointNow {
    if (pointNow.x > _lastPoint.x ) {
        NSLog(@"end for CMTime Upper");
        float length = fabs(pointNow.x - _lastPoint.x);
        [self upperCMTime:length];
    } else {
        NSLog(@"end for CMTime min");
        float length = fabs(pointNow.x - _lastPoint.x);
        [self mineCMTime:length];
    }
}
#pragma mark - CMTIME
- (void)upperCMTime:(float)length {
    float tobeTime = length * 0.5; // 要增加的进度时间
    NSLog(@"快进的时间%f",tobeTime);
    if ([self.delegate respondsToSelector:@selector(playerSeekToTime:ChangeCMTime:)]) {
        [self.delegate playerSeekToTime:tobeTime ChangeCMTime:CKPlayerUpperCMTime];
    }
}
- (void)mineCMTime:(float)length { 
    float tobeTime =  length * 0.5;
    NSLog(@"快退的时间%f",tobeTime);
    if ([self.delegate respondsToSelector:@selector(playerSeekToTime:ChangeCMTime:)]) {
        [self.delegate playerSeekToTime:tobeTime ChangeCMTime:CKPlayerMineCMTime];
    }
   
}

#pragma mark - Ligth
- (void)changeForLigth:(CGPoint) pointNow {
    float number = fabs(pointNow.y - _lastPoint.y);
    if (pointNow.y > _lastPoint.y && number > 10) {
        _lastPoint = pointNow;
        [self minLigth];
    } else if (pointNow.y < _lastPoint.y && number > 10) {
        _lastPoint = pointNow;
        [self upperLigth];
    }
}
- (void)upperLigth {
    NSLog(@"亮度增加");
    CGFloat currentLight = [[UIScreen mainScreen] brightness];
    if(currentLight < 1.0)  {
        [[UIScreen mainScreen] setBrightness: currentLight + 0.01];
    }
}
- (void)minLigth {
    NSLog(@"亮度减少");
    CGFloat currentLight = [[UIScreen mainScreen] brightness];
    if(currentLight > 0)  {
        [[UIScreen mainScreen] setBrightness: currentLight - 0.01];
    }
}

#pragma mark - Voice
- (void)changeForVoice:(CGPoint)pointNow {
    float number = fabs(pointNow.y - _lastPoint.y);
    if (pointNow.y > _lastPoint.y && number > 10) {
        _lastPoint = pointNow;
        [self minVolume];
    } else if (pointNow.y < _lastPoint.y && number > 10) {
        _lastPoint = pointNow;
        [self upperVolume];
    }
}
- (void)upperVolume {
    NSLog(@"声音增加");
    NSLog(@"self.volumeView.frame = %@",NSStringFromCGRect(self.volumeView.frame));
    if (self.volumeSlider.value <= 1.0) {
        self.volumeSlider.value =  self.volumeSlider.value + 0.1 ;
    }
}
- (void)minVolume {
    NSLog(@"声音减少");
    if (self.volumeSlider.value >= 0.0) {
        self.volumeSlider.value =  self.volumeSlider.value - 0.1 ;
    }
}
#pragma mark - set & get
- (MPVolumeView *)volumeView {
    
    if (_volumeView == nil) {
        _volumeView = [[MPVolumeView alloc] init];
        _volumeView.hidden = YES;
        _volumeView.showsRouteButton = YES;
        //默认YES，这里为了突出，故意设置一遍
        _volumeView.showsVolumeSlider = YES;
        //通过设置frame来达到隐藏音量滑动条
        //        [_volumeView setFrame:CGRectMake(100, 100, 10, 10)];
        [self addSubview:_volumeView];
    }
    return _volumeView;
}
- (UISlider *)volumeSlider {
    if (_volumeSlider== nil) {
        NSLog(@"%@",[self.volumeView subviews]);
        for (UIView  *subView in [self.volumeView subviews]) {
            if ([subView.class.description isEqualToString:@"MPVolumeSlider"]) {
                _volumeSlider = (UISlider*)subView;
                break;
            }
        }
    }
    return _volumeSlider;
}
@end

