//
//  FFPlayerView.h
//  FFAVPlayer
//
//  Created by cts on 2018/4/20.
//  Copyright © 2018年 cts. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol FFPlayerViewDelegate <NSObject>
@required

- (void)flushCurrentTime:(NSString *)timeString sliderValue:(float)sliderValue;

@end

@interface FFPlayerView : UIView

@property (nonatomic ,weak) id <FFPlayerViewDelegate> delegate;
@property (nonatomic, copy) NSString *playerUrl;
- (void)stop;


- (id)initWithUrl:(NSString *)url delegate:(id<FFPlayerViewDelegate>)delegate;
@end

@interface FFPlayerView  (Guester)

- (void)addSwipeView;

@end
