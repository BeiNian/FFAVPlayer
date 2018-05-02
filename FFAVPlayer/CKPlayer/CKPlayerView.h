//
//  CKPlayerView.h
//  FFAVPlayer
//
//  Created by cts on 2018/5/2.
//  Copyright © 2018年 cts. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CKPlayerConfiguration.h"

@interface CKPlayerView : UIView
/**
 初始化播放器
 @param configuration 播放器配置信息
 */
- (instancetype)initWithFrame:(CGRect)frame configuration:(CKPlayerConfiguration *)configuration;
@end
