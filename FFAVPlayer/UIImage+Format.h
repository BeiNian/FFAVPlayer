//
//  UIImage+Format.h
//  FFAVPlayer
//
//  Created by cts on 2018/4/28.
//  Copyright © 2018年 cts. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Format)
// 获取视频第一帧
+ (UIImage*) getVideoPreViewImage:(NSURL *)path;
@end
