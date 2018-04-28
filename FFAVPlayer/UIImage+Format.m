//
//  UIImage+Format.m
//  FFAVPlayer
//
//  Created by cts on 2018/4/28.
//  Copyright © 2018年 cts. All rights reserved.
//

#import "UIImage+Format.h"
#import <AVFoundation/AVFoundation.h>

@implementation UIImage (Format)

// 获取视频第一帧
+ (UIImage*) getVideoPreViewImage:(NSURL *)path
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:path options:nil];
    AVAssetImageGenerator *assetGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    assetGen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [assetGen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *videoImage = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return videoImage;
}
@end
