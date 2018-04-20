//
//  ViewController.m
//  FFAVPlayer
//
//  Created by cts on 2018/4/18.
//  Copyright © 2018年 cts. All rights reserved.
//

#import "ViewController.h"
#import "FFPlayerViewController.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}
- (IBAction)AVPlayerPractice:(UIButton *)sender { 
    FFPlayerViewController *playerPractice = [[FFPlayerViewController alloc] init];
    [self.navigationController pushViewController:playerPractice animated:YES];
}




@end
