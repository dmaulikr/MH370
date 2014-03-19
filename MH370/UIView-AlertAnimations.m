#import "UIView-AlertAnimations.h"
#import <QuartzCore/QuartzCore.h>

#define kAnimationDuration  0.2555

@implementation UIView(AlertAnimations)

float pulsesteps[3] = { 0.2, 1/15., 1/7.5 };

- (void) pulse {
    self.transform = CGAffineTransformMakeScale(0.6, 0.6);
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:pulsesteps[0]];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(pulseGrowAnimationDidStop:finished:context:)];
    self.transform = CGAffineTransformMakeScale(1.1, 1.1);
    [UIView commitAnimations];
}

- (void)pulseGrowAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {   
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:pulsesteps[1]];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(pulseShrinkAnimationDidStop:finished:context:)];
    self.transform = CGAffineTransformMakeScale(0.9, 0.9);
    [UIView commitAnimations];
}

- (void)pulseShrinkAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:pulsesteps[2]];
    self.transform = CGAffineTransformIdentity;
    [UIView commitAnimations];
}

- (void)doFadeInAnimation{
    [self doFadeInAnimationWithDelegate:nil];
}

- (void)doFadeInAnimationWithDelegate:(id)animationDelegate{
    CALayer *viewLayer = self.layer;
    CABasicAnimation *fadeInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeInAnimation.fromValue = [NSNumber numberWithFloat:0.0];
    fadeInAnimation.toValue = [NSNumber numberWithFloat:1.0];
    fadeInAnimation.duration = kAnimationDuration;
    fadeInAnimation.delegate = animationDelegate;
    [viewLayer addAnimation:fadeInAnimation forKey:@"opacity"];
}@end