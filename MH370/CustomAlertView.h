#import <UIKit/UIKit.h>

@class CustomAlertView;

@protocol CustomAlertViewDelegate
- (void) alertView:(CustomAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;
@end

@interface CustomAlertView : UIViewController <UITextFieldDelegate>
{
    UIView                                  *alertView;
    UIView                                  *backgroundView;
    
    __unsafe_unretained id<NSObject, CustomAlertViewDelegate>   delegate;
@private
  BOOL                                    busyDismissing;
}

@property (nonatomic, retain) IBOutlet  UIView *alertView;
@property (nonatomic, retain) IBOutlet  UIView *backgroundView;
@property (nonatomic, assign) IBOutlet id<NSObject, CustomAlertViewDelegate> delegate;

- (IBAction)show;
- (IBAction)dismiss:(id)sender;
- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated;

@end