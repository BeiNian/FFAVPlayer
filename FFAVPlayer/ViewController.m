//
//  ViewController.m
//  FFAVPlayer
//
//  Created by cts on 2018/4/18.
//  Copyright © 2018年 cts. All rights reserved.
//

#import "ViewController.h" 
#import <AVFoundation/AVFoundation.h>
#import "AVPlayerPracticeViewController.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}
- (IBAction)AVPlayerPractice:(UIButton *)sender {
    AVPlayerPracticeViewController *playerPractice = [[AVPlayerPracticeViewController alloc] init];
    [self.navigationController pushViewController:playerPractice animated:YES];
}


@end
