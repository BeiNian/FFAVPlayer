//
//  FFPlayerConfiguration.m
//  FFAVPlayer
//
//  Created by cts on 2018/4/28.
//  Copyright © 2018年 cts. All rights reserved.
//

#import "FFPlayerConfiguration.h"

@implementation FFPlayerConfiguration
/**
 初始化 设置缺省值
 */
- (instancetype)init
{
    self = [super init];
    if (self) {
        _hideControlsInterval = 5.0f;
    }
    return self;
}
@end
