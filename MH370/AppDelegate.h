//
//  AppDelegate.h
//  MH370
//
//  Created by Sravan Jinna on 19/03/2014.
//  Copyright (c) 2014 soma. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "GameTextController.h"
//#import "EAGLView.h"

@class EAGLView;
@class GameTextController;

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    
    GameTextController			*gameTextController;
    EAGLView					*glView;
}

@property (strong, nonatomic) UIWindow *window;

- (void) showWheresRichardIntro;
- (BOOL) nextGameState;
- (void) showGlobe;
@end
