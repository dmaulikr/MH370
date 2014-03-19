//
//  ViewController.h
//  MH370
//
//  Created by Sravan Jinna on 19/03/2014.
//  Copyright (c) 2014 soma. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController {

IBOutlet UIImageView *yourImageView;

}

@property (nonatomic, retain) IBOutlet UIImageView *yourImageView;

-(UIImage *)imageNamed:(NSString *)name withColor:(UIColor *)color;

@end
