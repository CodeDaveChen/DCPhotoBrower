//
//  UIScrollView+DCPhotoBrower.m
//  DCPhotoBrower
//
//  Created by 陈舟为 on 2017/4/10.
//  Copyright © 2017年 DaveChen. All rights reserved.
//

#import "UIScrollView+DCPhotoBrower.h"

@implementation UIScrollView (DCPhotoBrower)

- (void)scrollToTopAnimated:(BOOL)animated {
    CGPoint off = self.contentOffset;
    off.y = 0 - self.contentInset.top;
    [self setContentOffset:off animated:animated];
}


@end
