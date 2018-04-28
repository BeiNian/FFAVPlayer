//
//  FFVideoPlayerView.h
//  FFAVPlayer
//
//  Created by cts on 2018/4/28.
//  Copyright © 2018年 cts. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FFPlayerConfiguration.h"

@interface FFVideoPlayerView : UIView
/**
 初始化播放器
 @param configuration 播放器配置信息
 */
- (instancetype)initWithFrame:(CGRect)frame configuration:(FFPlayerConfiguration *)configuration;
@end
