//
//  CKPlayerControlsView.h
//  FFAVPlayer
//
//  Created by cts on 2018/5/2.
//  Copyright © 2018年 cts. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CKPlayerConfiguration.h"

/** 播放器控制面板代理 */
@protocol CKPlayerControlsDelegate <NSObject>
@required
- (void)playerSeekToTime:(CGFloat)toTime ChangeCMTime:(CKChangeCMTime)changeCMTime;
@optional

@end


@interface CKPlayerControlsView : UIView
@property (nonatomic, weak) id <CKPlayerControlsDelegate>delegate;
@property (nonatomic, assign) BOOL isFullScreen;// 是否处于全屏状态

@property (nonatomic, strong) UIButton *controlButton; // 控制按钮
@property (nonatomic, strong) UILabel *playDuration; // 播放时间
@property (nonatomic, strong) UILabel *playTotalDuration; // 播放总时长
@property (nonatomic, strong) UIButton *fullScreenButton; // 全屏操作按钮

/**
 设置视频时间显示以及滑杆状态
 @param playTime 当前播放时间
 @param totalTime 视频总时间
 @param sliderValue 滑杆滑动值
 */
- (void)setPlaybackControlsWithPlayTime:(NSInteger)playTime totalTime:(NSInteger)totalTime sliderValue:(CGFloat)sliderValue;
@end
