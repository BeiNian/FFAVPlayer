//
//  CKPlayerView.m
//  FFAVPlayer
//
//  Created by cts on 2018/5/2.
//  Copyright © 2018年 cts. All rights reserved.
//

#import "CKPlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import "CKPlayerControlsView.h"

@interface CKPlayerView () <CKPlayerControlsDelegate>
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) id timeObserve;// 时间监听
@property (nonatomic, strong) CKPlayerConfiguration *configuration;// 配置信息
@property (nonatomic, assign) BOOL isFullScreen;// 是否处于全屏状态
@property (nonatomic, strong) UIView *originalSuperview; // 非全屏状态下播放器 superview
@property (nonatomic, assign) CGRect originalRect; // 非全屏状态下播放器 frame
@property (nonatomic, strong) CKPlayerControlsView *playerControlsView;//控制面板
@property (nonatomic ,assign) float playTotalDuration; // 视频总时长


@end

@implementation CKPlayerView
#pragma mark - FFVideoPlayerView lifecycle
/**
 初始化播放器
 @param configuration 播放器配置信息
 */
- (instancetype)initWithFrame:(CGRect)frame configuration:(CKPlayerConfiguration *)configuration {
    self = [super initWithFrame:frame];
    if (self) {
        _configuration = configuration;
        [self setupPlayer];
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [self addOrientationChangedNotification];
        [self addShowControls];
    }
    return self;
}
- (void)dealloc {
    self.playerItem = nil;
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    
    if (self.timeObserve) {
        [self.player removeTimeObserver:self.timeObserve];
        self.timeObserve = nil;
    }
    self.playerLayer = nil;
    self.player = nil;
    NSLog(@"dealloc");
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
    if (_playerControlsView) {
        _playerControlsView.frame = self.bounds;
    }
}
- (void)setupPlayer {
    self.playerItem = [AVPlayerItem playerItemWithURL:_configuration.sourceUrl];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [self.layer addSublayer:_playerLayer];
    [self setBackgroundColor:[UIColor blackColor]];
    
    [self createPeriodicTimer];
    
    if (_configuration.shouldAutoPlay) {
        [self playVideo];
    }
}
- (void)addShowControls {
    if (_configuration.showControls) {
        self.playerControlsView = [CKPlayerControlsView new];
        _playerControlsView.delegate = self;
        [self addSubview:_playerControlsView];
        [self bringSubviewToFront:_playerControlsView];
    }
}
- (void)createPeriodicTimer {
    __weak typeof(self) weakSelf = self;
    //这里设置每秒执行一次
    _timeObserve = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
//        float current = CMTimeGetSeconds(time);
        //NSLog(@"🖨 当前已经播放%.2fs.",current);
        AVPlayerItem *currentItem = weakSelf.playerItem;
        NSArray *loadedRanges = currentItem.seekableTimeRanges;
        if (loadedRanges.count > 0 && currentItem.duration.timescale != 0) {
            NSInteger currentTime = (NSInteger)CMTimeGetSeconds([currentItem currentTime]);
            CGFloat totalTime = (CGFloat)currentItem.duration.value / currentItem.duration.timescale;
            CGFloat value = CMTimeGetSeconds([currentItem currentTime]) / totalTime;
            [weakSelf.playerControlsView setPlaybackControlsWithPlayTime:currentTime totalTime:totalTime sliderValue:value];
        }
    }];
}

#pragma mark - CKPlayerControlsDelegate
- (void)playerSeekToTime:(CGFloat)toTime ChangeCMTime:(CKChangeCMTime)changeCMTime {
    float currentTime = _player.currentItem.currentTime.value/_player.currentItem.currentTime.timescale;
    switch (changeCMTime) {
        case CKPlayerUpperCMTime:{
            float tobeTime = currentTime + toTime * 0.5;
            if (toTime >= _playTotalDuration) {
                [_player seekToTime:CMTimeMake(_playTotalDuration, 1)];
            }else {
                [_player seekToTime:CMTimeMake(tobeTime, 1)];
            }
        }break;
        case CKPlayerMineCMTime:{
            float tobeTime = currentTime - toTime * 0.5;
            if (toTime <= 0) {
                [_player seekToTime:kCMTimeZero];
            } else {
                [_player seekToTime:CMTimeMake(tobeTime, 1)];
            }
        }break;
            
        default:
            break;
    }
}

