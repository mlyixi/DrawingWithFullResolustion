//
//  MLViewController.m
//  DrawingWithFullResolution
//
//  Created by mlyixi on 11/14/14.
//  Copyright (c) 2014 mlyixi. All rights reserved.
//

#import "MLViewController.h"
#import <QuartzCore/QuartzCore.h>
///blockkit,用于简化输入时的代理方法
#import "UIAlertView+BlocksKit.h"

@interface MLViewController ()
{
    //触摸时对应原图的坐标点
    CGPoint sBeginPoint;
    //触摸时对应屏幕的坐标点,供暂时的显示用.
    CGPoint tBeginPoint;
    
    UISlider *slider;
    UISegmentedControl *colorCtl;
    UISwitch *drawSwitch;
    
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat opacity;
    BOOL mouseSwiped;
    CGFloat scale;
    UIColor *color;
}
///导航手势
@property (nonatomic,strong) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic,strong) UIRotationGestureRecognizer *rotationRecognizer;
@property (nonatomic,strong) UIPinchGestureRecognizer *pinchRecognizer;
@property (nonatomic,strong) UITapGestureRecognizer *tapRecognizer;

//导航时图片的中心点,暂时没用
@property(nonatomic,assign) CGPoint touchCenter;
@property(nonatomic,assign) CGPoint scaleCenter;

///图片视图,imageView为底图,用于显示编辑图片, tempView用于显示绘制时效果,亦可用于一些操作管理(未完成).
@property (nonatomic,strong) UIImageView *imageView;
@property (nonatomic,strong) UIImageView *tempView;

@property(nonatomic,assign) NSUInteger gestureCount;
@end

@implementation MLViewController
@synthesize drawing=_drawing;

