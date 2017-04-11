//
//  ViewController.m
//  DCPhotoBrower
//
//  Created by 陈舟为 on 2017/4/1.
//  Copyright © 2017年 DaveChen. All rights reserved.
//

#import "ViewController.h"

#import "DCPhotoBrower.h"

#import "UIImageView+WebCache.h"

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray	*itemArray;
@property (nonatomic, strong) NSArray			*images;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.images = @[
                    @"http://www.sznews.com/ent/images/attachement/jpg/site3/20140128/001e4f9d7bf914513fca04.jpg",
                    @"http://img1.gtimg.com/ent/pics/hv1/147/12/1499/97475682.jpg",
                    @"http://mat1.gtimg.com/ent/000000000000000000/zhangzhangbobo.jpg",
                    @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1491881920249&di=0ad55b5fb4e904c65b4127ab78c92567&imgtype=0&src=http%3A%2F%2Fimg17.3lian.com%2Fd%2Ffile%2F201701%2F23%2F5d3652c09418781509ce62268de896cc.jpg",
                    @"http://ww3.sinaimg.cn/mw690/006cTjnOjw1f3zcxgau0ij30b46e7am0.jpg"
                    
                         ];
    

    
    [self setupView];
    
}

- (void)setupView {
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.itemArray = [NSMutableArray array];
    
    CGFloat margin = 10;
    CGFloat item_W = ([UIScreen mainScreen].bounds.size.width-4* 10)/3;
    CGFloat item_X = 10;
    CGFloat item_Y = 40;
    
    for (int i = 0; i < self.images.count; i++) {
        
        NSInteger lineNumber = i / 3;
        NSInteger listNumber = i % 3;
        
        CGFloat itemX = item_X + (item_W + margin) * listNumber;
        CGFloat itemY = item_Y + (item_W + margin) * lineNumber;
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(itemX, itemY, item_W, item_W)];
        imageView.backgroundColor = [UIColor lightGrayColor];
        imageView.userInteractionEnabled = YES;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        UITapGestureRecognizer *singleTap =
        [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clickImage:)];
        [imageView addGestureRecognizer:singleTap];
        
        [imageView sd_setImageWithURL:[NSURL URLWithString:self.images[i]] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        }];
        
        //这里将UIImageView加入可变数组
        [self.itemArray addObject:imageView];
        
        [self.view addSubview:imageView];
    }
    
}

// 点击图片
- (void)clickImage:(UIGestureRecognizer *)gesture {
    
    NSMutableArray *items = [NSMutableArray array];
    
    for (int i = 0; i < self.images.count; i++) {
        NSString *urlString = self.images[i];
        //拿到创建的UIImageView
        UIImageView *imageView = self.itemArray[i];
        //创建DCPhotoGroupItem
        DCPhotoGroupItem *item	= [[DCPhotoGroupItem alloc] init];
        item.thumbView = imageView;
        item.largeImageURL = [NSURL URLWithString:urlString];
        [items addObject:item];
    }
    
    
    DCPhotoBrower *photoBrower = [[DCPhotoBrower alloc] initWithGroupImages:items withTapView:gesture.view];
    
    [photoBrower show];
    
    //索引显示方式 （不调用默认小圆点显示索引）
    [photoBrower showIndexWithNumber];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
