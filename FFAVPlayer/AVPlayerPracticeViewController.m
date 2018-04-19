//
//  AVPlayerPracticeViewController.m
//  FFAVPlayer
//
//  Created by cts on 2018/4/18.
//  Copyright © 2018年 cts. All rights reserved.
//

#import "AVPlayerPracticeViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface AVPlayerPracticeViewController ()
@property (nonatomic, nullable, strong) AVPlayer *player;
@property (nonatomic, nullable, strong) UIButton *playOrPause;//播放/暂停按钮
@property (nonatomic, nullable, strong) UIProgressView *progress;//播放进度
@property (strong, nonatomic)AVPlayerItem *item;//播放单元
@property (nonatomic, nullable, strong) AVPlayerLayer *playerLayer;

@property (nonatomic ,strong)  id timeObser;

@end
#define kScreenSize           [[UIScreen mainScreen] bounds].size
#define kScreenWidth          [[UIScreen mainScreen] bounds].size.width
#define kScreenHeight         [[UIScreen mainScreen] bounds].size.height

@implementation AVPlayerPracticeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self setupUI];
    [self.player play];
    
    [self addNotification];
    // self.player.rate = 1.5;//注意更改播放速度要在视频开始播放之后才会生效
}

- (void)viewWillLayoutSubviews {
    self.playerLayer.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    self.progress.frame = CGRectMake(20, kScreenHeight - 20, kScreenWidth-40, 20);
}
-(void)dealloc{
    [self removeObserverFromPlayerItem:self.player.currentItem];
    [self removeNotification];
}
- (void)setupUI {
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity=AVLayerVideoGravityResizeAspect;//视频填充模式
    [self.view.layer addSublayer:self.playerLayer];
    [self.view addSubview:self.progress];
}
/**
 *  给AVPlayerItem添加监控
 *
 *  @param playerItem AVPlayerItem对象
 */
-(void)addObserverToPlayerItem:(AVPlayerItem *)playerItem{
    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监控网络加载情况属性
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
}
/**
 *  通过KVO监控播放器状态
 *
 *  @param keyPath 监控属性
 *  @param object  监视器
 *  @param change  状态改变
 *  @param context 上下文
 */
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    AVPlayerItem *playerItem=object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status= [[change objectForKey:@"new"] intValue];
        if(status==AVPlayerStatusReadyToPlay){
            NSLog(@"正在播放...，视频总长度:%.2f",CMTimeGetSeconds(playerItem.duration));
        }
    }else if([keyPath isEqualToString:@"loadedTimeRanges"]){
        NSArray *array=playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
        NSLog(@"共缓冲：%.2f",totalBuffer);
    }
}
#pragma mark - 监控
/**
 *  给播放器添加进度更新
 */
-(void)addProgressObserver{
    AVPlayerItem *playerItem=self.player.currentItem;
    UIProgressView *progress=self.progress;
    //    UISlider *slider = self.slider;
    //这里设置每秒执行一次
    _timeObser = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current=CMTimeGetSeconds(time);
        float total=CMTimeGetSeconds([playerItem duration]);
        NSLog(@"🖨当前已经播放%.2fs.",current);
        if (current) {
            [progress setProgress:(current/total) animated:YES];
            //            slider.value = (float)(current/total);
        }
    }];
}

/**
 *  根据视频索引取得AVPlayerItem对象
 *
 *  @param videoIndex 视频顺序索引
 *
 *  @return AVPlayerItem对象
 */
-(AVPlayerItem *)getPlayItem:(int)videoIndex{
    NSURL *url = [NSURL URLWithString:@"http://111.26.155.64/v.cctv.com/flash/mp4video6/TMS/2011/01/05/cf752b1c12ce452b3040cab2f90bc265_h264818000nero_aac32-1.mp4"];
    AVPlayerItem *playerItem=[AVPlayerItem playerItemWithURL:url];
    return playerItem;
}

/**
 *  播放完成通知
 *
 *  @param notification 通知对象
 */
-(void)playbackFinished:(NSNotification *)notification{
    NSLog(@"视频播放完成.");
}

-(void)removeObserverFromPlayerItem:(AVPlayerItem *)playerItem{
    [playerItem removeObserver:self forKeyPath:@"status"];
    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.player removeTimeObserver:_timeObser];
}

#pragma mark -
// 让视频从指定处播放
- (void)avSliderAction {
    int64_t value = 10000;
    int32_t preferredTimeScale = 600;
    CMTime startTime = CMTimeMake(value, preferredTimeScale);
    //让视频从指定处播放
    [self.player seekToTime:startTime completionHandler:^(BOOL finished) {
        if (finished) {
            [self.player play];
        }
    }];
    
    //让视频从指定的CMTime对象处播放。
//    CMTime startTime = CMTimeMakeWithSeconds(seconds, self.item.currentTime.timescale);
   
//    CMTimeShow(inTime);
//    OUTPUT: {10000/600 = 16.667}
//    代表时间为16.667s, 视频一共1000帧，每秒600帧
    //让视频从指定处播放
    //    [self.player seekToTime:startTime completionHandler:^(BOOL finished) {
    //        if (finished) {
    //           [self.player play];
    //        }
    //    }];
   
}
#pragma mark - 通知
/**
 *  添加播放器通知
 */
-(void)addNotification{
    //给AVPlayerItem添加播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}

-(void)removeNotification{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - set & get
/**
 *  初始化播放器
 *
 *  @return 播放器对象
 */
-(AVPlayer *)player{
    if (!_player) {
        AVPlayerItem *playerItem=[self getPlayItem:0];
        self.item = playerItem;
        _player=[AVPlayer playerWithPlayerItem:playerItem];
        [self addProgressObserver];
        [self addObserverToPlayerItem:playerItem];
    }
    return _player;
}

- (UIProgressView *)progress {
    if (_progress == nil) {
        _progress = [UIProgressView new];
    }
    return _progress;
}

#pragma nmark -
/**
 AVPlayer 本身不能显示视频，如果要显示必须创建一个播放层AVPlayerLayer用于展示，播放层继承与CALayer。有了AVPlayerLayer之添加到控制器视图的layer中即可。要使用AVPlayer首先了解一下几个常用的类：
     AVAsset：主要用你与获取多媒体信息。
     AVURLAsset：AVAsset子类，可根据一个URL路径常见一个包含媒体信息的AVURLAsset对象。
     AVPlayerItem：一个媒体资源管理对象，管理者视频的一些基本信息和状态。一个AVPlayerItem对应着一个视频资源。
 
 - addPeriodicTimeObserverForInterval
 - removeTimeObserver
 给AVPlayer添加time Observer 有利于我们去检测播放进度
 但是添加以后一定要记得移除，其实不移除程序不会崩溃，但是这个线程是不会释放的，会占用你大量的内存资源
 
 */

@end
