//
//  DCPhotoBrower.m
//  DCPhotoBrower
//
//  Created by 陈舟为 on 2017/4/10.
//  Copyright © 2017年 DaveChen. All rights reserved.
//

#import "DCPhotoBrower.h"

#import "UIView+DCPhotoBrower.h"

#import "UIScrollView+DCPhotoBrower.h"

#import "CALayer+DCPhotoBrower.h"

#import "UIImageView+WebCache.h"

#define kPadding 20
#define kHiColor [UIColor colorWithRGBHex:0x2dd6b8]
#ifndef DC_CLAMP
#define DC_CLAMP(_x_, _low_, _high_)  (((_x_) > (_high_)) ? (_high_) : (((_x_) < (_low_)) ? (_low_) : (_x_)))
#endif


@interface DCPhotoGroupItem()<NSCopying>

@property (nonatomic, readonly) UIImage *thumbImage;
@property (nonatomic, readonly) BOOL	thumbClippedToTop;

- (BOOL)shouldClipToTop:(CGSize)imageSize forView:(UIView *)view;

@end

@implementation DCPhotoGroupItem

- (UIImage *)thumbImage {
    
    if ([_thumbView respondsToSelector:@selector(image)]) {
        return ((UIImageView *)_thumbView).image;
    }
    return nil;
}

- (BOOL)thumbClippedToTop {
    if (_thumbView) {
        if (_thumbView.layer.contentsRect.size.height < 1) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)shouldClipToTop:(CGSize)imageSize forView:(UIView *)view {
    if (imageSize.width < 1 || imageSize.height < 1) return NO;
    if (view.width < 1 || view.height < 1) return NO;
    return imageSize.height / imageSize.width > view.width / view.height;
}

- (id)copyWithZone:(NSZone *)zone {
    DCPhotoGroupItem *item = [self.class new];
    return item;
}

@end



// 单个图片
@interface DCPhotoGroupCell : UIScrollView <UIScrollViewDelegate>

/// 显示图片View
@property (nonatomic, strong) UIView				*imageContainerView;
/// 图片
@property (nonatomic, strong) UIImageView			*imageView;
/// 图片索引
@property (nonatomic, assign) NSInteger				page;
/// 是否显示进度
@property (nonatomic, assign) BOOL					showProgress;
/// 进度百分比
@property (nonatomic, assign) CGFloat				progress;
/// 图层
@property (nonatomic, strong) CAShapeLayer			*progressLayer;
///
@property (nonatomic, strong) DCPhotoGroupItem		*item;
///
@property (nonatomic, readonly) BOOL				itemDidLoad;

- (void)resizeSubviewSize;

@end

@implementation DCPhotoGroupCell


- (instancetype)init {
    self = super.init;
    self.delegate						= self;
    self.bouncesZoom					= YES;
    self.maximumZoomScale				= 3;
    self.multipleTouchEnabled			= YES;
    self.alwaysBounceVertical			= NO;
    self.showsVerticalScrollIndicator	= YES;
    self.showsHorizontalScrollIndicator = NO;
    self.frame = [UIScreen mainScreen].bounds;
    
    _imageContainerView = [UIView new];
    _imageContainerView.clipsToBounds = YES;
    [self addSubview:_imageContainerView];
    
    _imageView = [UIImageView new];
    _imageView.clipsToBounds = YES;
    _imageView.backgroundColor = [UIColor colorWithWhite:1.000 alpha:0.500];
    [_imageContainerView addSubview:_imageView];
    
    // 进度
    _progressLayer = [CAShapeLayer layer];
    _progressLayer.size = CGSizeMake(40, 40);
    _progressLayer.cornerRadius = 20;
    _progressLayer.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.500].CGColor;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(_progressLayer.bounds, 7, 7)
                                                    cornerRadius:(40 / 2 - 7)];
    _progressLayer.path = path.CGPath;
    _progressLayer.fillColor = [UIColor clearColor].CGColor;
    _progressLayer.strokeColor = [UIColor whiteColor].CGColor;
    _progressLayer.lineWidth = 4;
    _progressLayer.lineCap = kCALineCapRound;
    _progressLayer.strokeStart = 0;
    _progressLayer.strokeEnd = 0;
    _progressLayer.hidden = YES;
    [self.layer addSublayer:_progressLayer];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _progressLayer.center = CGPointMake(self.width / 2, self.height / 2);
}

