//
//  FFPlayerView.m
//  FFAVPlayer
//
//  Created by cts on 2018/4/20.
//  Copyright © 2018年 cts. All rights reserved.
//

#import "FFPlayerView.h"
#import <MediaPlayer/MPVolumeView.h>

typedef enum  {
    ChangeNone,
    ChangeVoice,
    ChangeLigth,
    ChangeCMTime
}Change;

@interface FFPlayerView ()
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic ,strong)  id timeObser;
/** 视频总长度 */
@property (nonatomic ,assign) float playLength;

/** 是否处于全屏状态 */
@property (nonatomic, assign) BOOL isFullScreen;
/** 非全屏状态下播放器 superview */
@property (nonatomic, strong) UIView *originalSuperview;
/** 非全屏状态下播放器 frame */
@property (nonatomic, assign) CGRect originalRect;

#pragma mark -
@property (nonatomic ,strong) UIPanGestureRecognizer *panGesture;
/** 亮度图片 */
@property (nonatomic, nullable, strong) UIImageView *brightnessImgView;
/** 系统音量提示框 */
@property (nonatomic ,weak) UISlider *volumeSlider;
/** 音量操作 */
@property (nonatomic ,strong) MPVolumeView *volumeView;
//Gesture 屏幕操作要改变的内容
@property (nonatomic ,assign) Change changeKind;
/** 手势开始触摸的点 */
@property (nonatomic ,assign) CGPoint lastPoint;


@end

@implementation FFPlayerView

- (id)initWithUrl:(NSString *)url delegate:(id<FFPlayerViewDelegate>)delegate {
    if (self = [super init]) {
        _playerUrl = url;
        _delegate = delegate;
        [self setBackgroundColor:[UIColor blackColor]];
        [self setUpPlayer];
        [self addPlayerKVO];
        [self addProgressObserver];
        [self addNotification];
        [self addSwipeView]; 
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    _playerLayer.frame = self.bounds;
    _brightnessImgView.bounds = CGRectMake(0, 0, 75, 75);
    _brightnessImgView.center =  self.center;
}

- (void)setUpPlayer {
    NSURL *url = [NSURL URLWithString:_playerUrl];
    _playerItem = [AVPlayerItem playerItemWithURL:url];
    _player = [AVPlayer playerWithPlayerItem:_playerItem];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    [self.layer addSublayer:_playerLayer];
    [self addSubview:self.brightnessImgView];
}
- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
}
/** 屏幕翻转监听事件 */
- (void)orientationChanged:(NSNotification *)notify
{
    [self orientationAspect];
}
/** 根据屏幕旋转方向改变当前视频屏幕状态 */
- (void)orientationAspect
{
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if (orientation == UIDeviceOrientationLandscapeLeft){
        if (!_isFullScreen){
            [self _videoZoomInWithDirection:UIInterfaceOrientationLandscapeRight];
        }
    }
    else if (orientation == UIDeviceOrientationLandscapeRight){
        if (!_isFullScreen){
            [self _videoZoomInWithDirection:UIInterfaceOrientationLandscapeLeft];
        }
    }
    else if(orientation == UIDeviceOrientationPortrait){
        if (_isFullScreen){
            [self _videoZoomOut];
        }
    }
}
/** 视频退出全屏幕 */
- (void)_videoZoomOut
{
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
/**
 视频放大全屏幕
 @param orientation 旋转方向
 */
- (void)_videoZoomInWithDirection:(UIInterfaceOrientation)orientation
{
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
//    [self setNeedsLayout];
//    [self layoutIfNeeded];
    
    self.isFullScreen = YES;
}
#pragma mark - KVO
- (void)addPlayerKVO {
    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监控网络加载情况属性
    [_playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
}
- (void)removePlayerKVO {
    [_playerItem removeObserver:self forKeyPath:@"status"];
    [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
}
- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString*, id> *)change context:(nullable void *)context {
//    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = _playerItem.status;
        switch (status) {
            case AVPlayerItemStatusReadyToPlay: {
                NSLog(@"AVPlayerItemStatusReadyToPlay");
                NSLog(@"正在播放...，视频总长度:%.2f",CMTimeGetSeconds(_playerItem.duration));
                [self play];
                _playLength = floor(_playerItem.asset.duration.value * 1.0/ _playerItem.asset.duration.timescale);
//                _shouldFlushSlider = YES;
            }
                break;
            case AVPlayerItemStatusUnknown: {
                NSLog(@"AVPlayerItemStatusUnknown");
            } break;
            case AVPlayerItemStatusFailed: {
                NSLog(@"AVPlayerItemStatusFailed");
                NSLog(@"%@",_playerItem.error);
            } break;
            default: break;
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        
    }
}

/**
 *  给播放器添加进度更新
 */
-(void)addProgressObserver {
    AVPlayerItem *playerItem=self.player.currentItem;
//    UIProgressView *progress=self.progress;
    //    UISlider *slider = self.slider;
    __weak typeof(self) weakSelf = self;
    //这里设置每秒执行一次
    _timeObser = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
//        float total = CMTimeGetSeconds([playerItem duration]);
        NSLog(@"🖨1当前已经播放%.2fs.",current);
//
        
        float currentTime = time.value*1.0/time.timescale/weakSelf.playLength;
        NSString *currentString = [weakSelf getStringFromCMTime:time];
//        NSLog(@"🖨当前已经播放%@s.",currentString);
        if ([weakSelf.delegate respondsToSelector:@selector(flushCurrentTime:sliderValue:)]) {
            [weakSelf.delegate flushCurrentTime:currentString sliderValue:currentTime];
        }
    }];
}

