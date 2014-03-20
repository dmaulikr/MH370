//
//  gameViewController.m
//  VAA
//
//  Created by Fabien on 15/02/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "gameViewController.h"
#import "AppDelegate.h"
//#import "UIWaracleButton.h"
//#import "UIWaracleSmallButton.h"

#define GAME_VIEW_CONT_ENABLE_PRINTS 0

@interface GameViewController()
- (void) initAlternateGame;
- (void) showWheresRichardIntro;
- (void) showBalloonIntro;
- (BOOL) nextGameState;
- (void) showCustomAlert:(NSString*)text withButton1:(NSString*)text1 withButton1:(NSString*)text2;
@end

@implementation GameViewController
@synthesize glView;
@synthesize alert;

- (id) initWithGame:(int) gMode {
	
    self = [super init];
	if (self != nil) {
		
        glView= [[EAGLView alloc] initWithFrame:CGRectMake(0, 64, 320, self.view.bounds.size.height)];
		
		self.view =glView;
        
		[self initGame:gMode];
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	//[glView initResources]; 
	
}
-(void)viewWillAppear:(BOOL)animated{
	if(glView){
	[glView clearTouches];
	glView.interface = self;
	[glView startAnimation];

	[self initAlternateGame];//initiates the game
	}
	else {
		[self performSelector:@selector(viewWillAppear:) withObject:self afterDelay:1];
	}

}

-(void)viewWillDisappear:(BOOL)animated{
	glView.updateDraw = FALSE;
//	for (UIView *view in self.view.subviews) {
//		[view removeFromSuperview];
//	}
	[alert dismissWithClickedButtonIndex:5 animated:NO];
  self.alert = nil;
}

-(IBAction)beginBalloonGame{
}

-(IBAction)beginAirportGame{
}
//rory functions

-(void)initGame:(int) gMode
{
#if GAME_VIEW_CONT_ENABLE_PRINTS
	NSLog(@"GameViewController::  init Game started");
#endif

	glView.globeMode =GLOBE_MODE_TARGET;
	glView.animationInterval = 1.0 / 60.0;
	AppDelegate * delegate = (AppDelegate*) [[UIApplication sharedApplication]delegate];
	[glView setAppPtr:delegate];
	//make sure it loads in the textures for the games
	glView.first = NO;
	glView.appMode = APP_MODE_GAME_BALLOON;
	glView.globeMode =GLOBE_MODE_TARGET;
	glView.lastGame = gameMode;
	gameMode = gMode;
	//allow the eaglview to call functions to allow new interface
	glView.interface = self;
	
#if GAME_VIEW_CONT_ENABLE_PRINTS
	NSLog(@"GameViewController::  init Game finished");
#endif
}

//origional slifhtly altered functions
-(void) initAlternateGame {	
	switch(gameMode){
		case 0:
			[self showWheresRichardIntro];
			[glView initAirportGame];
			break;
		case 1:
			[glView initBalloonGame];
			[self showBalloonIntro];
			
			break;
	}
}
//balloon game messages
- (void) showWheresRichardIntro
{
#if GAME_VIEW_CONT_ENABLE_PRINTS
	NSLog(@"GameViewController::  showing Richard Intro");
#endif
	glView.updateDraw = TRUE;
	//todo Cancel pressed allow user to select games!
	glView.appMode = APP_MODE_GAME_AIRPORT;
	[glView initAirportGame];
	[glView setGameState:GS_AIRPORT_FIND];	//[glView initAirportGame];
	airport = TRUE;
	glView.zoomLevel = 55;
	
	
}

- (void) showBalloonIntro
{
#if GAME_VIEW_CONT_ENABLE_PRINTS
	NSLog(@"GameViewController::  Showing Baloon Intro");
#endif
	glView.updateDraw = TRUE;
	//make sure it loads in the textures for the games
	glView.first = NO;
	glView.appMode = APP_MODE_GAME_BALLOON;
	glView.globeMode =GLOBE_MODE_TARGET;
	glView.lastGame = gameMode;
	//allow the eaglview to call functions to allow new interface
	//todo Cancel pressed allow user to select games!
	// alert = [[UIAlertView alloc]initWithTitle:@"Balloon Game" message:@"Play balloon game" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"startGame",nil]	;
	//[alert show];
	[glView drawView];
	[self nextGameState];
}

//- (void) showBalloonWin {
//	//todo Cancel pressed allow user to select games!
//	[self showCustomAlert:@"Richard has safely arrived\nat his goal. Are you ready\nto try a more difficult trip?"  withButton1:@"Quit" withButton1:@"Continue" ];
//	airport = false;
//}


//- (void) showBalloonLose:(int)inScore withHighScore:(int)inHighScore {
//	//todo Cancel pressed allow user to select games!
//	[self showCustomAlert:[NSString stringWithFormat:@"\nRichard's trip has been cut\nshort by bad weather.\nYour score: %d",inScore]  withButton1:@"Quit" withButton1:@"Restart" ];
//	airport = false;
//	//[self performSelector:@selector(hideAlert) withObject:nil afterDelay:3.0];
//}

- (void) hideAlert {
	[alert dismissWithClickedButtonIndex:0 animated:YES];
  self.alert = nil;
}

//aiport game messages
- (void) showFindRichardResult:(int)inScore withHighScore:(int)inHighScore
{
	//todo Cancel pressed allow user to select games!
	[self showCustomAlert:[NSString stringWithFormat:@"     Out of Time!\n     Your score: %d",inScore]  withButton1:@"Quit" withButton1:@"Restart" ];
}


//alert view delegate methods

-(void)alertView:(CustomAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0){
		[self.navigationController popViewControllerAnimated:YES];
	}
	if (buttonIndex == 1) 
	{
		[self nextGameState];
		if(airport== TRUE){
			[glView setGameState:GS_AIRPORT_FIND];	
			glView.appMode = APP_MODE_GAME_AIRPORT;
			[glView initAirportGame];
		}
	}
}

