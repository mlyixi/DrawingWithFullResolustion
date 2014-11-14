//
//  MLViewController.h
//  DrawingWithFullResolution
//
//  Created by mlyixi on 11/14/14.
//  Copyright (c) 2014 mlyixi. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^MLImageDoneCallback)(UIImage *image, BOOL canceled);

@interface MLViewController : UIViewController<UIGestureRecognizerDelegate>
///编辑完成回调函数
@property(nonatomic,strong) MLImageDoneCallback doneCallback;
///载入的图片
@property(nonatomic,strong) UIImage *image;
//最大最小比例,暂时没用
@property(nonatomic,assign) CGFloat minimumScale;
@property(nonatomic,assign) CGFloat maximumScale;
///导航/绘画切换
@property(nonatomic,assign) BOOL drawing;

@end