- (void)removeProgressObserver {
    [_player removeTimeObserver:_timeObser];
    _timeObser = nil;
}

- (void)play {
     [_player play];
}
- (void)pause {
    [_player pause];
}

- (void)stop {
    [self removePlayerKVO];
    [self removeProgressObserver];
}

#pragma mark - Utils
- (NSString *)getStringFromCMTime:(CMTime)time {
    float currentTimeValue = (CGFloat)time.value/time.timescale;//得到当前的播放时
    
    NSDate * currentDate = [NSDate dateWithTimeIntervalSince1970:currentTimeValue];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSInteger unitFlags = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond ;
    NSDateComponents *components = [calendar components:unitFlags fromDate:currentDate];
    
    if (currentTimeValue >= 3600 ) {
        return [NSString stringWithFormat:@"%ld:%ld:%ld",components.hour,components.minute,components.second];
    } else {
        return [NSString stringWithFormat:@"%ld:%ld",components.minute,components.second];
    }
}
@end


#pragma mark - FFPlayerView (Guester)
@implementation FFPlayerView (Guester)

- (void)addSwipeView {
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(swipeAction:)];
    [self addGestureRecognizer:_panGesture];
    
}
- (void)swipeAction:(UISwipeGestureRecognizer *)gesture {
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            _changeKind = ChangeNone;
            _lastPoint = [gesture locationInView:self];
            [self pause];
        } break;
        case  UIGestureRecognizerStateChanged: {
            [self getChangeKindValue:[gesture locationInView:self]];
        } break;
        case UIGestureRecognizerStateEnded: {
            if (_changeKind == ChangeCMTime) {
                [self changeEndForCMTime:[gesture locationInView:self]];
            }
            [self play];
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
        float currentTime = _player.currentTime.value / _player.currentTime.timescale;
        float tobeTime = currentTime + number*0.5;
        NSLog(@"forwart to  changeTo  time:%f",tobeTime);
    } else if (pointNow.x < _lastPoint.x && number > 10) {
        float currentTime = _player.currentTime.value / _player.currentTime.timescale;
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
    float currentTime = _player.currentTime.value / _player.currentTime.timescale;
    float tobeTime = currentTime + length * 0.5;
    if (tobeTime > _playLength) {
        [_player seekToTime:_playerItem.asset.duration]; // 跳转到指定时间
    } else {
        [_player seekToTime:CMTimeMake(tobeTime, 1)];
    }
}
- (void)mineCMTime:(float)length {
    float currentTime = _player.currentTime.value / _player.currentTime.timescale;
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
