#import "CustomAlertView.h"
#import "UIView-AlertAnimations.h"
#import <QuartzCore/QuartzCore.h>

@interface CustomAlertView()
- (void)alertDidFadeOut;
@end

@implementation CustomAlertView
@synthesize alertView;
@synthesize backgroundView;
@synthesize delegate;

#pragma mark -
#pragma mark IBActions
- (IBAction)show
{    
	// Retaining self is odd, but we do it to make this "fire and forget"    
	//[self retain];
    
    // We need to add it to the window, which we can get from the delegate    
	id appDelegate = [[UIApplication sharedApplication] delegate];
    
	UIWindow *window = [appDelegate window];
    [window addSubview:self.view];
    
    // Make sure the alert covers the whole window    
	self.view.frame = window.frame;
    self.view.center = window.center;
    
    // "Pop in" animation for alert    
	[alertView pulse];
    
    // "Fade in" animation for background    
	[backgroundView doFadeInAnimation];
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated
{
  // We need to make sure this method isn't called again from within the
  // didDismissWithButtonIndex callback. Otherwise the alertDidFadeOut method
  // gets called more than once and the object is released more than once.
  if (!busyDismissing) {
    busyDismissing = YES;
	  [self dismiss:self];
	  [delegate alertView:self didDismissWithButtonIndex:buttonIndex];
    busyDismissing = NO;
  }
}

- (IBAction)dismiss:(id)sender{
    [UIView beginAnimations:nil context:nil];
    self.view.alpha = 0.0;
    [UIView commitAnimations];
    
    [self performSelector:@selector(alertDidFadeOut) withObject:nil afterDelay:0.5];
}

#pragma mark -
- (void)viewDidUnload {
    [super viewDidUnload];
    self.alertView = nil;
    self.backgroundView = nil;
}

- (void)dealloc {
//    [alertView release];
//    [backgroundView release];
//    [super dealloc];
}

#pragma mark -
#pragma mark Private Methods
- (void)alertDidFadeOut{    
    [self.view removeFromSuperview];
    //[self autorelease];
}

@end

