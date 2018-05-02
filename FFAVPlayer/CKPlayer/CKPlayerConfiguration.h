//
//  CKPlayerConfiguration.h
//  FFAVPlayer
//
//  Created by cts on 2018/5/2.
//  Copyright © 2018年 cts. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CKPlayerChange) {
    CKPlayerChangeNone,
    CKPlayerChangeVoice,
    CKPlayerChangeLigth,
    CKPlayerChangeCMTime
};

typedef NS_ENUM(NSUInteger, CKChangeCMTime) {
    CKPlayerUpperCMTime,
    CKPlayerMineCMTime,
};


@interface CKPlayerConfiguration : NSObject
/** 视频数据源 */
@property (nonatomic, strong) NSURL *sourceUrl;
/** 是否自动播放 */
@property (nonatomic, assign) BOOL shouldAutoPlay;
/** 视频拉伸方式 */
//@property (nonatomic, assign) SelVideoGravity videoGravity;
/** 是否重复播放 */
@property (nonatomic, assign) BOOL repeatPlay;
/** 是否支持双击暂停或播放 */
@property (nonatomic, assign) BOOL supportedDoubleTap;
/** 是否支持自动转屏 */
@property (nonatomic, assign) BOOL shouldAutorotate;
/** 隐藏控制面板延时时间 缺省5s */
@property (nonatomic, assign) NSTimeInterval hideControlsInterval;
/** 是否显示控制面板 */
@property (nonatomic, assign) BOOL showControls;

@end
