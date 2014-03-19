//
//  GlobeViewController.m
//  TestGlobe
//
//  Created by aamrit.rao on 19/03/2014.
//  Copyright (c) 2014 aamrit.rao. All rights reserved.
//

#import "GlobeViewController.h"
#import "GameViewController.h"
@interface GlobeViewController ()

@end

@implementation GlobeViewController
@synthesize Game;
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
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(IBAction)loadAirportGame{
	
        if (self.Game == nil) {
            GameViewController * controller = [[GameViewController alloc]initWithGame:0];
            
            self.Game = controller;
            [controller release];
            [self.Game initGame:0];
        }
        else {
            [self.Game initGame:0];
        }
        [self.navigationController pushViewController:self.Game animated:YES];
        
   
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
