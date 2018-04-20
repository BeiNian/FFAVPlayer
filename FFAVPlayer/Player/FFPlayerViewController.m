//
//  FFPlayerViewController.m
//  FFAVPlayer
//
//  Created by cts on 2018/4/20.
//  Copyright © 2018年 cts. All rights reserved.
//

#import "FFPlayerViewController.h"
#import "FFPlayerView.h"
@interface FFPlayerViewController ()<FFPlayerViewDelegate>
@property (nonatomic, nullable, strong) FFPlayerView *playerView;
@end

@implementation FFPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    NSString *path = @"http://static.tripbe.com/videofiles/20121214/9533522808.f4v.mp4";
    @autoreleasepool {
        _playerView = [[FFPlayerView alloc] initWithUrl:path delegate:self];
        _playerView.delegate = self;
        _playerView.frame = self.view.bounds;
        [self.view addSubview:_playerView];
    }
}
- (void)dealloc {
    [_playerView stop];
}
#pragma mark - FFPlayerViewDelegate
- (void)flushCurrentTime:(NSString *)timeString sliderValue:(float)sliderValue {
//    NSLog(@"🖨当前已经播放%@s.  sliderValue = %.2f",timeString,sliderValue);

}

@end