- (BOOL) nextGameState
{
	int currentGameState = [glView getGameState];
	int newGameState = currentGameState;
	BOOL endGame = NO;
	BOOL removeView = NO;

#if GAME_VIEW_CONT_ENABLE_PRINTS
	NSLog(@"GameViewController::NextGameState - current State : %d",currentGameState);
#endif	
	
	switch(currentGameState)
	{
		case GS_AIRPORT_INTRO:
			newGameState = GS_AIRPORT_FIND;
			removeView = YES;
			break;
		case GS_AIRPORT_RESULT:
			endGame = YES;
			removeView = YES;
			break;
		case GS_BALLOON_INTRO:
			newGameState = GS_BALLOON_GAMEPLAY;
			removeView = YES;
			break;
		case GS_BALLOON_WIN:
			newGameState = GS_BALLOON_CONTINUE;
			removeView = YES;
			break;
		case GS_BALLOON_LOSE:
		case GS_BALLOON_OUT_OF_TIME:
			newGameState = GS_BALLOON_GAMEPLAY;
			removeView = YES;
			break;
	}
	
	if(!endGame)
	{
		[glView setGameState:newGameState];
	}
	else
	{
		[glView endCurrentGame];
	}
	
	return removeView;
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
  [super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
//  [alert release];
//  [super dealloc];
}

-(void)showCustomAlert:(NSString*)text withButton1:(NSString*)text1 withButton1:(NSString*)text2
{
	self.alert = [[UIAlertView alloc] initWithTitle:@"Your Score" message:[NSString stringWithFormat:@"%@%@", text1, text2] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
	alert.delegate = self;
	[alert show];
	
//	UILabel * titlelabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 10, 280, 110)];
//	titlelabel.text = [NSString stringWithFormat:@"%@",text];
//	titlelabel.font = [UIFont fontWithName:@"Arial-BoldMT" size:17];
//	titlelabel.numberOfLines = 0;
//	titlelabel.contentMode = UIViewContentModeCenter;
//	titlelabel.textColor = [UIColor whiteColor];
//	titlelabel.backgroundColor = [UIColor clearColor];
//	[alert.alertView addSubview:titlelabel];
//	//[titlelabel release];
//	
//	UIButton *cancel = [[UIButton alloc]initWithFrame:CGRectMake(40,130, 100, 42)];
//	[cancel setTitle:text1 forState:UIControlStateNormal];
//	[cancel addTarget:self action:@selector(quit)forControlEvents:UIControlEventTouchUpInside];
//	[alert.alertView addSubview:cancel];
//	[cancel release];
//	
//	UIButton* showSchedule = [[UIButton alloc]initWithFrame:CGRectMake(150,130, 100, 42)];
//	[showSchedule setTitle:text2 forState:UIControlStateNormal];
//	[showSchedule addTarget:self action:@selector(continueGame)forControlEvents:UIControlEventTouchUpInside];
//	[alert.alertView addSubview:showSchedule];
//	[showSchedule release];
}

-(void)quit
{
	[alert dismissWithClickedButtonIndex:0 animated:YES];
  self.alert = nil;
}

-(void)continueGame
{
	[alert dismissWithClickedButtonIndex:1 animated:YES];
  self.alert = nil;
}

@end
