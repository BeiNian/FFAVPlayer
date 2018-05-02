//
//  FFVideoPlayerView.m
//  FFAVPlayer
//
//  Created by cts on 2018/4/28.
//  Copyright © 2018年 cts. All rights reserved.
//

#import "FFVideoPlayerView.h"
#import <AVFoundation/AVFoundation.h> 
#import <MediaPlayer/MPVolumeView.h>
#import "FFPlayerControlsView.h"


@interface FFVideoPlayerView ()
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
/// 时间监听
@property (nonatomic ,strong)  id timeObserve;
/// 配置
@property (nonatomic, nullable, strong) FFPlayerConfiguration *playerConfiguration;
/// 是否处于全屏状态
@property (nonatomic, assign) BOOL isFullScreen;
/// 是否正在播放
@property (nonatomic, assign) BOOL isPayering;
/** 非全屏状态下播放器 superview */
@property (nonatomic, strong) UIView *originalSuperview;
/** 非全屏状态下播放器 frame */
@property (nonatomic, assign) CGRect originalRect;
/** 控制面板 */
@property (nonatomic, nullable, strong) FFPlayerControlsView *playerControlsView;


#pragma mark - FFVideoPlayerView (Guester)
@property (nonatomic ,strong) UIPanGestureRecognizer *panGesture;
/** 亮度图片 */
@property (nonatomic, nullable, strong) UIImageView *brightnessImgView;
/** 系统音量提示框 */
@property (nonatomic ,weak) UISlider *volumeSlider;
/** 音量操作 */
@property (nonatomic ,strong) MPVolumeView *volumeView;
// Gesture 屏幕操作要改变的内容
@property (nonatomic ,assign) Change changeKind;
/** 手势开始触摸的点 */
@property (nonatomic ,assign) CGPoint lastPoint;
/** 视频总长度 */
@property (nonatomic ,assign) float playLength;
@end

@implementation FFVideoPlayerView
#pragma mark - FFVideoPlayerView lifecycle
/**
 初始化播放器
 @param configuration 播放器配置信息
 */
- (instancetype)initWithFrame:(CGRect)frame configuration:(FFPlayerConfiguration *)configuration {
    self = [super initWithFrame:frame];
    if (self) {
        _playerConfiguration = configuration;
        [self setupPlayer];
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [self addNotification];
        [self addSwipeView]; // 添加手势
    }
    return self;
}
- (void)dealloc {
    self.playerItem = nil;
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    if (self.timeObserve) {
        [self.player removeTimeObserver:self.timeObserve];
        self.timeObserve = nil;
    }
    self.playerLayer = nil;
    self.player = nil;
}

- (void)addNotification {
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

/** 屏幕翻转监听事件 */
- (void)orientationChanged:(NSNotification *)notify {
    if (_playerConfiguration.shouldAutorotate) {
        [self orientationAspect];
    }
}
- (void)orientationAspect {
    UIDeviceOrientation orientaion = [UIDevice currentDevice].orientation;
    switch (orientaion) {
        case UIDeviceOrientationLandscapeLeft:{
            if (!_isFullScreen) {
                [self videoZoomInWithDirection:UIInterfaceOrientationLandscapeRight];
            }
        } break;
        case UIDeviceOrientationLandscapeRight:{
            if (!_isFullScreen) {
                [self videoZoomInWithDirection:UIInterfaceOrientationLandscapeLeft];
            }
        } break;
        case UIDeviceOrientationPortrait:{
            if (_isFullScreen) {
                [self videoZoomOut];
            }
        } break;
            
        default:
            break;
    }
}
/**
 视频放大全屏幕
 @param orientation 旋转方向
 */
- (void)videoZoomInWithDirection:(UIInterfaceOrientation)orientation {
    // 记录小屏幕时位置
    _originalSuperview = self.superview;
    _originalRect = self.frame;
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [keyWindow addSubview:self];
    CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
    [[UIApplication sharedApplication] setStatusBarOrientation:orientation animated:NO];
    
    [UIView animateWithDuration:duration animations:^{
        if (orientation == UIInterfaceOrientationLandscapeLeft){
            self.transform = CGAffineTransformMakeRotation(-M_PI/2);
        }else if (orientation == UIInterfaceOrientationLandscapeRight) {
            self.transform = CGAffineTransformMakeRotation(M_PI/2);
        }
    }completion:^(BOOL finished) {
    }];
    self.frame = keyWindow.bounds;
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    self.isFullScreen = YES;
}
/** 视频退出全屏幕 */
- (void)videoZoomOut {
    //退出全屏时强制取消隐藏状态栏
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:NO];
    [UIView animateWithDuration:duration animations:^{
        self.transform = CGAffineTransformMakeRotation(0);
    }completion:^(BOOL finished) {
        
    }];
    self.frame = _originalRect;
    [_originalSuperview addSubview:self];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    self.isFullScreen = NO;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
    self.playerControlsView.frame = self.bounds;
}

- (void)playVideo {
    [_player play];
}
- (void)pauseVideo {
    [_player pause];
}

