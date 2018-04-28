//
//  ViewController.m
//  FFAVPlayer
//
//  Created by cts on 2018/4/18.
//  Copyright © 2018年 cts. All rights reserved.
//

#import "ViewController.h"
#import "FFPlayerViewController.h"
#import "UIImage+Format.h"
#import "SelPlayerConfiguration.h"
#import "SelVideoPlayer.h"


@interface ViewController ()

@property (nonatomic, strong) SelVideoPlayer *player;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
//
//    if ([[UIDevice currentDevice].systemVersion floatValue] > 7.0) {
//        self.edgesForExtendedLayout = UIRectEdgeNone;
//    }
//    SelPlayerConfiguration *configuration = [[SelPlayerConfiguration alloc]init];
//    configuration.shouldAutoPlay = YES;
//    configuration.supportedDoubleTap = YES;
//    configuration.shouldAutorotate = YES;
//    configuration.repeatPlay = YES;
//    configuration.statusBarHideState = SelStatusBarHideStateFollowControls;
//    configuration.sourceUrl = [NSURL URLWithString:@"http://120.25.226.186:32812/resources/videos/minion_02.mp4"];
//    configuration.videoGravity = SelVideoGravityResizeAspect;
//
//    CGFloat width = self.view.frame.size.width;
//    _player = [[SelVideoPlayer alloc]initWithFrame:CGRectMake(0, 100, width, 300) configuration:configuration];
//    [self.view addSubview:_player];
    
//
//    UIImageView *imageView = [UIImageView  new];
//    imageView.frame = CGRectMake(0, 100, 100, 100);
//    imageView.image = [UIImage getVideoPreViewImage:[NSURL URLWithString:@"http://static.tripbe.com/videofiles/20121214/9533522808.f4v.mp4"]];
//    [self.view addSubview:imageView];
    
}
- (IBAction)AVPlayerPractice:(UIButton *)sender { 
    FFPlayerViewController *playerPractice = [[FFPlayerViewController alloc] init];
    [self.navigationController pushViewController:playerPractice animated:YES];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event  {
    FFPlayerViewController *playerPractice = [[FFPlayerViewController alloc] init];
    [self.navigationController pushViewController:playerPractice animated:YES];
}


@end
