//
//  FFPlayerViewController.m
//  FFAVPlayer
//
//  Created by cts on 2018/4/20.
//  Copyright © 2018年 cts. All rights reserved.
//

#import "FFPlayerViewController.h"
#import "FFPlayerView.h"
#import "FFVideoPlayerView.h"


@interface FFPlayerViewController ()<FFPlayerViewDelegate>
@property (nonatomic, nullable, strong) FFPlayerView *playerView;
@property (nonatomic, nullable, strong) FFVideoPlayerView *player;

@end

@implementation FFPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    FFPlayerConfiguration *configuration = [[FFPlayerConfiguration alloc]init];
        configuration.shouldAutoPlay = YES;
        configuration.supportedDoubleTap = YES;
        configuration.shouldAutorotate = YES;
        configuration.repeatPlay = YES;
        configuration.sourceUrl = [NSURL URLWithString:@"http://static.tripbe.com/videofiles/20121214/9533522808.f4v.mp4"];
    
        CGFloat width = self.view.frame.size.width;
        _player = [[FFVideoPlayerView alloc]initWithFrame:CGRectMake(0, 100, width, 300) configuration:configuration];
        [self.view addSubview:_player];
    
    
    
    
//        NSString *path = @"http://static.tripbe.com/videofiles/20121214/9533522808.f4v.mp4";
//        @autoreleasepool {
//            _playerView = [[FFPlayerView alloc] initWithUrl:path delegate:self];
//            _playerView.delegate = self;
//            _playerView.frame = self.view.bounds;
//            [self.view addSubview:_playerView];
//        }
    
}
- (void)dealloc {
    [_playerView stop];
}
#pragma mark - FFPlayerViewDelegate
- (void)flushCurrentTime:(NSString *)timeString sliderValue:(float)sliderValue {
    NSLog(@"🖨当前已经播放%@s.  sliderValue = %.2f",timeString,sliderValue);

}

@end
