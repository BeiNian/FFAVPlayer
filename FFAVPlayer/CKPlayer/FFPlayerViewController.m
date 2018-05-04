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
#import "CKPlayerView.h"


@interface FFPlayerViewController ()  
@property (nonatomic, nullable, strong) CKPlayerView *player;

@end

@implementation FFPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    CKPlayerConfiguration *configuration = [[CKPlayerConfiguration alloc]init];
        configuration.shouldAutoPlay = YES;
        configuration.supportedDoubleTap = YES;
        configuration.shouldAutorotate = YES;
        configuration.repeatPlay = YES;
        configuration.sourceUrl = [NSURL URLWithString:@"http://static.tripbe.com/videofiles/20121214/9533522808.f4v.mp4"];
    
        CGFloat width = self.view.frame.size.width;
        _player = [[CKPlayerView alloc]initWithFrame:CGRectMake(0, 100, width, 300) configuration:configuration];
        [self.view addSubview:_player]; 
}
- (void)dealloc {
   
}

@end
