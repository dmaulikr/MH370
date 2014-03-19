//
//  FilterSelectorController.h
//  VAA
//
//  Created by Calum McMinn on 28/10/2009.
//  Copyright 2009 Tag Games. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@class AppDelegate;

@interface GameTextController : UIViewController {
	AppDelegate*		parent;
	IBOutlet UILabel*	scoreText;
	IBOutlet UILabel*	highscoreText;
	IBOutlet UILabel*	score;
	IBOutlet UILabel*	highscore;
}

@property(nonatomic, retain) AppDelegate *parent;

-(void) setAppPtr:(AppDelegate *)ad;
- (void) setScore:(NSString*)inScore withHighScore:(NSString*)inHighScore;
-(IBAction) btnBack_Click:(id)sender;
- (IBAction) btnNext_Click:(id)sender;

@end