- (void)setItem:(DCPhotoGroupItem *)item {
    if (_item == item) return;
    _item = item;
    _itemDidLoad = NO;
    
    
    [self setZoomScale:1.0 animated:NO];
    self.maximumZoomScale = 1;
    
    //    [_imageView cancelCurrentImageRequest];
    [_imageView.layer removePreviousFadeAnimation];
    
    _progressLayer.hidden = NO;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _progressLayer.strokeEnd = 0;
    _progressLayer.hidden = YES;
    [CATransaction commit];
    
    if (!_item) {
        _imageView.image = nil;
        return;
    }
    
    [_imageView sd_setImageWithURL:item.largeImageURL
                  placeholderImage:item.thumbImage
                           options:SDWebImageRetryFailed
                          progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                              if (!self) return;
                              CGFloat progress = receivedSize / (float)expectedSize;
                              progress = progress < 0.01 ? 0.01 : progress > 1 ? 1 : progress;
                              if (isnan(progress)) progress = 0;
                              self.progressLayer.hidden = NO;
                              self.progressLayer.strokeEnd = progress;
                          } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                              if (!self) return;
                              self.progressLayer.hidden = YES;
                              self.maximumZoomScale = 3;
                              if (image) {
                                  self->_itemDidLoad = YES;
                                  
                                  [self resizeSubviewSize];
                                  [self.imageView.layer addFadeAnimationWithDuration:0.1 curve:UIViewAnimationCurveLinear];
                              }
                          }];
    [self resizeSubviewSize];
}

/// 设置子控件尺寸
- (void)resizeSubviewSize {
    _imageContainerView.origin = CGPointZero;
    _imageContainerView.width  = self.width;
    
    UIImage *image = _imageView.image;
    // 计算图片款高比
    if (image.size.height / image.size.width > self.height / self.width) {
        _imageContainerView.height = floor(image.size.height / (image.size.width / self.width));
    } else {
        CGFloat height = image.size.height / image.size.width * self.width;
        if (height < 1 || isnan(height)) height = self.height;
        height = floor(height);
        _imageContainerView.height = height;
        _imageContainerView.centerY = self.height / 2;
    }
    
    // 高度处理
    if (_imageContainerView.height > self.height && _imageContainerView.height - self.height <= 1) {
        _imageContainerView.height = self.height;
    }
    //
    self.contentSize = CGSizeMake(self.width, MAX(_imageContainerView.height, self.height));
    [self scrollRectToVisible:self.bounds animated:NO];
    
    if (_imageContainerView.height <= self.height) {
        self.alwaysBounceVertical = NO;
    } else {
        self.alwaysBounceVertical = YES;
    }
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _imageView.frame = _imageContainerView.bounds;
    [CATransaction commit];
}

#pragma mark - UIScrollViewDelegate
// 返回缩放完成后的View
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return _imageContainerView;
}
// 缩放
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    UIView *subView = _imageContainerView;
    
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    
    subView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                 scrollView.contentSize.height * 0.5 + offsetY);
}

@end


@interface DCPhotoBrower() <UIScrollViewDelegate, UIGestureRecognizerDelegate,UIActionSheetDelegate>

@property (nonatomic, weak) UIView				*fromView;
@property (nonatomic, weak) UIView				*toContainerView;

@property (nonatomic, strong) UIImage			*snapshotImage;
@property (nonatomic, strong) UIImage			*snapshorImageHideFromView;

@property (nonatomic, strong) UIImageView		*background;					// 背景图片
@property (nonatomic, strong) UIImageView		*blurBackground;

@property (nonatomic, strong) UIView			*contentView;
@property (nonatomic, strong) UIScrollView		*scrollView;
@property (nonatomic, strong) NSMutableArray	*cells;							// 图片数组
@property (nonatomic, strong) UIPageControl		*pager;
@property (nonatomic, assign) CGFloat			pagerCurrentPage;
@property (nonatomic, assign) BOOL				fromNavigationBarHidden;

