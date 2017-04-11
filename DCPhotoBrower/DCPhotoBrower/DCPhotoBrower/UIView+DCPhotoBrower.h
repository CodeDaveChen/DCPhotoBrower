//
//  UIView+DCPhotoBrower.h
//  DCPhotoBrower
//
//  Created by 陈舟为 on 2017/4/10.
//  Copyright © 2017年 DaveChen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (DCPhotoBrower)

@property (nonatomic) CGFloat left;

@property (nonatomic) CGFloat top;

@property (nonatomic) CGFloat right;

@property (nonatomic) CGFloat bottom;

@property (nonatomic) CGFloat width;

@property (nonatomic) CGFloat height;

@property (nonatomic) CGFloat centerX;

@property (nonatomic) CGFloat centerY;

@property (nonatomic) CGPoint origin;

@property (nonatomic) CGSize  size;

- (nullable UIImage *)snapshotImage;

- (nullable UIImage *)snapshotImageAfterScreenUpdates:(BOOL)afterUpdates;

@property (nullable, nonatomic, readonly) UIViewController *viewController;

@end
