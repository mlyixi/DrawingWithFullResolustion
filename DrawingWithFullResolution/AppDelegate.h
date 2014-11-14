//
//  AppDelegate.h
//  DrawingWithFullResolution
//
//  Created by mlyixi on 11/14/14.
//  Copyright (c) 2014 mlyixi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "MLViewController.h"
@interface AppDelegate : UIResponder <UIApplicationDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>
{
    MLViewController *viewController;
}
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic,strong) ALAssetsLibrary *library;

@end