@property (nonatomic, assign) NSInteger			fromItemIndex;					// 打开索引
@property (nonatomic, assign) BOOL				isPresented;

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, assign) CGPoint panGestureBeginPoint;

@property (nonatomic,weak)UIView *tapView;

@property(nonatomic,assign)NSInteger numberOfPages;

@property(nonatomic,weak)UILabel *countLab;

@end

@implementation DCPhotoBrower


/**
 初始化
 
 */
- (instancetype)initWithGroupImages:(NSArray *)groupItems withTapView:(UIView *)tapView{
    
    self.tapView = tapView;
    
    self.numberOfPages = groupItems.count;
    
    // 1.
    self = [super init];
    if (groupItems.count == 0) return nil;
    
    // 2. 属性
    self.frame				= [UIScreen mainScreen].bounds;
    
    _groupItems 			= groupItems.copy;
    
    self.clipsToBounds		= YES;
    self.backgroundColor	= [UIColor clearColor];
    _dimBackground	= YES;
    
    // 3. 手势
    // 3.1 单击手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(dismiss)];
    tap.delegate = self;
    [self addGestureRecognizer:tap];
    
    // 3.2 双击手势
    UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                           action:@selector(doubleTap:)];
    tap2.delegate = self;
    tap2.numberOfTapsRequired = 2;
    // 指定双击失败触发单击
    [tap requireGestureRecognizerToFail: tap2];
    [self addGestureRecognizer:tap2];
    
    // 3.2 长按手势
    UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(longPress)];
    press.delegate = self;
    [self addGestureRecognizer:press];
    
    // 3.3 拖动
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(pan:)];
    [self addGestureRecognizer:pan];
    _panGesture = pan;
    
    // 4.
    _cells = @[].mutableCopy;
    
    // 背景图片
    _background			= UIImageView.new;
    _background.frame	= self.bounds;
    _background.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // 半透明背景
    _blurBackground			= UIImageView.new;
    _blurBackground.frame	= self.bounds;
    _blurBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // 内容
    _contentView		= UIView.new;
    _contentView.frame	= self.bounds;
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // UIScrollView
    _scrollView					= UIScrollView.new;
    _scrollView.frame			= CGRectMake(-kPadding / 2, 0, self.width + kPadding, self.height);
    _scrollView.delegate		= self;
    _scrollView.scrollsToTop	= NO;
    _scrollView.pagingEnabled	= YES;
    _scrollView.alwaysBounceHorizontal			= groupItems.count > 1;
    _scrollView.showsHorizontalScrollIndicator	= NO;
    _scrollView.showsVerticalScrollIndicator	= NO;
    _scrollView.autoresizingMask		= UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.delaysContentTouches	= NO;
    _scrollView.canCancelContentTouches = YES;
    
    // UIPageControl
    _pager							= [[UIPageControl alloc] init];
    _pager.hidesForSinglePage		= YES;
    _pager.userInteractionEnabled	= NO;
    _pager.width	= self.width - 36;
    _pager.height	= 10;
    _pager.center	= CGPointMake(self.width / 2, self.height - 18);
    _pager.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    [self addSubview:_background];
    [self addSubview:_blurBackground];
    [self addSubview:_contentView];
    [_contentView addSubview:_scrollView];
    [_contentView addSubview:_pager];
    
    // 设置透明颜色
    _blurBackground.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.9];
    
    return self;
}

-(void)show{
    
    UIView *from = self.tapView;
    
    UIView *to = [UIApplication sharedApplication].keyWindow.rootViewController.view;
    
    [self presentFromImageView:from toContainer:to animated:YES completion:nil];
    
}

/**
 显示图片浏览器
 
 @param fromView 打开的View
 @param toContainer 添加到的View
 @param animated 是否动画
 @param completion 完成回调
 */
