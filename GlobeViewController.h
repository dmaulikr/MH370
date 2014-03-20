

#import <UIKit/UIKit.h>
@class GameViewController;
@interface GlobeViewController : UIViewController{
    GameViewController* Game;
}
@property(nonatomic,retain) GameViewController* Game;
@end