- (void)setupPlayer {
    self.playerItem = [AVPlayerItem playerItemWithURL:_playerConfiguration.sourceUrl];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [self.layer addSublayer:_playerLayer];
    [self setBackgroundColor:[UIColor blackColor]];
    
    [self createPeriodicTimer];
    
    if (_playerConfiguration.shouldAutoPlay) {
        [self playVideo];
        _isPayering = YES;
    }
}
- (void)createPeriodicTimer {
    AVPlayerItem *playerItem=self.player.currentItem;
    __weak typeof(self) weakSelf = self;
    //这里设置每秒执行一次
    _timeObserve = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
        NSLog(@"🖨 当前已经播放%.2fs.",current);
    }]; 
}

/** 播放器控制面板 */
- (FFPlayerControlsView *)playerControlsView {
    if (_playerControlsView == nil) {
        _playerControlsView = [[FFPlayerControlsView alloc]init];
    }
    return _playerControlsView;
}



@end

#pragma mark - FFVideoPlayerView (Guester)
@implementation FFVideoPlayerView (Guester)

- (void)addSwipeView {
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(swipeAction:)];
    [self addGestureRecognizer:_panGesture];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self addGestureRecognizer:tap];
    [tap requireGestureRecognizerToFail:_panGesture];
}
- (void)tapAction:(UITapGestureRecognizer *)tap {
    if (_isPayering) {
        [self pauseVideo];
    }else {
        [self playVideo];
    }
    _isPayering = !_isPayering;
}

- (void)swipeAction:(UISwipeGestureRecognizer *)gesture {
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            _changeKind = ChangeNone;
            _lastPoint = [gesture locationInView:self];
            [self pauseVideo];
        } break;
        case  UIGestureRecognizerStateChanged: {
            [self getChangeKindValue:[gesture locationInView:self]];
        } break;
        case UIGestureRecognizerStateEnded: {
            if (_changeKind == ChangeCMTime) {
                [self changeEndForCMTime:[gesture locationInView:self]];
            }
            [self playVideo];
            _changeKind = ChangeNone;
            _lastPoint = CGPointZero;
            _brightnessImgView.hidden = YES;
        } break;
        default: break;
    }
}

- (void)getChangeKindValue:(CGPoint)pointNow {
    switch (_changeKind) {
        case ChangeNone: {
            [self changeForNone:pointNow];
        } break;
        case ChangeCMTime: {
            [self changeForCMTime:pointNow];
        } break;
        case ChangeLigth: {
            [self changeForLigth:pointNow];
        } break;
        case ChangeVoice: {
            [self changeForVoice:pointNow];
        } break;
        default:
            break;
    }
}
- (void)changeForNone:(CGPoint) pointNow {
    if (fabs(pointNow.x - _lastPoint.x) > fabs(pointNow.y - _lastPoint.y)) {
        _changeKind = ChangeCMTime;
    } else {
        float halfWight = self.bounds.size.width / 2;
        if (_lastPoint.x < halfWight) {
            _changeKind = ChangeLigth;
            _brightnessImgView.hidden = NO;
        } else {
            _changeKind = ChangeVoice;
        }
        _lastPoint = pointNow;
    }
}
- (void)changeForCMTime:(CGPoint) pointNow {
    float number = fabs(pointNow.x - _lastPoint.x);
    if (pointNow.x > _lastPoint.x && number > 10) {
        float currentTime = _player.currentItem.currentTime.value/_player.currentItem.currentTime.timescale;
        float tobeTime = currentTime + number*0.5;
        NSLog(@"forwart to  changeTo  time:%f",tobeTime);
    } else if (pointNow.x < _lastPoint.x && number > 10) {
        float currentTime = _player.currentItem.currentTime.value/_player.currentItem.currentTime.timescale;
        float tobeTime = currentTime - number*0.5;
        NSLog(@"back to  time:%f",tobeTime);
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
    float currentTime = _player.currentItem.currentTime.value/_player.currentItem.currentTime.timescale;
    float tobeTime = currentTime + length * 0.5;
    if (tobeTime > _playLength) {
        [_player seekToTime:CMTimeMake(tobeTime, 1)];
        // [_player seekToTime:_playerItem.asset.duration]; // 跳转到指定时间
    } else {
        [_player seekToTime:CMTimeMake(tobeTime, 1)];
    }
}
- (void)mineCMTime:(float)length {
    float currentTime = _player.currentItem.currentTime.value/_player.currentItem.currentTime.timescale;
    float tobeTime = currentTime - length*0.5;
    if (tobeTime <= 0) {
        [_player seekToTime:kCMTimeZero];
    } else {
        [_player seekToTime:CMTimeMake(tobeTime, 1)];
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
- (UIImageView *)brightnessImgView {
    if (_brightnessImgView == nil) {
        _brightnessImgView = [[UIImageView alloc]init];
        _brightnessImgView.image = [UIImage imageNamed:@"al_fingerGesture_brightness"];
        _brightnessImgView.backgroundColor = [UIColor whiteColor];
        _brightnessImgView.layer.cornerRadius = 5;
        _brightnessImgView.layer.masksToBounds = YES;
        _brightnessImgView.hidden = YES;
    }
    return _brightnessImgView;
}
@end

