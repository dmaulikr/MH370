//
//  GlobeViewController.h
//  TestGlobe
//
//  Created by aamrit.rao on 19/03/2014.
//  Copyright (c) 2014 aamrit.rao. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GameViewController;
@interface GlobeViewController : UIViewController{
    GameViewController* Game;
}
@property(nonatomic,retain) GameViewController* Game;
@end
