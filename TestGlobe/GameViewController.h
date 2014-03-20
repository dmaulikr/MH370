

#import <UIKit/UIKit.h>
#import "EAGLView.h"
#import "CustomAlertView.h"


// this class creates and manages all of the interface stuff for the game it deals with switching between the game states and 
//drawing text to the screen it does not deal with rendering the game only managing its states.


@interface GameViewController : UIViewController <UIAlertViewDelegate>{
	EAGLView	*glView;// the actual view the globe is rendered in
	int gameMode;//0= balloon 1 = airport
	UIAlertView* alert;
	bool airport;
}

@property(nonatomic,retain)	IBOutlet EAGLView *glView;
@property(nonatomic,retain)	UIAlertView* alert;

- (id) initWithGame:(int)gMode;
- (void) initGame:(int)gMode;
//- (void) showBalloonWin;
//- (void) showBalloonLose:(int)inScore withHighScore:(int)inHighScore;
- (void) showFindRichardResult:(int)inScore withHighScore:(int)inHighScore;

@end
