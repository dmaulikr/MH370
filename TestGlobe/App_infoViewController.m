//
//  App_infoViewController.m
//  TestGlobe
//
//  Created by aamrit.rao on 20/03/2014.
//  Copyright (c) 2014 aamrit.rao. All rights reserved.
//

#import "App_infoViewController.h"

@interface App_infoViewController ()

@end

@implementation App_infoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)btnClose:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end