//
//  AppDelegate.h
//  TestGlobe
//
//  Created by aamrit.rao on 19/03/2014.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EAGLView;
@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
       EAGLView					*glView;

}
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, retain) EAGLView *glView;


@end
