//
//  CALayer+DCPhotoBrower.h
//  DCPhotoBrower
//
//  Created by 陈舟为 on 2017/4/10.
//  Copyright © 2017年 DaveChen. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import <UIKit/UIKit.h>

@interface CALayer (DCPhotoBrower)


@property (nonatomic) CGFloat left;

@property (nonatomic) CGFloat top;

@property (nonatomic) CGFloat right;

@property (nonatomic) CGFloat bottom;

@property (nonatomic) CGFloat width;

@property (nonatomic) CGFloat height;

@property (nonatomic) CGPoint center;

@property (nonatomic) CGFloat centerX;

@property (nonatomic) CGFloat centerY;

@property (nonatomic) CGPoint origin;

@property (nonatomic, getter=frameSize, setter=setFrameSize:) CGSize  size;

@property (nonatomic) CGFloat transformRotation;

@property (nonatomic) CGFloat transformRotationX;

@property (nonatomic) CGFloat transformRotationY;

@property (nonatomic) CGFloat transformRotationZ;

@property (nonatomic) CGFloat transformScale;

@property (nonatomic) CGFloat transformScaleX;

@property (nonatomic) CGFloat transformScaleY;

@property (nonatomic) CGFloat transformScaleZ;

@property (nonatomic) CGFloat transformTranslationX;

@property (nonatomic) CGFloat transformTranslationY;

@property (nonatomic) CGFloat transformTranslationZ;

- (void)addFadeAnimationWithDuration:(NSTimeInterval)duration curve:(UIViewAnimationCurve)curve;

- (void)removePreviousFadeAnimation;

@end
