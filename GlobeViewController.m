//
//  GlobeViewController.m
//  TestGlobe
//
//  Created by aamrit.rao on 19/03/2014.
//  Copyright (c) 2014 aamrit.rao. All rights reserved.
//

#import "GlobeViewController.h"
#import "GameViewController.h"
#import "App_infoViewController.h"

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
    //[self.navigationController setNavigationBarHidden:YES];
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"MH370";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(IBAction)loadAirportGame{
	
        if (self.Game == nil) {
            GameViewController * controller = [[GameViewController alloc]initWithGame:0];
            //controller.navigationController.navigationBarHidden =FALSE;
            
            self.Game = controller;
            [controller release];
            [self.Game initGame:0];
        }
        else {
            [self.Game initGame:0];
        }
        [self.navigationController pushViewController:self.Game animated:YES];
    //[self presentViewController:self.Game animated:NO completion:nil];
   
}

-(IBAction)btnInfo
{
	
    App_infoViewController *objApp_infoViewController=[[App_infoViewController alloc]initWithNibName:@"App_infoViewController" bundle:nil];
    [self presentViewController:objApp_infoViewController animated:YES completion:nil];
    [objApp_infoViewController release];
    objApp_infoViewController=nil;
    
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