- (void)presentFromImageView:(UIView *)fromView
                 toContainer:(UIView *)toContainer
                    animated:(BOOL)animated
                  completion:(void (^)(void))completion {
    // 1. 安全判断
    if (!toContainer) return;
    
    // 2. 保存属性
    _fromView		 = fromView;			// 点击的图片
    _toContainerView = toContainer;			// 添加到的图片
    
    // 3. 当前索引
    NSInteger page = -1;
    for (NSUInteger i = 0; i < self.groupItems.count; i++) {
        
        if (fromView == ((DCPhotoGroupItem *)self.groupItems[i]).thumbView) {
            page = (int)i;
            break;
        }
    }
    if (page == -1) page = 0;
    _fromItemIndex = page;
    
    // 3. 快照
    _snapshotImage = [_toContainerView snapshotImageAfterScreenUpdates:NO];
    
    BOOL fromViewHidden = fromView.hidden;
    fromView.hidden = YES;
    _snapshorImageHideFromView = [_toContainerView snapshotImage];
    fromView.hidden = fromViewHidden;
    
    // 4. 背景设置为快照
    _background.image = _snapshorImageHideFromView;
    
    self.size = _toContainerView.size;
    self.blurBackground.alpha = 0;
    self.pager.alpha = 0;
    self.pager.numberOfPages = self.groupItems.count;
    self.pager.currentPage = page;
    
    // 添加
    [_toContainerView addSubview:self];
    
    _scrollView.contentSize = CGSizeMake(_scrollView.width * self.groupItems.count, _scrollView.height);
    [_scrollView scrollRectToVisible:CGRectMake(_scrollView.width * _pager.currentPage, 0,
                                                _scrollView.width, _scrollView.height)
                            animated:NO];
    
    [self scrollViewDidScroll:_scrollView];
    
    [UIView setAnimationsEnabled:YES];
    _fromNavigationBarHidden = [UIApplication sharedApplication].statusBarHidden;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // 状态栏
    [[UIApplication sharedApplication] setStatusBarHidden:YES
                                            withAnimation:animated ?
                                 UIStatusBarAnimationFade: UIStatusBarAnimationNone];
#pragma clang diagnostic pop
    
    
    // 获取当前 cell
    DCPhotoGroupCell *cell = [self cellForPage:self.currentPage];
    DCPhotoGroupItem *item = _groupItems[self.currentPage];
    
    if (!item.thumbClippedToTop) {
        
    }
    if (!cell.item) {
        cell.imageView.image = item.thumbImage;
        [cell resizeSubviewSize];
    }
    
    if (item.thumbClippedToTop) {
        CGRect fromFrame = [_fromView convertRect:_fromView.bounds toView:cell];
        CGRect originFrame = cell.imageContainerView.frame;
        CGFloat scale = fromFrame.size.width / cell.imageContainerView.width;
        
        cell.imageContainerView.centerX = CGRectGetMidX(fromFrame);
        cell.imageContainerView.height = fromFrame.size.height / scale;
        cell.imageContainerView.layer.transformScale = scale;
        cell.imageContainerView.centerY = CGRectGetMidY(fromFrame);
        
        float oneTime = animated ? 0.25 : 0;
        [UIView animateWithDuration:oneTime delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut animations:^{
            _blurBackground.alpha = 1;
        }completion:NULL];
        
        _scrollView.userInteractionEnabled = NO;
        [UIView animateWithDuration:oneTime delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            cell.imageContainerView.layer.transformScale = 1;
            cell.imageContainerView.frame = originFrame;
            _pager.alpha = 1;
        }completion:^(BOOL finished) {
            _isPresented = YES;
            [self scrollViewDidScroll:_scrollView];
            _scrollView.userInteractionEnabled = YES;
            [self hidePager];
            if (completion) completion();
        }];
        
    } else {
        CGRect fromFrame = [_fromView convertRect:_fromView.bounds toView:cell.imageContainerView];
        
        cell.imageContainerView.clipsToBounds = NO;
        cell.imageView.frame = fromFrame;
        cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
        
        float oneTime = animated ? 0.18 : 0;
        [UIView animateWithDuration:oneTime*2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut animations:^{
            _blurBackground.alpha = 1;
        }completion:NULL];
        
        _scrollView.userInteractionEnabled = NO;
        [UIView animateWithDuration:oneTime delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut animations:^{
            cell.imageView.frame = cell.imageContainerView.bounds;
            cell.imageView.layer.transformScale = 1.01;
        }completion:^(BOOL finished) {
            [UIView animateWithDuration:oneTime delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut animations:^{
                cell.imageView.layer.transformScale = 1.0;
                _pager.alpha = 1;
            }completion:^(BOOL finished) {
                cell.imageContainerView.clipsToBounds = YES;
                _isPresented = YES;
                [self scrollViewDidScroll:_scrollView];
                _scrollView.userInteractionEnabled = YES;
                [self hidePager];
                if (completion) completion();
            }];
        }];
    }
}

