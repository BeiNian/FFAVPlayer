//
//  FFVideoPlayerView.m
//  FFAVPlayer
//
//  Created by cts on 2018/4/28.
//  Copyright © 2018年 cts. All rights reserved.
//

#import "FFVideoPlayerView.h"
#import <AVFoundation/AVFoundation.h> 

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
/** 非全屏状态下播放器 superview */
@property (nonatomic, strong) UIView *originalSuperview;
/** 非全屏状态下播放器 frame */
@property (nonatomic, assign) CGRect originalRect;

@end

@implementation FFVideoPlayerView
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
}

- (void)playVideo {
    [_player play];
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
    }
}
- (void)createPeriodicTimer {
    AVPlayerItem *playerItem=self.player.currentItem;
    __weak typeof(self) weakSelf = self;
    //这里设置每秒执行一次
    _timeObserve = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
        NSLog(@"🖨1当前已经播放%.2fs.",current); 
    }];
    
}

@end