-(void)loadView
{
    [super loadView];
    self.view.backgroundColor=[UIColor whiteColor];
    _imageView=[[UIImageView alloc] init];
    _imageView.contentMode=UIViewContentModeScaleAspectFit;
    [self.view addSubview:_imageView];
    
    _tempView=[[UIImageView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:_tempView];
    
    UIView *toolView=[[UIView alloc] init];
    toolView.backgroundColor=[UIColor whiteColor];
    toolView.alpha=0.9;
    toolView.translatesAutoresizingMaskIntoConstraints=NO;
    [self.view addSubview:toolView];
    
    UILabel *drawLabel=[[UILabel alloc] init];
    drawLabel.translatesAutoresizingMaskIntoConstraints=NO;
    drawLabel.text=@"Draw:";
    [toolView addSubview:drawLabel];
    
    drawSwitch=[[UISwitch alloc] init];
    drawSwitch.translatesAutoresizingMaskIntoConstraints=NO;
    [drawSwitch addTarget:self action:@selector(navDraw:) forControlEvents:UIControlEventValueChanged];
    [toolView addSubview:drawSwitch];
    
    UILabel *lineLabel=[[UILabel alloc] init];
    lineLabel.translatesAutoresizingMaskIntoConstraints=NO;
    lineLabel.text=@"LineWidth";
    [toolView addSubview:lineLabel];
    
    slider=[[UISlider alloc] init];
    slider.translatesAutoresizingMaskIntoConstraints=NO;
    slider.maximumValue=20.f;
    slider.minimumValue=1.f;
    slider.value=2.f;
    [toolView addSubview:slider];
    
    colorCtl=[[UISegmentedControl alloc] initWithItems:@[@"red",@"white"]];
    colorCtl.translatesAutoresizingMaskIntoConstraints=NO;
    [colorCtl setImage:[UIImage imageNamed:@"eraser.png"] forSegmentAtIndex:1];
    [colorCtl addTarget:self action:@selector(colorCtlSelected:) forControlEvents:UIControlEventValueChanged];
    [toolView addSubview:colorCtl];
    
    NSDictionary *toolViewDictionary=NSDictionaryOfVariableBindings(toolView,drawSwitch,drawLabel,slider,lineLabel,slider,colorCtl);
    NSArray *cstrs=[NSLayoutConstraint constraintsWithVisualFormat:@"|-5-[toolView]-5-|" options:0 metrics:nil views:toolViewDictionary];
    [self.view addConstraints:cstrs];
    cstrs=[NSLayoutConstraint constraintsWithVisualFormat:@"V:[toolView(50)]-5-|" options:0 metrics:nil views:toolViewDictionary];
    [self.view addConstraints:cstrs];
    
    cstrs=[NSLayoutConstraint constraintsWithVisualFormat:@"|-2-[drawSwitch]-10-[slider(100)]-10-[colorCtl(100)]|" options:0 metrics:nil views:toolViewDictionary];
    [toolView addConstraints:cstrs];
    NSLayoutConstraint *cstr=[NSLayoutConstraint constraintWithItem:drawLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:drawSwitch attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    [toolView addConstraint:cstr];
    cstr=[NSLayoutConstraint constraintWithItem:lineLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:slider attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    [toolView addConstraint:cstr];
    
    cstrs=[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[drawLabel][drawSwitch]|" options:0 metrics:nil views:toolViewDictionary];
    [toolView addConstraints:cstrs];
    cstrs=[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[lineLabel][slider]|" options:0 metrics:nil views:toolViewDictionary];
    [toolView addConstraints:cstrs];
    cstrs=[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[colorCtl]|" options:0 metrics:nil views:toolViewDictionary];
    [toolView addConstraints:cstrs];
    
    UIBarButtonItem *saveItem=[[UIBarButtonItem alloc] initWithTitle:@"save" style:UIBarButtonItemStylePlain target:self action:@selector(doneAction:)];
    self.navigationItem.rightBarButtonItem=saveItem;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    colorCtl.selectedSegmentIndex=0;
    color=[UIColor redColor];
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panRecognizer.cancelsTouchesInView = NO;
    panRecognizer.delegate = self;
    [self.view addGestureRecognizer:panRecognizer];
    self.panRecognizer = panRecognizer;
    
    UIRotationGestureRecognizer *rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];
    rotationRecognizer.cancelsTouchesInView = NO;
    rotationRecognizer.delegate = self;
    [self.view addGestureRecognizer:rotationRecognizer];
    self.rotationRecognizer = rotationRecognizer;
    
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    pinchRecognizer.cancelsTouchesInView = NO;
    pinchRecognizer.delegate = self;
    [self.view addGestureRecognizer:pinchRecognizer];
    self.pinchRecognizer = pinchRecognizer;
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapRecognizer.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tapRecognizer];
    self.tapRecognizer = tapRecognizer;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //由于imageView高度定制,不能保证保证图片完全的宽高比缩放,所以要自定义imageView的大小
    scale=MAX(_image.size.width/self.view.frame.size.width, _image.size.height/self.view.frame.size.height);
    CGFloat imageViewWidth=_image.size.width/scale;
    CGFloat imageViewHeight=_image.size.height/scale;
    self.imageView.frame=CGRectMake(0, 0, imageViewWidth, imageViewHeight);
    self.imageView.center=self.view.center;
    //图片必须在appear周期内生成.应该是pickImageViewcontroller的问题.
    self.imageView.image=_image;
    self.drawing=NO;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    _tempView.image=nil;
    drawSwitch.on=NO;
    self.drawing=NO;
    
}

///绘图手势方法
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (drawSwitch.on) {
        mouseSwiped = NO;
        UITouch *touch = [touches anyObject];
        sBeginPoint = [touch locationInView:self.imageView];
        tBeginPoint=[touch locationInView:self.tempView];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (drawSwitch.on) {
        mouseSwiped = YES;
        UITouch *touch=[touches anyObject];
        CGPoint tmpPoint=[touch locationInView:_tempView];
        
        UIGraphicsBeginImageContext(_tempView.frame.size);
        CGContextRef ctx=UIGraphicsGetCurrentContext();
        CGContextSetStrokeColorWithColor(ctx, color.CGColor);
        CGContextMoveToPoint(ctx, tBeginPoint.x, tBeginPoint.y);
        CGContextAddLineToPoint(ctx, tmpPoint.x, tmpPoint.y);
        CGContextSetLineWidth(ctx, slider.value);
        CGContextStrokePath(ctx);
        self.tempView.image=UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        
        
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (drawSwitch.on) {
        UITouch *touch = [touches anyObject];
        CGPoint sStopPoint = [touch locationInView:self.imageView];
        
        if(!mouseSwiped) {
            [self promptForTextAtPoint:sStopPoint];
        }else
        {
            self.imageView.image=[self imageByDrawingLineOnImageView:self.imageView startPoint:sBeginPoint stopPoint:sStopPoint];
        }
    }
}
///startPoint,stopPoint为imageView上的点,转换为图像上的点进行绘制
- (UIImage *)imageByDrawingLineOnImageView:(UIImageView *)imageView startPoint:(CGPoint)startPoint stopPoint:(CGPoint)stopPoint
{
    UIGraphicsBeginImageContext(imageView.image.size);
    [imageView.image drawAtPoint:CGPointZero];
    CGContextRef ctx=UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(ctx, color.CGColor);
    CGContextMoveToPoint(ctx, startPoint.x*scale, startPoint.y*scale);
    CGContextAddLineToPoint(ctx, stopPoint.x*scale, stopPoint.y*scale);
    CGContextSetLineWidth(ctx, slider.value);
    CGContextStrokePath(ctx);
    UIImage *retImage=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return retImage;
}
- (UIImage *)imageByDrawingText:(NSString *)text OnImage:(UIImage *)image atPoint:(CGPoint)point
{
    UIGraphicsBeginImageContext(image.size);
    [image drawAtPoint:CGPointZero];
    CGSize textRect=[text sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0f]}];
    CGRect rect=CGRectMake(point.x*scale-textRect.width/2, point.y*scale-textRect.height/2,textRect.width, textRect.height);
    CGContextRef ctx=UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    [text drawInRect:rect withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0f]}];
    UIImage *retImage=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return retImage;
}
- (void)promptForTextAtPoint:(CGPoint)point
{
    UIAlertView *alertView = [UIAlertView bk_alertViewWithTitle:@"Text Tool" message:@"Enter the text to draw."];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
    [alertView bk_addButtonWithTitle:@"Ok" handler:^{
        self.imageView.image=[self imageByDrawingText:[alertView textFieldAtIndex:0].text OnImage:self.imageView.image atPoint:point];
    }];
    [alertView show];
    
}


///手势识别类的处理方法
- (IBAction)handlePan:(UIPanGestureRecognizer*)recognizer
{
    switch (recognizer.state) {
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [recognizer translationInView:self.imageView];
            self.imageView.transform=CGAffineTransformTranslate(self.imageView.transform, translation.x,translation.y);
            [recognizer setTranslation:CGPointMake(0, 0) inView:self.imageView];
            break;
        }
        default:
            break;
    }
}
- (IBAction)handleRotation:(UIRotationGestureRecognizer*)recognizer
{
    switch (recognizer.state) {
        case UIGestureRecognizerStateChanged:
            self.imageView.transform=CGAffineTransformRotate(self.imageView.transform, recognizer.rotation);
            recognizer.rotation=0;
            break;
            
        default:
            break;
    }
}
- (IBAction)handlePinch:(UIPinchGestureRecognizer*)recognizer
{
    switch (recognizer.state) {
        case UIGestureRecognizerStateChanged:
            self.imageView.transform=CGAffineTransformScale(self.imageView.transform, recognizer.scale, recognizer.scale);
            recognizer.scale=1;
            break;
        default:
            break;
    }
}
- (IBAction)handleTap:(UITapGestureRecognizer*)recognizer
{
    self.view.userInteractionEnabled=NO;
    [UIView animateWithDuration:0.25 animations:^{
        self.imageView.transform=CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.view.userInteractionEnabled=YES;
    }];
    
}

///浏览绘图切换
- (IBAction)navDraw:(UISwitch *)navOrDraw
{
    self.drawing=navOrDraw.on;
    self.tempView.image=nil;
}


///gestureRecognizer deleage method - 提高手势识别敏感度
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (IBAction)doneAction:(id)sender
{
    if(self.doneCallback) {
        self.doneCallback(self.imageView.image, NO);
    }
    
}
- (IBAction)colorCtlSelected:(id)sender
{
    if (colorCtl.selectedSegmentIndex==0) {
        color=[UIColor redColor];
    }else
    {
        color=[UIColor whiteColor];
    }
}

- (void)setDrawing:(BOOL)drawing
{
    
    _drawing=drawing;
    slider.enabled=drawing;
    colorCtl.userInteractionEnabled=drawing;
    BOOL naving=!drawing;
    self.rotationRecognizer.enabled=naving;
    self.panRecognizer.enabled=naving;
    self.tapRecognizer.enabled=naving;
    self.pinchRecognizer.enabled=naving;
    
}
-(BOOL)drawing
{
    return _drawing;
}

@end