#pragma mark - 手势方法
//  单击关闭手势
- (void)dismiss {
    [self dismissAnimated:YES completion:nil];
}

- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion {
    [UIView setAnimationsEnabled:YES];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[UIApplication sharedApplication] setStatusBarHidden:_fromNavigationBarHidden withAnimation:animated ? UIStatusBarAnimationFade : UIStatusBarAnimationNone];
#pragma clang diagnostic pop
    
    NSInteger currentPage = self.currentPage;
    DCPhotoGroupCell *cell = [self cellForPage:currentPage];
    DCPhotoGroupItem *item = _groupItems[currentPage];
    
    UIView *fromView = nil;
    if (_fromItemIndex == currentPage) {
        fromView = _fromView;
    } else {
        fromView = item.thumbView;
    }
    
    [self cancelAllImageLoad];
    _isPresented = NO;
    BOOL isFromImageClipped = fromView.layer.contentsRect.size.height < 1;
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    if (isFromImageClipped) {
        CGRect frame = cell.imageContainerView.frame;
        cell.imageContainerView.layer.anchorPoint = CGPointMake(0.5, 0);
        cell.imageContainerView.frame = frame;
    }
    cell.progressLayer.hidden = YES;
    [CATransaction commit];
    
    
    
    
    if (fromView == nil) {
        self.background.image = _snapshotImage;
        [UIView animateWithDuration:animated ? 0.25 : 0 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut animations:^{
            self.alpha = 0.0;
            self.scrollView.layer.transformScale = 0.95;
            self.scrollView.alpha = 0;
            self.pager.alpha = 0;
            self.blurBackground.alpha = 0;
        }completion:^(BOOL finished) {
            self.scrollView.layer.transformScale = 1;
            [self removeFromSuperview];
            [self cancelAllImageLoad];
            if (completion) completion();
        }];
        return;
    }
    
    if (_fromItemIndex != currentPage) {
        _background.image = _snapshotImage;
        [_background.layer addFadeAnimationWithDuration:0.25 curve:UIViewAnimationCurveEaseOut];
    } else {
        _background.image = _snapshorImageHideFromView;
    }
    
    
    if (isFromImageClipped) {
        [cell scrollToTopAnimated:NO];
    }
    
    [UIView animateWithDuration:animated ? 0.2 : 0 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut animations:^{
        _pager.alpha = 0.0;
        _blurBackground.alpha = 0.0;
        if (isFromImageClipped) {
            
            CGRect fromFrame = [fromView convertRect:fromView.bounds toView:cell];
            CGFloat scale = fromFrame.size.width / cell.imageContainerView.width * cell.zoomScale;
            CGFloat height = fromFrame.size.height / fromFrame.size.width * cell.imageContainerView.width;
            if (isnan(height)) height = cell.imageContainerView.height;
            
            cell.imageContainerView.height = height;
            cell.imageContainerView.center = CGPointMake(CGRectGetMidX(fromFrame), CGRectGetMinY(fromFrame));
            cell.imageContainerView.layer.transformScale = scale;
            
        } else {
            CGRect fromFrame = [fromView convertRect:fromView.bounds toView:cell.imageContainerView];
            cell.imageContainerView.clipsToBounds = NO;
            cell.imageView.contentMode = fromView.contentMode;
            cell.imageView.frame = fromFrame;
        }
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:animated ? 0.15 : 0 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished) {
            cell.imageContainerView.layer.anchorPoint = CGPointMake(0.5, 0.5);
            [self removeFromSuperview];
            if (completion) completion();
        }];
    }];
    
    
}

