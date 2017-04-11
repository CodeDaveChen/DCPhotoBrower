//
//  DCPhotoBrower.h
//  DCPhotoBrower
//
//  Created by 陈舟为 on 2017/4/10.
//  Copyright © 2017年 DaveChen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DCPhotoGroupItem : NSObject

@property (nonatomic, strong) UIView	*thumbView;
@property (nonatomic, assign) CGSize	largeImageSize;
@property (nonatomic, strong) NSURL		*largeImageURL;

@end


@interface DCPhotoBrower : UIView

@property (nonatomic, readonly) NSArray		*groupItems;
@property (nonatomic, readonly) NSInteger	currentPage;
@property (nonatomic, assign)	BOOL		dimBackground;


- (instancetype)initWithGroupImages:(NSArray *)imageItems withTapView:(UIView *)tapView;

-(void)show;

//显示数字索引
-(void)showIndexWithNumber;

//关闭拖拽手势
-(void)closePanGestureRecognizer;

@end
