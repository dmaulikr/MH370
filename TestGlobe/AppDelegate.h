
#import <UIKit/UIKit.h>
@class EAGLView;
@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
       EAGLView	*glView;

}
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, retain) EAGLView *glView;


@end