//  双击放大手势
- (void)doubleTap:(UITapGestureRecognizer *)g {
    if (!_isPresented) return;
    DCPhotoGroupCell *tile = [self cellForPage:self.currentPage];
    if (tile) {
        if (tile.zoomScale > 1) {
            [tile setZoomScale:1 animated:YES];
        } else {
            CGPoint touchPoint = [g locationInView:tile.imageView];
            CGFloat newZoomScale = tile.maximumZoomScale;
            CGFloat xsize = self.width / newZoomScale;
            CGFloat ysize = self.height / newZoomScale;
            [tile zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
        }
    }
}

//  长按操作手势
- (void)longPress {
    if (!_isPresented) return;
    
    DCPhotoGroupCell *tile = [self cellForPage:self.currentPage];
    
    if (!tile.imageView.image) return;
    
    
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *sure=[UIAlertAction actionWithTitle:@"保存图片" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self saveWithDetail:tile];
        
    }];
    
    UIAlertAction *cancle=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alert addAction:cancle];
    
    [alert addAction:sure];
    
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    
    
}

//保存图片
-(void)saveWithDetail:(DCPhotoGroupCell *)detail{
    
    UIImage *img = detail.imageView.image;
    
    // 保存图片到相册中（在infoPlist中打开图片保存图片权限）
    UIImageWriteToSavedPhotosAlbum(img,self, @selector(image:didFinishSavingWithError:contextInfo:),nil);
    
}
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error) {
        
        NSLog(@"保存图片失败!");
        
    } else {
        
         NSLog(@"保存图片成功!");

    }
}

//  拖动手势
- (void)pan:(UIPanGestureRecognizer *)g {
    switch (g.state) {
        case UIGestureRecognizerStateBegan: {
            if (_isPresented) {
                _panGestureBeginPoint = [g locationInView:self];
            } else {
                _panGestureBeginPoint = CGPointZero;
            }
        } break;
        case UIGestureRecognizerStateChanged: {
            if (_panGestureBeginPoint.x == 0 && _panGestureBeginPoint.y == 0) return;
            CGPoint p = [g locationInView:self];
            CGFloat deltaY = p.y - _panGestureBeginPoint.y;
            _scrollView.top = deltaY;
            
            CGFloat alphaDelta = 160;
            CGFloat alpha = (alphaDelta - fabs(deltaY) + 50) / alphaDelta;
            alpha = DC_CLAMP(alpha, 0, 1);
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveLinear animations:^{
                _blurBackground.alpha = alpha;
                _pager.alpha = alpha;
            } completion:nil];
            
        } break;
        case UIGestureRecognizerStateEnded: {
            if (_panGestureBeginPoint.x == 0 && _panGestureBeginPoint.y == 0) return;
            CGPoint v = [g velocityInView:self];
            CGPoint p = [g locationInView:self];
            CGFloat deltaY = p.y - _panGestureBeginPoint.y;
            
            if (fabs(v.y) > 1000 || fabs(deltaY) > 120) {
                [self cancelAllImageLoad];
                _isPresented = NO;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                [[UIApplication sharedApplication] setStatusBarHidden:_fromNavigationBarHidden withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
                BOOL moveToTop = (v.y < - 50 || (v.y < 50 && deltaY < 0));
                CGFloat vy = fabs(v.y);
                if (vy < 1) vy = 1;
                CGFloat duration = (moveToTop ? _scrollView.bottom : self.height - _scrollView.top) / vy;
                duration *= 0.8;
                duration = DC_CLAMP(duration, 0.05, 0.3);
                
                [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState animations:^{
                    _blurBackground.alpha = 0;
                    _pager.alpha = 0;
                    if (moveToTop) {
                        _scrollView.bottom = 0;
                    } else {
                        _scrollView.top = self.height;
                    }
                } completion:^(BOOL finished) {
                    [self removeFromSuperview];
                }];
                
                _background.image = _snapshotImage;
                [_background.layer addFadeAnimationWithDuration:0.3 curve:UIViewAnimationCurveEaseInOut];
                
            } else {
                [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:v.y / 1000 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{
                    _scrollView.top = 0;
                    _blurBackground.alpha = 1;
                    _pager.alpha = 1;
                } completion:^(BOOL finished) {
                    
                }];
            }
            
        } break;
        case UIGestureRecognizerStateCancelled : {
            _scrollView.top = 0;
            _blurBackground.alpha = 1;
        }
        default:break;
    }
}