#pragma mark - 操作
- (void)playVideo {
    [self.player play];
//    self.player.rate = 4; // 播放倍数
}
- (void)pauseVideo {
    [self.player pause];
}
- (void)setIsFullScreen:(BOOL)isFullScreen {
    _isFullScreen = isFullScreen;
    self.playerControlsView.isFullScreen = isFullScreen;
}
- (void)activityShowing:(BOOL)isShow {
    self.playerControlsView.isActivityShowing = isShow;
}

#pragma mark - 缓存较差时候
- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString*, id> *)change context:(nullable void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = _playerItem.status;
        
        switch (status) {
            case AVPlayerItemStatusReadyToPlay: {
                NSLog(@"AVPlayerItemStatusReadyToPlay");
                NSLog(@"正在播放...，视频总长度:%.2f",CMTimeGetSeconds(_playerItem.duration));
                self.playTotalDuration = CMTimeGetSeconds(_playerItem.duration);
                [self activityShowing:YES];
            } break;
                
            case AVPlayerItemStatusUnknown: {
                NSLog(@"AVPlayerItemStatusUnknown");
            } break;
                
            case AVPlayerItemStatusFailed: {
                NSLog(@"AVPlayerItemStatusFailed");
                NSLog(@"%@",_playerItem.error);
            } break;
                
            default: break;
        }
    }
    else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSArray *array = _playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
//        NSLog(@"当前缓冲时间：%f",totalBuffer);
    }
     // playbackLikelyToKeepUp和playbackBufferEmpty是一对，用于监听缓存足够播放的状态
    else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        // 当无缓冲视频数据时
        if (self.playerItem.playbackBufferEmpty) {
            NSLog(@"playbackBufferEmpty 无可播放视频缓存");
            [self pauseVideo];
            [self activityShowing:YES];
        }
    }
    else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        // 当视频缓冲好时
        // 播放
        if (self.playerItem.playbackLikelyToKeepUp) {
            [self playVideo];
             NSLog(@"playbackLikelyToKeepUp 可播放视频缓存");
            [self activityShowing:NO];
        }
    }
}
/** 视频播放结束事件监听 */
- (void)videoDidPlayToEnd:(NSNotification *)notify {
    if (_configuration.repeatPlay) {
        // 重新播放
    } else {
        // 暂停播放
    }
}

#pragma mark - set
/** 根据playerItem，来添加移除观察者 */
- (void)setPlayerItem:(AVPlayerItem *)playerItem {
    if (_playerItem == playerItem) {return;}
    
    if (_playerItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [_playerItem removeObserver:self forKeyPath:@"status"];
        [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [_playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [_playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    }
    _playerItem = playerItem;
    if (playerItem) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil]; // 播放结束通知
        [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        // 缓冲区空了，需要等待数据
        [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
        // 缓冲区有足够数据可以播放了
        [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    }
}
#pragma mark - 全屏旋转
- (void)addOrientationChangedNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
}
/** 屏幕翻转监听事件 */
- (void)orientationChanged:(NSNotification *)notify {
    if (_configuration.shouldAutorotate) {
        [self orientationAspect];
    }
}
- (void)orientationAspect {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    switch (orientation) {
        case UIDeviceOrientationLandscapeLeft: {
            if (!_isFullScreen) {
                [self videoZoomInWithDirection:UIInterfaceOrientationLandscapeRight];
            }
        } break;
        case UIDeviceOrientationLandscapeRight: {
            if (!_isFullScreen) {
                [self videoZoomInWithDirection:UIInterfaceOrientationLandscapeLeft];
            }
        } break;
        case UIDeviceOrientationPortrait: { // 直立
            if (_isFullScreen) {
                 [self videoZoomOut];
            }
        } break;
        default: break;
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
    // 状态栏动画持续时间
    CGFloat duration = [[UIApplication sharedApplication] statusBarOrientationAnimationDuration];
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
    CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:NO];
    
    [UIView animateWithDuration:duration animations:^{
        self.transform = CGAffineTransformIdentity; //清除变形
    } completion:^(BOOL finished) {
    }];
    self.frame = _originalRect;
    [_originalSuperview addSubview:self];
    [self setNeedsLayout];
    [self layoutIfNeeded];
    self.isFullScreen = NO;
}

@end
