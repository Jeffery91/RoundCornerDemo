//
//  ViewController.m
//  RoundCornerDemo
//
//  Created by 张剑飞 on 16/5/4.
//  Copyright © 2016年 tjuzjf. All rights reserved.
//

#import "ViewController.h"

static NSString * const kIdentifier = @"identifier";

@implementation UIImage (RoundedCorner)

- (UIImage *)drawCircleImage {
    CGFloat side = MIN(self.size.width, self.size.height);
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(side, side), false, [UIScreen mainScreen].scale);
    CGContextAddPath(UIGraphicsGetCurrentContext(),
                     [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, side, side)].CGPath);
    CGContextClip(UIGraphicsGetCurrentContext());
    CGFloat marginX = -(self.size.width - side) / 2.f;
    CGFloat marginY = -(self.size.height - side) / 2.f;
    [self drawInRect:CGRectMake(marginX, marginY, self.size.width, self.size.height)];
    CGContextDrawPath(UIGraphicsGetCurrentContext(), kCGPathFillStroke);
    UIImage *output = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return output;
}

@end

@interface ViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@end

@implementation ViewController

+ (CGFloat)cellHMargin {
    CGSize winSize = [UIScreen mainScreen].bounds.size;
    return (winSize.width - [self imageSize].width * 3) / 4;
}

+ (CGFloat)cellVMargin {
    return 25;
}

+ (CGSize)imageSize {
    return CGSizeMake(80, 80);
}

+ (CGSize)cellSize {
    CGFloat width = [self cellHMargin] + [self imageSize].width;
    CGFloat height = [self cellVMargin] + [self imageSize].height;
    return CGSizeMake(width, height);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGSize winSize = [UIScreen mainScreen].bounds.size;
    CGFloat offset = 30;
    CGRect collectRect = CGRectMake(0, offset, winSize.width, winSize.height - offset);
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    layout.itemSize = [ViewController cellSize];
    
    UICollectionView *colloect = [[UICollectionView alloc] initWithFrame:collectRect
                                                    collectionViewLayout:layout];
    [colloect registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kIdentifier];
    //背景色和cover图片的圆角颜色相同
    colloect.backgroundColor = [UIColor colorWithRed:240/255.f green:240/255.f blue:240/255.f alpha:1];
    colloect.delegate = self;
    colloect.dataSource = self;
    
    [self.view addSubview:colloect];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setCorner:(UIImageView *)view {
    CGSize imgSize = view.bounds.size;
    int flag = 1;
    switch (flag) {
        case 0: {
            //没有圆角
            ;
        }
            break;
        case 1: {
            //cornerRadius圆角
            view.layer.masksToBounds = YES;
            view.layer.cornerRadius = imgSize.width / 2;
        }
            break;
        case 2: {
            //mask圆角
            CAShapeLayer *layer = [CAShapeLayer layer];
            UIBezierPath *aPath = [UIBezierPath bezierPathWithOvalInRect:view.bounds];
            layer.path = aPath.CGPath;
            view.layer.mask = layer;
        }
            break;
        case 3: {
            //重新绘制圆角
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage *image = view.image;
                image = [image drawCircleImage];
                dispatch_async(dispatch_get_main_queue(), ^{
                    view.image = image;
                });
            });
        }
            break;
        case 4: {
            //混合图层
            UIView *parent = [view superview];
            UIImageView *cover = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, imgSize.width, imgSize.height)];
            cover.image = [UIImage imageNamed:@"cover"];
            [parent addSubview:cover];
            cover.center = view.center;
        }
            break;
    }
}

#pragma mark -

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 80;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kIdentifier forIndexPath:indexPath];
    static const NSInteger tag = 0x11;
    UIImageView *view = [cell.contentView viewWithTag:tag];
    if (!view) {
        CGSize imgSize = [self.class imageSize];
        view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, imgSize.width, imgSize.height)];
        view.image = [UIImage imageNamed:@"img"];
        view.tag = tag;
        [cell.contentView addSubview:view];
        view.center = CGPointMake(CGRectGetMidX(cell.bounds), CGRectGetMidY(cell.bounds));
        
        /**
         *  为求简单，即将设置的圆角半径为正方形边长的一半
         *  这样mask曲线和重新绘制的方法写起来比较方便，圆角效果是正方形的内切圆
         ＊ 如果需求为非圆圆角，原理都是一样的，具体可参见UIBezierPath
         */
        view.layer.masksToBounds = YES;
        view.layer.cornerRadius = imgSize.width / 2;
    }
    
    return cell;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    CGFloat topAndBottom = [ViewController cellVMargin] / 2;
    CGFloat leftAndRight = [ViewController cellHMargin] / 2;
    return UIEdgeInsetsMake(topAndBottom, leftAndRight, topAndBottom, leftAndRight);
}

@end