- (void)cancelAllImageLoad {
    [_cells enumerateObjectsUsingBlock:^(DCPhotoGroupCell *cell, NSUInteger idx, BOOL *stop) {
        //        [cell.imageView cancelCurrentImageRequest];
    }];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateCellsForReuse];
    
    CGFloat floatPage = _scrollView.contentOffset.x / _scrollView.width;
    NSInteger page    = _scrollView.contentOffset.x / _scrollView.width + 0.5;
    
    for (NSInteger i = page - 1; i <= page + 1; i++) { // preload left and right cell
        if (i >= 0 && i < self.groupItems.count) {
            
            DCPhotoGroupCell *cell = [self cellForPage:i];
            if (!cell) {
                DCPhotoGroupCell *cell = [self dequeueReusableCell];
                cell.page = i;
                cell.left = (self.width + kPadding) * i + kPadding / 2;
                
                if (_isPresented) {
                    cell.item = self.groupItems[i];
                }
                [self.scrollView addSubview:cell];
            } else {
                if (_isPresented && !cell.item) {
                    cell.item = self.groupItems[i];
                }
            }
        }
    }
    
    NSInteger intPage = floatPage + 0.5;
    intPage = intPage < 0 ? 0 : intPage >= _groupItems.count ? (int)_groupItems.count - 1 : intPage;
    _pager.currentPage = intPage;
    [UIView animateWithDuration:0.3
                          delay:0 
                        options:UIViewAnimationOptionBeginFromCurrentState
     | UIViewAnimationOptionCurveEaseInOut animations:^{
         _pager.alpha = 1;
     }completion:^(BOOL finish) {
     }];
    page = page +1;
    
    self.countLab.text = [NSString stringWithFormat:@"%ld/%ld",page,self.numberOfPages];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (!decelerate) {
        [self hidePager];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self hidePager];
}

- (void)hidePager {
    [UIView animateWithDuration:0.3 delay:0.8 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut animations:^{
        _pager.alpha = 0;
    }completion:^(BOOL finish) {
    }];
}

/// enqueue invisible cells for reuse
- (void)updateCellsForReuse {
    for (DCPhotoGroupCell *cell in _cells) {
        if (cell.superview) {
            if (cell.left > _scrollView.contentOffset.x + _scrollView.width * 2||
                cell.right < _scrollView.contentOffset.x - _scrollView.width) {
                [cell removeFromSuperview];
                cell.page = -1;
                cell.item = nil;
            }
        }
    }
}

/// 创建 一个 cell
- (DCPhotoGroupCell *)dequeueReusableCell {
    DCPhotoGroupCell *cell = nil;
    for (cell in _cells) {
        if (!cell.superview) {
            return cell;
        }
    }
    
    cell = [DCPhotoGroupCell new];
    cell.frame = self.bounds;
    cell.imageContainerView.frame = self.bounds;
    cell.imageView.frame = cell.bounds;
    cell.page = -1;
    cell.item = nil;
    [_cells addObject:cell];
    return cell;
}

#pragma mark - Private Methond

- (DCPhotoGroupCell *)cellForPage:(NSInteger)page {
    for (DCPhotoGroupCell *cell in _cells) {
        if (cell.page == page) {
            return cell;
        }
    }
    return nil;
}

// 获取当前索引
- (NSInteger)currentPage {
    NSInteger page = _scrollView.contentOffset.x / _scrollView.width + 0.5;
    if (page >= _groupItems.count) page = (NSInteger)_groupItems.count - 1;
    if (page < 0) page = 0;
    return page;
}

-(void)showIndexWithNumber{
    
    _pager.hidden = YES;
    
    UILabel *countLab = [[UILabel alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width -60)/2, 20, 60, 20)];
    
    countLab.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.4];
    
    countLab.layer.cornerRadius = 10;
    
    countLab.layer.masksToBounds = YES;
    
    countLab.textAlignment = 1;
    
    countLab.font = [UIFont boldSystemFontOfSize:18];
    
    countLab.textColor = [UIColor whiteColor];
    
    [self addSubview:countLab];
    
    self.countLab = countLab;
    
}

-(void)closePanGestureRecognizer{
    
    _panGesture.enabled = NO;
    
}

@end
