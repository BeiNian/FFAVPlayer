//
//  CKPlayerConfiguration.m
//  FFAVPlayer
//
//  Created by cts on 2018/5/2.
//  Copyright © 2018年 cts. All rights reserved.
//

#import "CKPlayerConfiguration.h"

@implementation CKPlayerConfiguration
/**
 初始化 设置缺省值
 */
- (instancetype)init
{
    self = [super init];
    if (self) {
        _hideControlsInterval = 5.0f;
        _showControls = YES;
    }
    return self;
}

@end
