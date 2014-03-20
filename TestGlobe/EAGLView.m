//
//  EAGLView.m
//  VAA
//
//  Created by Tag Games on 14/09/2009.
//  Copyright Tag Games Ltd 2009. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "EAGLView.h"
#import "gameViewController.h"
//#import "GlobeViewController.h"
#import "AirportDataManager.h"
#define EAGLVIEW_ENABLE_PRINTS        0

#define USE_DEPTH_BUFFER            1

@interface EAGLView ()

@property(nonatomic, retain) EAGLContext *context;
@property(nonatomic, assign) NSTimer *animationTimer;

- (BOOL)createFramebuffer;

- (void)destroyFramebuffer;

- (void)initResources;

- (BOOL)loadTextureFromPNGFileWithName:(NSString *)nameMinusPNG ToTex:(GLuint *)tex;

- (void)drawShineyOverlay;

- (void)drawQuad;

//- (GlobeViewController *)globeInterface;

- (GameViewController *)gameInterface;

@end


@implementation EAGLView

@synthesize context;
@synthesize animationTimer;
@synthesize animationInterval;
@synthesize lastGame;
@synthesize globeMode;
@synthesize first;
@synthesize appMode;
@synthesize interface, updateDraw, zoomLevel, textScale;


//ACCELEROMETER
#define kAccelerometerFrequency            25        //Hz
#define kAccelerometerFrequencySlow        0.0166f    //
#define kFilteringFactor                0.1
#define kMinEraseInterval                0.5
#define kMaxEraseInterval                2.0
#define kEraseAccelerationThreshold        2.0

UIAccelerationValue myAccelerometer[3];
CFAbsoluteTime lastTime = 0;
short shakes = 0;
BOOL accelerometerEnabled = NO;


//- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
//    if (self.animationTimer == nil) {
//#if EAGLVIEW_ENABLE_PRINTS
//		NSLog(@"Globe not visible, ignoring shake...");
//#endif
//        return;
//    }
//
//    UIAccelerationValue length, x, y, z;
//    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
//
//    //Use a basic high-pass filter to remove the influence of the gravity
//    myAccelerometer[0] = acceleration.x * kFilteringFactor + myAccelerometer[0] * (1.0 - kFilteringFactor);
//    myAccelerometer[1] = acceleration.y * kFilteringFactor + myAccelerometer[1] * (1.0 - kFilteringFactor);
//    myAccelerometer[2] = acceleration.z * kFilteringFactor + myAccelerometer[2] * (1.0 - kFilteringFactor);
//    // Compute values for the three axes of the acceleromater
//    x = acceleration.x - myAccelerometer[0];
//    y = acceleration.y - myAccelerometer[0];
//    z = acceleration.z - myAccelerometer[0];
//
//    //Compute the intensity of the current acceleration 
//    length = sqrt(x * x + y * y + z * z);
//    // If above a given threshold, play the erase sounds and erase the drawing view
//    if ((length >= kEraseAccelerationThreshold) && (currentTime > (lastTime + kMinEraseInterval))) {
//        if (currentTime > (lastTime + kMaxEraseInterval)) {
//            //too slow
//            shakes = 0;
//#if EAGLVIEW_ENABLE_PRINTS
//			NSLog(@"Shake too slow, resetting...");
//#endif
//        }
//        else {
//            shakes++;
//            if (shakes >= 2) {
//                shakes = 0;
//                [appPtr showGlobewithAircraft:[sky getRndPlane]];
//#if EAGLVIEW_ENABLE_PRINTS
//				NSLog(@"Shakes activated...");
//#endif
//            }
//        }
//        lastTime = CFAbsoluteTimeGetCurrent();
//    }
//}


//- (void)startAccelerometer {
//    [[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / kAccelerometerFrequency)];
//    [[UIAccelerometer sharedAccelerometer] setDelegate:self];
//    accelerometerEnabled = YES;
//}


//- (void)updateAccelerometerInterval:(BOOL)inInUse {
//    if ((inInUse) && (accelerometerEnabled)) {
//        [[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / kAccelerometerFrequency)];
//    }
//    else if ((!inInUse) && (accelerometerEnabled)) {
//        [[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / kAccelerometerFrequencySlow)];
//    }
//}


- (void)updatePerferredAirportList {
//    myAirport1 = (NSString *) [[NSUserDefaults standardUserDefaults] objectForKey:@"preferredAirport1"];
//    if (myAirport1 == nil) {
//        myAirport1 = @" ";
//    }
//    myAirport2 = (NSString *) [[NSUserDefaults standardUserDefaults] objectForKey:@"preferredAirport2"];
//    if (myAirport2 == nil) {
//        myAirport2 = @" ";
//    }
//    myAirport3 = (NSString *) [[NSUserDefaults standardUserDefaults] objectForKey:@"preferredAirport3"];
//    if (myAirport3 == nil) {
//        myAirport3 = @" ";
//    }
//
}


// You must implement this method
+ (Class)layerClass {
    return [CAEAGLLayer class];
}


//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithFrame:(CGRect)frame {

    NSLog(@"%s ", __PRETTY_FUNCTION__);

    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(airportDataManagerUpdated) name:@"AirportDataUpdated" object:nil];

    //[[AirportDataManager sharedInstance] setDelegate:self];

    if ((self = [super initWithFrame:(CGRect) frame])) {

        CAEAGLLayer *eaglLayer = (CAEAGLLayer *) self.layer;
        first = YES;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];

        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];

        if (!context || ![EAGLContext setCurrentContext:context]) {
            //[self release];
            return nil;
        }


        [self initResources];

        drawAirportShortName = TRUE;
        animationInterval = 1.0 / 60.0;
        airportLabels = [[NSMutableArray alloc] init];
        perLoaded = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 250, 20)];
        perLoaded.backgroundColor = [UIColor clearColor];
        perLoaded.textColor = [UIColor whiteColor];
        perLoaded.font = [UIFont fontWithName:@"Arial" size:18];
        [self addSubview:perLoaded];

    }

    return self;
}


- (void)initResources {

    //NSLog(@"%s ", __PRETTY_FUNCTION__);

    drawingBalloon = false;
    [self loadHighScores];
    textScale = (35.0 / 60.0);
    GLuint TEXGLOBE, TEXMAIN, TEXNUMBER;
    [self loadTextureFromPNGFileWithName:@"globe" ToTex:&TEXGLOBE];
    [self loadTextureFromPNGFileWithName:@"maingfx" ToTex:&TEXMAIN];
    [self loadTextureFromPNGFileWithName:@"font" ToTex:&TEXNUMBER];
    [self loadTextureFromPNGFileWithName:@"globe_shine_light" ToTex:&globeshine];
    //[self loadTextureFromPNGFileWithName:@"fairclouds" ToTex:&cloudtex];
    //[self loadTextureFromPNGFileWithName:@"game_back_panel" ToTex:&scoretex];
    [self initRenderList:&rl_back withSize:1024];
    [self initRenderList:&rl_front withSize:1024];
    [self initRenderList:&rl_gui withSize:1024];

    [self loadTagSpriteData:texture_data_files[TEX_MAIN] DEST:ts_main TEX_W:512 TEX_H:1024];
    [self loadTagSpriteData:texture_data_files[TEX_NUMBER] DEST:ts_number TEX_W:128 TEX_H:128];

    viewOrientation = 2;

    rotateTouch = -1;
    zoomTouch = -1;

    zoomLevel = 60.0f;
    rotateY = 270.0f;
    rotateX = 231.0f;

    globe_radius = 30.4f;


#pragma mark Airport Plotting

    NSArray *airportsArray = [[[AirportDataManager sharedInstance] allAirports] retain];
//
//	
//	
    airports = (airport_t *) malloc(sizeof(airport_t) * airportsArray.count);
//
////    NSLog(@"%s ", __PRETTY_FUNCTION__);
////    NSLog(@"Current thread = %@", [NSThread currentThread]);
////    NSLog(@"airportCount = %u", airportsArray.count);
//
    primaryAirportIndexes = [[NSMutableArray array] retain];
//
	static int counter = 0;
//	
    for (int i = 0; i < airportsArray.count; i++) {

        //NSLog(@"Load airport %d", i);

        Airport *airport = [[airportsArray objectAtIndex:i] retain];
        [self initAirport:&airports[i] withName:airport.code withN:[airport.latitude floatValue] withE:[airport.longitude floatValue] withR:airport_colors[(i * 3)] withG:airport_colors[(i * 3) + 1] withB:airport_colors[(i * 3) + 2] isPrimary:[airport.primary boolValue]];
        if ([airport.primary boolValue] == YES) {
			counter++;
            [primaryAirportIndexes addObject:[NSNumber numberWithInt:i]];
        }

        [airport release];
    }

//	NSLog(@"Primary Airport Count %i", counter);

    /*
     THIS IS THE OLD PLOTTING CODE USING THEIR C ARRAYS, DON'T DELETE IN CASE OF COCK UP
    for (int i=0;i<NUM_AIRPORTS;i++){
		[self initAirport:&airports[i] withName:airport_names[i] withN:airport_coords[(i*2)] withE:airport_coords[(i*2)+1] withR:airport_colors[(i*3)] withG:airport_colors[(i*3)+1] withB:airport_colors[(i*3)+2]];
     }
     */

//    flightpaths = (flightpath_t *) malloc(sizeof(flightpath_t) * NUM_AIRPORTS);
//    for (int i = 0; i < NUM_AIRPORTS; i++) {
//        flightpaths[i].used = NO;
//    }

    planes = (plane_t *) malloc(sizeof(plane_t) * MAX_PLANES);
    for (int i = 0; i < MAX_PLANES; i++) {
        planes[i].used = NO;
        planes[i].name = NULL;
    }

    [self setMultipleTouchEnabled:YES];
    GLfloat mat_specular[] = {1.0, 1.0, 1.0, 1.0};
    GLfloat mat_diffuse[] = {1.0, 1.0, 1.0, 1.0};
    GLfloat mat_shininess[] = {5};
    glClearColor(1.0, 1.0, 1.0, 0.0);
    glShadeModel(GL_SMOOTH);

    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, mat_specular);
    glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, mat_diffuse);
    glMaterialfv(GL_FRONT_AND_BACK, GL_SHININESS, mat_shininess);
    GLfloat light0_ambient[] = {0.3, 0.3, 0.3, 1.0};

    GLfloat light0_position[] = {-10.0, 50.0, 100.0, 1.0};

    glLightfv(GL_LIGHT0, GL_AMBIENT, light0_ambient);
    glLightfv(GL_LIGHT0, GL_POSITION, light0_position);
    glEnable(GL_LIGHT0);

    GLfloat light1_ambient[] = {0.6, 0.6, 0.6, 1.0};
    GLfloat light1_diffuse[] = {1.0, 1.0, 1.0, 1.0};
    GLfloat light1_specular[] = {1.0, 1.0, 1.0, 1.0};
    GLfloat light1_position[] = {-10.0, 50.0, 100.0, 1.0};
    GLfloat spot_direction[] = {0.1, -0.5, -1.0};

    glLightfv(GL_LIGHT1, GL_AMBIENT, light1_ambient);
    glLightfv(GL_LIGHT1, GL_DIFFUSE, light1_diffuse);
    glLightfv(GL_LIGHT1, GL_SPECULAR, light1_specular);
    glLightfv(GL_LIGHT1, GL_POSITION, light1_position);
    glLightf(GL_LIGHT1, GL_SHININESS, 128);
    glLightf(GL_LIGHT0, GL_CONSTANT_ATTENUATION, 4);

    glLightf(GL_LIGHT1, GL_SPOT_CUTOFF, 30.0);
    glLightfv(GL_LIGHT1, GL_SPOT_DIRECTION, spot_direction);
    glLightf(GL_LIGHT1, GL_SPOT_EXPONENT, 50.0);

    glEnable(GL_LIGHT1);
    glEnable(GL_LIGHTING);
    drawFrame = true;

    //[airportsArray release];
}

- (void)airportDataManagerUpdated {

}


- (void)drawView {
    if (updateDraw) {

        AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];

        ticks++;

        [EAGLContext setCurrentContext:context];

        glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
        glViewport(0, 0, backingWidth, backingHeight);

        //[appPtr updatePlanes];


//        if ([appPtr isNewPlaneDataAvailable]) {
//            sky = [appPtr getPlaneData];
//        }

        [self resetRenderList:&rl_back];
        [self resetRenderList:&rl_front];
        [self resetRenderList:&rl_gui];

        switch (appMode) {
//            case APP_MODE_FREE: {
////
////                perLoaded.text = @"Loading please wait...";
////                for (int i = 0; i < 4; i++) {
////
////                    if (_touches[i].active && !_touches[i].used) {
////                        object_type = -1;
////                        nearest_plane = -1;
////                        nearest_airport = -1;
////                        float nearest_object = 99999.0f;
////                        float current_object = 0.0f;
////                        nearest_plane = [self checkForPlaneTouchedAtX:_touches[i].tx atY:_touches[i].ty returnDistance:&current_object];
////                        if (nearest_plane >= 0) {
////                            if (current_object < nearest_object) {
////                                nearest_object = current_object;
////                                object_type = 0;
////                            }
////                        }
////                        nearest_airport = [self checkForAirportTouchedAtX:_touches[i].tx atY:_touches[i].ty returnDistance:&current_object];
////                        if (nearest_airport >= 0) {
////                            if (current_object < nearest_object) {
////                                object_type = 1;
////                            }
////                        }
////                    }
////                }
////                int i = 0;
////                if (!_touches[i].active && !_touches[i].used) {
////
////                    if (zoomLevel < 50) {
////                        switch (object_type) {
////                            case 0:
////                                if (_touches[i].taps == 1 && !_touches[i].used) {
////                                    _touches[i].taps = 0;
////                                    selectedPlane = nearest_plane;
////
////                                    //Aircraft *aircraft = planes[selectedPlane].ac;
////                                    //[self.globeInterface tappedOnAircraft:aircraft withApp:appPtr];
////                                }
////                                break;
////
////                            case 1:
////                                if (_touches[i].taps == 1 && !_touches[i].used) {
////                                    _touches[i].taps = 0;
////                                    _touches[i].used = YES;
////                                    //NSString *Airport = airports[nearest_airport].name;
////                                    //[self.globeInterface tappedOnAirportWith:(NSString *) Airport];
////                                }
////                                break;
////                        }
////                    }
////                }
//            }
//                break;

//            case APP_MODE_PLANE:
////                perLoaded.text = @"Loading please wait...";
////                for (int i = 0; i < 4; i++) {
////                    if (_touches[i].active && !_touches[i].used) {
////                        globeMode = GLOBE_MODE_FREE;
////                        i = 4;
////                        continue;
////                    }
////                }
////
////
////                [self processTrackPlane];
//
//                break;

//            case APP_MODE_AIRPORT:
//                perLoaded.text = @"";
//                globeTargetX = airports[selectedAirport].north + 180.0f;
//                globeTargetY = -airports[selectedAirport].east - 90.0f;
//                globeTargetZoom = 40.0;
//                break;

            case APP_MODE_GAME_AIRPORT:
                perLoaded.text = @"";
                [self processAirportGame];
                break;

//            case APP_MODE_GAME_BALLOON:
//                perLoaded.text = @"";
//                //[self processBalloonGame];
//                break;

        }

        switch (globeMode) {
            case GLOBE_MODE_FREE:
                for (int i = 0; i < 4; i++) {
                    if (_touches[i].active && !_touches[i].used) {

                        if (_touches[i].taps >= 2) {
                            if (zoomLevel < globe_radius + 5.0f) {
                                zoomLevel = globe_radius + 5.0f;
                                tapZoomOn = NO;
                            }
                            else {
                                newZoomLevel = (zoomLevel - 5.0f);
                                tapZoomOn = YES;
                            }
                            //if (zoomLevel<36) {
                            //newZoomLevel = 60;
                            //tapZoomOn = YES;
                            //}
                        }

                        if (rotateTouch == -1) {
                            _touches[i].used = YES;
                            rotateTouch = i;
                            rotateLastX = _touches[rotateTouch].tx;
                            rotateLastY = _touches[rotateTouch].ty;
                            lastRotateY = rotateY;
                            lastRotateX = rotateX;
                            break;
                        }
                        else if (zoomTouch == -1) {
                            _touches[i].used = YES;
                            zoomTouch = i;
                            zoomLastX = _touches[zoomTouch].tx;
                            zoomLastY = _touches[zoomTouch].ty;
                            lastZoomLevel = zoomLevel;
                            rotateLastX = _touches[rotateTouch].tx;
                            rotateLastY = _touches[rotateTouch].ty;
                            tapZoomOn = NO;
                        }
                    }
                }


                if (rotateTouch != -1 && !_touches[rotateTouch].active) {
                    rotateTouch = zoomTouch;
                    rotateLastX = _touches[rotateTouch].tx;
                    rotateLastY = _touches[rotateTouch].ty;
                    lastRotateY = rotateY;
                    lastRotateX = rotateX;
                    zoomTouch = -1;

                }

                if (zoomTouch != -1 && !_touches[zoomTouch].active) {
                    zoomTouch = -1;

                    rotateLastX = _touches[rotateTouch].tx;
                    rotateLastY = _touches[rotateTouch].ty;
                    lastRotateY = rotateY;
                    lastRotateX = rotateX;

                }

                if (tapZoomOn) {
                    if (zoomLevel > newZoomLevel) {
                        zoomLevel -= 0.5f;
                        if ((zoomLevel - newZoomLevel) < 0.5) {
                            tapZoomOn = NO;
                        }
                    }
                    else {
                        if ((newZoomLevel - zoomLevel) < 0.5) {
                            tapZoomOn = NO;
                        }
                        zoomLevel += 0.5f;
                    }
                }

                if (zoomTouch != -1) {
                    int last_dx = abs(rotateLastX - zoomLastX);
                    int last_dy = abs(rotateLastY - zoomLastY);
                    int last_distance = sqrt((last_dx * last_dx) + (last_dy * last_dy));

                    int current_dx = abs(_touches[rotateTouch].tx - _touches[zoomTouch].tx);
                    int current_dy = abs(_touches[rotateTouch].ty - _touches[zoomTouch].ty);
                    int current_distance = sqrt((current_dx * current_dx) + (current_dy * current_dy));

                    int difference = current_distance - last_distance;

                    zoomLevel = lastZoomLevel - (((float) difference) / 20);


                }
                else if (rotateTouch != -1) {
                    if (touchScale <= 0) {
                        touchScale = 1;
                    }
                    float rotate_factor = touchScale;
                    if (rotate_factor <= 0) {
                        rotate_factor = 0.01;
                    }
                    int rotate_dx = _touches[rotateTouch].tx - rotateLastX;
                    int rotate_dy = _touches[rotateTouch].ty - rotateLastY;
                    rotateDY = (((float) (_touches[rotateTouch].tx - _touches[rotateTouch].tlastx)) / rotate_factor);
                    rotateDX = (((float) (_touches[rotateTouch].ty - _touches[rotateTouch].tlasty)) / rotate_factor);
                    rotateY = lastRotateY + (((float) rotate_dx) / rotate_factor);
                    rotateX = lastRotateX + (((float) rotate_dy) / rotate_factor);


                }
                else {

                    rotateY += rotateDY;
                    rotateX += rotateDX;
                    if (rotateDY > 0) {
                        rotateDY -= 0.02;
                        if (rotateDY < 0) {
                            rotateDY = 0;
                        }
                    }
                    if (rotateDY < 0) {
                        rotateDY += 0.02;
                        if (rotateDY > 0) {
                            rotateDY = 0;
                        }
                    }

                    if (rotateDX > 0) {
                        rotateDX -= 0.05;
                        if (rotateDX < 0) {
                            rotateDX = 0;
                        }
                    }
                    if (rotateDX < 0) {
                        rotateDX += 0.05;
                        if (rotateDX > 0) {
                            rotateDX = 0;
                        }
                    }

                }
                if (zoomLevel > 60)
                    zoomLevel = 60;
                if (zoomLevel < 25)
                    zoomLevel = 25;


                break;

//            case GLOBE_MODE_TARGET:
//
//                while (globeTargetY >= 360.0f) {
//                    globeTargetY -= 360.0f;
//                }
//
//                while (globeTargetY < 0.0f) {
//                    globeTargetY += 360.0f;
//                }
//
//                if ((globeTargetY > rotateY && (globeTargetY - rotateY) < 180.0f) || (globeTargetY < rotateY && (rotateY - globeTargetY) >= 180.0f)) {
//                    //positive
//                    float delta = globeTargetY - rotateY;
//                    if (delta < 0) {
//                        delta = -delta;
//                    }
//                    if (delta > 180.0f) {
//                        delta = 360.0f - delta;
//                    }
//
//                    rotateY += (delta * 0.05);
//
//
//                }
//                else {
//                    //negative
//                    float delta = globeTargetY - rotateY;
//                    if (delta < 0) {
//                        delta = -delta;
//                    }
//                    if (delta > 180.0f) {
//                        delta = 360.0f - delta;
//                    }
//
//                    rotateY -= (delta * 0.05);
//
//                }
//
//
//                rotateX += (((globeTargetX) - rotateX) * 0.05);
//
//                zoomLevel += (((globeTargetZoom) - zoomLevel) * 0.05);
//
//                break;
        }


        while (rotateY >= 360.0f) {
            rotateY -= 360.0f;
        }

        while (rotateY < 0.0f) {
            rotateY += 360.0f;
        }

        if (rotateX > 270.0f) {
            rotateX = 270.0f;
        }

        if (rotateX < 90.0f) {
            rotateX = 90.0f;
        }

        if (zoomLevel < globe_radius + 5.0f) {
            zoomLevel = globe_radius + 5.0f;
        }

        if (zoomLevel > 120.0f) {
            zoomLevel = 120.0f;
        }

        if (zoomLevel > 0) {
            point_sprite_scale = 1.0f;/*(globe_radius/(zoomLevel*1.5));*/
        }
        else {
            point_sprite_scale = 0;
        }

        [self setGlobeProjection];

        switch (appMode) {
//            case APP_MODE_FREE:
//
//
//                //this should draw all of them...
////                for (int i = 0; i < [[AirportDataManager sharedInstance] airportCount]; i++) {
////                    [self drawAirport:&airports[i]];
////                }
//
//                /* OLD C DRAWING CODE - DON'T REMOVE
//                for(int i=0;i<NUM_PRIMARY_AIRPORTS;i++){
//					[self drawAirport:&airports[airport_primary_list[i]]];
//				}
//                */
//
//                flight_progress += 0.001;
//                while (flight_progress >= 1.0f) {
//                    flight_progress -= 1.0f;
//                }
//
//
////				for(int i=0;i<MAX_PLANES;i++){
////					if(planes[i].used==YES){
//////						if(planes[i].flight->used==YES){
//////							//					[self drawFlightpath:&flightpaths[i]];
//////						}
////					}
////				}
////
//                for (int i = 0; i < MAX_PLANES; i++) {
//                    if (planes[i].used == YES) {
//                        [self drawPlane:&planes[i]];
//                    }
//                }
//
//                break;

//            case APP_MODE_PLANE: {
//                int i = planeToTrack;
//                if (planes[i].used == YES) {
//                    flightpath_t *fp = &flightpaths[i];
//                    if (fp != NULL && fp->used) {
//                        [self drawAirport:fp->start];
//                        [self drawAirport:fp->end];
//                        [self drawFlightpath:&flightpaths[i]];
//                    }
//
//                    [self drawPlane:&planes[i]];
//
//                }
//            }
//
//
//                break;

            case APP_MODE_GAME_AIRPORT:
                textScale = (1);
                [self drawAirportGame];
                break;
//            case APP_MODE_GAME_BALLOON:
//                textScale = (1);
//                [self drawBalloonGame];
//                break;
        }

        [self getTouchScale];

        //drawing begins

        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        glDisable(GL_DEPTH_TEST);
        glDepthMask(FALSE);

        glEnableClientState(GL_VERTEX_ARRAY);
        glEnableClientState(GL_COLOR_ARRAY);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glEnable(GL_TEXTURE_2D);
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

        [self setOrthoProjection];

        [self setTexture:2];
        [self drawTagSprite:&ts_main[GRAPHICS_maingfx_starBG] X:0 Y:0 Z:0 RL:&rl_back];
        [self drawRenderList:&rl_back];


        [self setGlobeProjection];


        glEnable(GL_DEPTH_TEST);
        glDepthMask(TRUE);

        glCullFace(GL_FRONT);
        glEnable(GL_CULL_FACE);

        glEnable(GL_TEXTURE_2D);
        [self setTexture:1];


        glEnable(GL_LIGHTING);
        glVertexPointer(3, GL_FLOAT, 0, sphere01_coords);
        glEnableClientState(GL_VERTEX_ARRAY);
        glNormalPointer(GL_FLOAT, 0, sphere01_normals);
        glEnableClientState(GL_NORMAL_ARRAY);
        glDisableClientState(GL_COLOR_ARRAY);
        glTexCoordPointer(2, GL_FLOAT, 0, sphere01_texcoords);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glDrawElements(GL_TRIANGLES, (sizeof(sphere01_indices) / sizeof(short)), GL_UNSIGNED_SHORT, sphere01_indices);
#ifdef GLOBECLOUDS
		if (appMode== APP_MODE_GAME_BALLOON ) {
			static	GLfloat angle = 0;
			angle+= 0.05;
			glPushMatrix();
			glBindTexture(GL_TEXTURE_2D, 5);
			glEnable(GL_BLEND);
			glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA);
			glScalef(1.02f, 1.02f, 1.02f);
			glRotatef(angle, 0, 1, 0);
			glEnable(GL_LIGHTING);
			glVertexPointer(3, GL_FLOAT, 0, sphere01_coords);
			glEnableClientState(GL_VERTEX_ARRAY);
			glNormalPointer (GL_FLOAT, 0, sphere01_normals);
			glEnableClientState(GL_NORMAL_ARRAY);
			glDisableClientState(GL_COLOR_ARRAY);
			glTexCoordPointer(2, GL_FLOAT, 0, sphere01_texcoords);
			glEnableClientState(GL_TEXTURE_COORD_ARRAY);
			glDrawElements(GL_TRIANGLES, (sizeof(sphere01_indices)/ sizeof(short)), GL_UNSIGNED_SHORT, sphere01_indices);
			glPopMatrix();
		}
#endif
        glCullFace(GL_FRONT);
        glDisable(GL_CULL_FACE);
        glDisable(GL_LIGHTING);

        glDisable(GL_DEPTH_TEST);
        glPushMatrix();
        glLoadIdentity();
#ifdef GLOBECLOUDS
		if (appMode !=APP_MODE_GAME_BALLOON) {
			[self drawShineyOverlay];
		}
#endif
#ifndef GLOBECLOUDS
        [self drawShineyOverlay];
#endif
        glPopMatrix();
        glEnableClientState(GL_VERTEX_ARRAY);
        glEnableClientState(GL_COLOR_ARRAY);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glEnable(GL_TEXTURE_2D);
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

        [self setOrthoProjection];
        if ((appMode == APP_MODE_GAME_BALLOON || appMode == APP_MODE_GAME_AIRPORT) && drawFrame) {
            [self drawQuad];
        }

        [self setTexture:2];
        [self drawRenderList:&rl_front];
        glPushMatrix();
        glScalef(textScale, textScale, 1);
        [self setTexture:3];
        [self drawRenderList:&rl_gui];
        glPopMatrix();


        glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
        [context presentRenderbuffer:GL_RENDERBUFFER_OES];
    }
}


- (void)initFreeMode {
    appMode = APP_MODE_FREE;
    globeMode = GLOBE_MODE_FREE;
}


- (void)initTrackPlane:(NSString *)plane_name {
    planeToTrack = [self findPlaneWithName:plane_name];
    if (planeToTrack >= 0) {
        globeMode = GLOBE_MODE_TARGET;
        appMode = APP_MODE_PLANE;
        planeToTrack = [self findPlaneWithName:plane_name];
    }
    else {
        globeMode = GLOBE_MODE_FREE;
        appMode = APP_MODE_FREE;
    }

}

- (void)processTrackPlane {

    if (planeToTrack >= 0) {
        globeTargetX = planes[planeToTrack].north + 180.0f;
        globeTargetY = -planes[planeToTrack].east - 90.0f;
        globeTargetZoom = 40.0;
    }

}


- (int)getGameState {
    return gameState;
}

- (void)setGameState:(int)inNewState {
    gameState = inNewState;

    if (inNewState == GS_AIRPORT_FIND) {
        [self chooseRandomAirportForAirportGame];
        gameScore = 0;
        gameTimer = 60000;
        gameTemperature = 0;
    }
    else if (gameState == GS_BALLOON_GAMEPLAY) {
        gameTouch = -1;
        [self setupObjectsForBalloonGame];
        gameScore = 0;
    }
    else if (gameState == GS_BALLOON_CONTINUE) {
        gameObjectCount += 8;
        if (gameObjectCount > MAX_GAME_OBJECTS) {
            gameObjectCount = MAX_GAME_OBJECTS;
        }
        gameMaxObjectSpeed += 0.0005;
        if (gameMaxObjectSpeed > 0.003) {
            gameMaxObjectSpeed = 0.003;
        }
        [self setupObjectsForBalloonGame];
        gameState = GS_BALLOON_GAMEPLAY;
    }
    else if (gameState == GS_BALLOON_END) {
        appMode = APP_MODE_FREE;
        globeMode = GLOBE_MODE_FREE;
    }
}

- (void)endCurrentGame {
    appMode = APP_MODE_FREE;
    globeMode = GLOBE_MODE_FREE;
}


- (void)initAlternateGame {
    if (lastGame > 1 || lastGame < 0) {
        lastGame = 0;
    }

    switch (lastGame) {
        case 0:
            [appPtr showWheresRichardIntro];
            [self initAirportGame];
            break;
        case 1:
            //[appPtr showBalloonIntro];
            [self initBalloonGame];
            break;
    }

    lastGame++;
}


- (void)initAirportGame {
    globeMode = GLOBE_MODE_FREE;
    appMode = APP_MODE_GAME_AIRPORT;
    gameState = GS_AIRPORT_INTRO;
    gameScore = 0;
    gameTimer = 30000;
}

- (void)processAirportGame {
    for (int i = 0; i < 4; i++) {
        switch (gameState) {
            case GS_AIRPORT_INTRO:
                //if(_touches[i].active && !_touches[i].used && _touches[i].ty < 400){




                //					if([self checkForSpriteTouched:&ts_main[GRAPHICS_maingfx_menu] atX:_touches[i].tx atY:_touches[i].ty]){
                //	_touches[i].used=YES;

                //	[self chooseRandomAirportForAirportGame];
                //	gameScore=0;
                //	gameTimer=60000;
                //	gameState=GS_AIRPORT_FIND;
                //	gameTemperature=0;
                //	i=4;
                //	continue;
                //					}
                /*
				 else if([self checkForSpriteTouched:&ts_main[GRAPHICS_maingfx_settings] atX:_touches[i].tx atY:_touches[i].ty]){
				 _touches[i].used=YES;
				 
				 appMode=APP_MODE_FREE;
				 globeMode=GLOBE_MODE_FREE;
				 i=4;
				 continue;
				 }
				 */
                //}

            case GS_AIRPORT_FIND: {
                drawFrame = true;
                gameState = GS_AIRPORT_FIND;
                //if(_touches[i].active && !_touches[i].used){
                /*	if([self checkForSpriteTouched:&ts_main[GRAPHICS_maingfx_settings] atX:_touches[i].tx atY:_touches[i].ty]){
				 _touches[i].used=YES;
				 appMode=APP_MODE_FREE;
				 globeMode=GLOBE_MODE_FREE;
				 i=4;
				 continue;
				 }*/
                float distance = [self getDistanceForSpriteTouched:&airports[gameAirport].sprite AtX:_touches[i].tx atY:_touches[i].ty];
                //if(distance<10.0f){
                if (distance < 20.0f) {
                    _touches[i].used = YES;

                    gameScore++;
                    bransonAnimation = 0;
                    gameState = GS_AIRPORT_FOUND;
                    i = 4;
                    continue;
                }

            }
                break;
            case GS_AIRPORT_RESULT: {
            }
                //if(_touches[i].active && !_touches[i].used && _touches[i].ty<400){
                /*					
				 _touches[i].used=YES;
				 gameState=GS_AIRPORT_INTRO;
				 i=4;
				 continue;
				 if([self checkForSpriteTouched:&ts_main[GRAPHICS_maingfx_menu] atX:_touches[i].tx atY:_touches[i].ty]){
				 _touches[i].used=YES;
				 
				 [self chooseRandomAirportForAirportGame];
				 gameScore=0;
				 gameTimer=30000;
				 gameState=GS_AIRPORT_FIND;
				 i=4;
				 continue;
				 }
				 */
                //					else if([self checkForSpriteTouched:&ts_main[GRAPHICS_maingfx_settings] atX:_touches[i].tx atY:_touches[i].ty]){
                //		_touches[i].used=YES;

                //		appMode=APP_MODE_FREE;
                //		globeMode=GLOBE_MODE_FREE;
                //		i=4;
                //		continue;
                //					}

                //		}
                break;

                //}									
        }


    }


    if (gameState == GS_AIRPORT_FIND) {


        if (gameTimer <= 0) {
            if (gameScore > gameHighScoreAirport) {
                gameHighScoreAirport = gameScore;
                [self saveHighScores];
            }
            gameState = GS_AIRPORT_RESULT;
            drawFrame = false;
            [self.gameInterface showFindRichardResult:gameScore withHighScore:gameHighScoreAirport];
        }
        else
            gameTimer -= 15;
    }

    if (gameState == GS_AIRPORT_FOUND) {
        bransonAnimation++;
        if (bransonAnimation >= 16) {
            [self chooseRandomAirportForAirportGame];
            gameState = GS_AIRPORT_FIND;
        }
    }


}

- (void)drawAirportGame {
    switch (gameState) {
        case GS_AIRPORT_INTRO:
            //[self drawTagSprite:&ts_main[GRAPHICS_maingfx_wheresrichard] X:0 Y:0 Z:0 RL:&rl_front];

        case GS_AIRPORT_FIND:
            //[self drawAirport:&airports[gameAirport]];


            [self drawSpriteOnGlobe:&ts_main[GRAPHICS_maingfx_Brandson] atN:airports[gameAirport].north atE:airports[gameAirport].east resultSprite:&airports[gameAirport].sprite];

            [self drawNumber:(gameTimer / 1000) X:32 Y:10 RL:&rl_gui];
            [self drawNumber:gameScore X:256 Y:10 RL:&rl_gui];
            [self drawString:[airports[gameAirport].name cStringUsingEncoding:NSUTF8StringEncoding] X:134 + 10 Y:10 RL:&rl_gui];

           // [self drawSpriteOnGlobe:&ts_main[GRAPHICS_maingfx_Brandson] atN:airports[gameAirport].north atE:airports[gameAirport].east resultSprite:&airports[gameAirport].sprite];

            //[self drawNumber:(gameTimer / 1000) X:32 Y:10 RL:&rl_gui];
            //[self drawNumber:gameScore X:256 Y:10 RL:&rl_gui];
           // [self drawString:[airports[gameAirport].name cStringUsingEncoding:NSUTF8StringEncoding] X:134 + 10 Y:10 RL:&rl_gui];


            if (rotateTouch != -1) {

                float deltax = (airports[gameAirport].sprite.x - _touches[rotateTouch].tx) / touchScale;
                float deltay = (airports[gameAirport].sprite.y - _touches[rotateTouch].ty) / touchScale;
                if (deltax < 0) deltax = -deltax;
                if (deltay < 0) deltay = -deltay;
                float gameTemperatureFloat = 4.999 - ((deltax + deltay) / 10);
                gameTemperature = (int) gameTemperatureFloat;
                if (gameTemperature < 0) gameTemperature = 0;
                if (gameTemperature > 3) gameTemperature = 3;

            }


            [self drawTagSpritePoint:&ts_main[GRAPHICS_maingfx_thermometer1 + gameTemperature] X:/*_touches[rotateTouch].tx + 48*/295 Y:/*_touches[rotateTouch].ty - 48*/295 Z:0 SCALE:0.35f RL:&rl_front];

          //  [self drawTagSpritePoint:&ts_main[GRAPHICS_maingfx_thermometer1 + gameTemperature] X:/*_touches[rotateTouch].tx + 48*/295 Y:/*_touches[rotateTouch].ty - 48*/295 Z:0 SCALE:0.35f RL:&rl_front];



            break;
        case GS_AIRPORT_FOUND:
            //[self drawAirport:&airports[gameAirport]];

            [self drawSpriteOnGlobe:&ts_main[GRAPHICS_maingfx_Brandson] atN:airports[gameAirport].north atE:airports[gameAirport].east resultSprite:&airports[gameAirport].sprite];
            [self drawSpriteOnGlobe:&ts_main[GRAPHICS_maingfx_brandstar1 + (bransonAnimation >> 2)] atN:airports[gameAirport].north atE:airports[gameAirport].east resultSprite:&airports[gameAirport].sprite];
            //		[self drawNumber:(gameTimer/1000) X:32 Y:32 RL:&rl_gui];
            [self drawNumber:(gameTimer / 1000) X:32 Y:10 RL:&rl_gui];
            [self drawNumber:gameScore X:256 Y:10 RL:&rl_gui];
            [self drawString:[airports[gameAirport].name cStringUsingEncoding:NSUTF8StringEncoding] X:134 + 10 Y:10 RL:&rl_gui];

          //  [self drawSpriteOnGlobe:&ts_main[GRAPHICS_maingfx_Brandson] atN:airports[gameAirport].north atE:airports[gameAirport].east resultSprite:&airports[gameAirport].sprite];
           // [self drawSpriteOnGlobe:&ts_main[GRAPHICS_maingfx_brandstar1 + (bransonAnimation >> 2)] atN:airports[gameAirport].north atE:airports[gameAirport].east resultSprite:&airports[gameAirport].sprite];
            //		[self drawNumber:(gameTimer/1000) X:32 Y:32 RL:&rl_gui];
    //[self drawNumber:(gameTimer / 1000) X:32 Y:10 RL:&rl_gui];
            //[self drawNumber:gameScore X:256 Y:10 RL:&rl_gui];
           // [self drawString:[airports[gameAirport].name cStringUsingEncoding:NSUTF8StringEncoding] X:134 + 10 Y:10 RL:&rl_gui];

            gameTemperature = 0;
            break;
        case GS_AIRPORT_RESULT:
            //[self drawTagSprite:&ts_main[GRAPHICS_maingfx_outoftime] X:0 Y:0 Z:0 RL:&rl_front];
            //[self drawNumber:gameScore X:184 Y:176 RL:&rl_gui];
            //[self drawNumber:gameHighScoreAirport X:184 Y:200 RL:&rl_gui];

            break;
    }

}

- (void)chooseRandomAirportForAirportGame {
    int randomPrimaryAirport = arc4random() % primaryAirportIndexes.count;
    int randomPrimaryAirportIndex = [[primaryAirportIndexes objectAtIndex:randomPrimaryAirport] intValue];
    gameAirport = randomPrimaryAirportIndex;
    //gameAirport=airport_primary_list[abs(rand())%NUM_PRIMARY_AIRPORTS];
}


- (void)initBalloonGame {
    globeMode = GLOBE_MODE_TARGET;
    appMode = APP_MODE_GAME_BALLOON;
    gameState = GS_BALLOON_INTRO;
    gameScore = 0;
    gameTimer = 60000;
    gameMaxObjectSpeed = 0.0005;
    gameObjectCount = 24;
    gameAirport = -1;

}

- (void)setupObjectsForBalloonGame {
//    if (gameAirport != -1) {
//        gameStart = gameAirport;
//    }
//    else {
//        gameStart = (rand() & 65535) % NUM_PRIMARY_AIRPORTS;
//    }
//
//    do {
//        int randomPrimaryAirport = arc4random() % primaryAirportIndexes.count;
//        int randomPrimaryAirportIndex = [[primaryAirportIndexes objectAtIndex:randomPrimaryAirport] intValue];
//        gameAirport = randomPrimaryAirportIndex;
//
//        //gameAirport=airport_primary_list[abs(rand())%NUM_PRIMARY_AIRPORTS];
//        gameDistance = sqrt(((airports[gameStart].east - airports[gameAirport].east) * (airports[gameStart].east - airports[gameAirport].east)) + ((airports[gameStart].north - airports[gameAirport].north) * (airports[gameStart].north - airports[gameAirport].north)));
//    } while (gameDistance < 90.0f);
//
//    gameTimer = 60000;
//
//
//    objRichard.east = airports[gameStart].east;
//    objRichard.north = airports[gameStart].north;
//    objRichard.deast = 0;
//    objRichard.dnorth = 0;
//    objRichard.altitude = 0;
//
//    for (int i = 0; i < gameObjectCount; i++) {
//        objWhirlwind[i].east = (float) ((int) abs(rand()) % 360);
//        objWhirlwind[i].north = (float) (((int) abs(rand()) % 120) - 60);
//        objWhirlwind[i].deast = (float) (((int) abs(rand()) % 100) * (gameMaxObjectSpeed * 2)) - gameMaxObjectSpeed;
//        objWhirlwind[i].dnorth = (float) (((int) abs(rand()) % 100) * (gameMaxObjectSpeed * 2)) - gameMaxObjectSpeed;
//        objWhirlwind[i].altitude = 0;
//    }

}


//- (void)processBalloonGame {
//
//    for (int i = 0; i < 4; i++) {
//        switch (gameState) {
//            case GS_BALLOON_INTRO:
//                //if(_touches[i].active && !_touches[i].used && _touches[i].ty<400){
//                //	_touches[i].used=YES;
//
//                //if([self checkForSpriteTouched:&ts_main[GRAPHICS_maingfx_menu] atX:_touches[i].tx atY:_touches[i].ty]){
//                //		gameTouch=-1;
//                //		[self setupObjectsForBalloonGame];
//                //		gameScore=0;
//                //		gameState=GS_BALLOON_GAMEPLAY;
//                //		i=4;
//                //		continue;
//                //}
//                //else if([self checkForSpriteTouched:&ts_main[GRAPHICS_maingfx_settings] atX:_touches[i].tx atY:_touches[i].ty]){
//                //appMode=APP_MODE_FREE;
//                //	globeMode=GLOBE_MODE_FREE;
//                //	i=4;
//                //		continue;
//                //}
//                //}
//                //break;
//            case GS_BALLOON_GAMEPLAY:
//                drawFrame = true;
//                if (_touches[i].active && !_touches[i].used) {
//                    if (gameTouch == -1) {
//
//
//                        //if([self checkForSpriteTouched:&ts_main[GRAPHICS_maingfx_settings] atX:_touches[i].tx atY:_touches[i].ty]){
//                        //	appMode=APP_MODE_FREE;
//                        //	globeMode=GLOBE_MODE_FREE;
//                        //	i=4;
//                        //	continue;
//                        //}
//                        //else{						
//                        gameTouch = i;
//                        gameTouchLastX = _touches[i].tx;
//                        gameTouchLastY = _touches[i].ty;
//                        //}
//                    }
//                }
//
//
//                break;
//            case GS_BALLOON_WIN:
//                //if(_touches[i].active && !_touches[i].used && _touches[i].ty < 400){
//                //	_touches[i].used=YES;
//
//                //if([self checkForSpriteTouched:&ts_main[GRAPHICS_maingfx_menu] atX:_touches[i].tx atY:_touches[i].ty]){
//
//                //	gameObjectCount+=8;
//                //	if(gameObjectCount > MAX_GAME_OBJECTS){
//                //		gameObjectCount=MAX_GAME_OBJECTS;
//                //	}
//                //	gameMaxObjectSpeed+=0.0005;
//                //	if(gameMaxObjectSpeed>0.003){
//                //		gameMaxObjectSpeed=0.003;
//                //	}
//                //	[self setupObjectsForBalloonGame];
//                //	gameState=GS_BALLOON_GAMEPLAY;
//                //	i=4;
//                //	continue;
//                //}
//                //else if([self checkForSpriteTouched:&ts_main[GRAPHICS_maingfx_settings] atX:_touches[i].tx atY:_touches[i].ty]){
//                //	appMode=APP_MODE_FREE;
//                //	globeMode=GLOBE_MODE_FREE;
//                //	i=4;
//                //	continue;
//                //}.
//
//                //}
//                break;
//            case GS_BALLOON_LOSE:
//            case GS_BALLOON_OUT_OF_TIME:
//
//                //if(_touches[i].active && !_touches[i].used && _touches[i].ty<400){
//                //	_touches[i].used=YES;
//
//                //if([self checkForSpriteTouched:&ts_main[GRAPHICS_maingfx_menu] atX:_touches[i].tx atY:_touches[i].ty]){
//                //	
//                //	[self initBalloonGame];
//                //	i=4;
//                //	continue;
//                //}
//                //else if([self checkForSpriteTouched:&ts_main[GRAPHICS_maingfx_settings] atX:_touches[i].tx atY:_touches[i].ty]){
//                //		appMode=APP_MODE_FREE;
//                //		globeMode=GLOBE_MODE_FREE;
//                //		i=4;
//                //		continue;
//                //}
//
//                //}
//
//                break;
//        }
//    }
//
//    globeTargetX = objRichard.north + 180.0f;
//    globeTargetY = -objRichard.east - 90.0f;
//    globeTargetZoom = 40.0;
//
//
//    if (gameState == GS_BALLOON_GAMEPLAY) {
//
//        if (gameTouch != -1) {
//            if (!_touches[gameTouch].active) {
//                gameTouch = -1;
//            }
//            else {
//                objRichard.deast += (((float) (_touches[gameTouch].tx - gameTouchLastX)) * 0.0003);
//                objRichard.dnorth -= (((float) (_touches[gameTouch].ty - gameTouchLastY)) * 0.0003);
//                gameTouchLastX = _touches[gameTouch].tx;
//                gameTouchLastY = _touches[gameTouch].ty;
//            }
//        }
//
//
//        if (objRichard.deast > 0.8) {
//            objRichard.deast = 0.8;
//        }
//        if (objRichard.deast < -0.8) {
//            objRichard.deast = -0.8;
//        }
//
//        if (objRichard.dnorth > 0.8) {
//            objRichard.dnorth = 0.8;
//        }
//        if (objRichard.dnorth < -0.8) {
//            objRichard.dnorth = -0.8;
//        }
//
//        objRichard.east += objRichard.deast;
//        objRichard.north += objRichard.dnorth;
//
//        objRichard.deast *= 0.99;
//        objRichard.dnorth *= 0.99;
//
//        while (objRichard.east >= 180.0f) {
//            objRichard.east -= 360.0f;
//        }
//        while (objRichard.east < -180.0f) {
//            objRichard.east += 360.0f;
//        }
//
//
//        if (objRichard.north > 60.0f) {
//            objRichard.dnorth -= 0.005f;
//        }
//        if (objRichard.north < -60.0f) {
//            objRichard.dnorth += 0.005f;
//        }
//
//        while (objRichard.north > 85.0f) {
//            objRichard.north = 85.0f;
//        }
//        while (objRichard.north < -85.0f) {
//            objRichard.north = 85.0f;
//        }
//
//
//        for (int i = 0; i < gameObjectCount; i++) {
//            objWhirlwind[i].east += objWhirlwind[i].deast;
//            while (objWhirlwind[i].east >= 180.0f) {
//                objWhirlwind[i].east -= 360.0f;
//            }
//            while (objWhirlwind[i].east < -180.0f) {
//                objWhirlwind[i].east += 360.0f;
//            }
//
//            objWhirlwind[i].north += objWhirlwind[i].dnorth;
//            while (objWhirlwind[i].north >= 90.0f) {
//                objWhirlwind[i].north -= 180.0f;
//            }
//            while (objWhirlwind[i].north < -90.0f) {
//                objWhirlwind[i].north += 180.0f;
//            }
//
//            if (objWhirlwind[i].north >= 60.0f) {
//                objWhirlwind[i].dnorth -= (gameMaxObjectSpeed * 2);
//            }
//
//            if (objWhirlwind[i].north <= -60.0f) {
//                objWhirlwind[i].dnorth += (gameMaxObjectSpeed * 2);
//            }
//        }
//
//        float compassDelta = airports[gameAirport].east - objRichard.east;
//        if (compassDelta < 0) {
//            compassDelta = -compassDelta;
//        }
//        if (compassDelta > 180.0f) {
//            gameCompassAngle = atan2((airports[gameAirport].east + 360.0f) - objRichard.east, airports[gameAirport].north - objRichard.north);
//        }
//        else {
//            gameCompassAngle = atan2(airports[gameAirport].east - objRichard.east, airports[gameAirport].north - objRichard.north);
//        }
//        for (int i = 0; i < 3; i++) {
//            objCompass[i].east = objRichard.east + sin(gameCompassAngle) * ((i + 2) * 2);
//            objCompass[i].north = objRichard.north + cos(gameCompassAngle) * ((i + 2) * 2);
//        }
//
//        float airportProximity = sqrt(((objRichard.east - airports[gameAirport].east) * (objRichard.east - airports[gameAirport].east)) + ((objRichard.north - airports[gameAirport].north) * (objRichard.north - airports[gameAirport].north)));
//        //	printf("%f    (%f,%f)  (%f,%f)\n",airportProximity,objRichard.east,objRichard.north,airports[gameAirport].east,airports[gameAirport].north);
//
//        if (airportProximity < 2.0f) {
//            gameScore += gameDistance;
//            gameState = GS_BALLOON_WIN;
//            drawFrame = false;
//            [self.gameInterface showBalloonWin];
//
//        }
//
//        for (int i = 0; i < gameObjectCount; i++) {
//            if (sqrt(((objRichard.east - objWhirlwind[i].east) * (objRichard.east - objWhirlwind[i].east)) + ((objRichard.north - objWhirlwind[i].north) * (objRichard.north - objWhirlwind[i].north))) < 1.5f) {
//                if (gameScore > gameHighScoreBalloon) {
//                    gameHighScoreBalloon = gameScore;
//                    [self saveHighScores];
//                }
//                gameState = GS_BALLOON_LOSE;
//                drawFrame = false;
//                [self.gameInterface showBalloonLose:gameScore withHighScore:gameHighScoreBalloon];
//            }
//        }
//
//        gameTimer -= 15;
//        if (gameTimer <= 0) {
//            if (gameScore > gameHighScoreBalloon) {
//                gameHighScoreBalloon = gameScore;
//                [self saveHighScores];
//            }
//            gameState = GS_BALLOON_OUT_OF_TIME;
//            drawFrame = false;
//            [self.gameInterface showBalloonLose:gameScore withHighScore:gameHighScoreBalloon];
//        }
//
//
//    }
//
//
//}

- (void)drawBalloonGame {

//    switch (gameState) {
//        case GS_BALLOON_GAMEPLAY:
//
//            [self drawAirport:&airports[gameAirport]];
//
//            for (int i = 0; i < gameObjectCount; i++) {
//                if ((((ticks >> 2) + i) % gameObjectCount) == 0) {
//                    [self drawSpriteOnGlobe:&ts_main[GRAPHICS_maingfx_cloud2] atN:objWhirlwind[i].north atE:objWhirlwind[i].east resultSprite:&objWhirlwind[i].sprite];
//                }
//                else {
//                    [self drawSpriteOnGlobe:&ts_main[GRAPHICS_maingfx_cloud1] atN:objWhirlwind[i].north atE:objWhirlwind[i].east resultSprite:&objWhirlwind[i].sprite];
//                }
//
//            }
//
//
//            [self drawSpriteOnGlobeRotated:&ts_main[GRAPHICS_maingfx_arrow] atN:objCompass[2].north atE:objCompass[2].east withAngle:gameCompassAngle withScale:point_sprite_scale * 2.0f resultSprite:&objCompass[2].sprite];
//
//            drawingBalloon = true;
//            [self drawSpriteOnGlobe:&ts_main[GRAPHICS_maingfx_balloon4] atN:objRichard.north atE:objRichard.east resultSprite:&objRichard.sprite];
//            drawingBalloon = false;
//
//            [self drawNumber:(gameTimer / 1000) X:32 Y:10 RL:&rl_gui];
//            [self drawNumber:gameScore X:256 Y:10 RL:&rl_gui];
//            [self drawString:[airports[gameAirport].name cStringUsingEncoding:NSUTF8StringEncoding] X:134 + 10 Y:10 RL:&rl_gui];
//
//            break;
//
//        case GS_BALLOON_INTRO:
//            //[self drawTagSprite:&ts_main[GRAPHICS_maingfx_balloontrip] X:0 Y:0 Z:0 RL:&rl_front];
//            break;
//        case GS_BALLOON_WIN:
//            //[self drawTagSprite:&ts_main[GRAPHICS_maingfx_welldone] X:0 Y:0 Z:0 RL:&rl_front];
//            //[self drawNumber:gameScore X:256 Y:32 RL:&rl_gui];
//            break;
//        case GS_BALLOON_LOSE:
//            //[self drawTagSprite:&ts_main[GRAPHICS_maingfx_badweather] X:0 Y:0 Z:0 RL:&rl_front];
//            //[self drawNumber:gameScore X:184 Y:176 RL:&rl_gui];
//            //[self drawNumber:gameHighScoreBalloon X:184 Y:200 RL:&rl_gui];
//            break;
//
//        case GS_BALLOON_OUT_OF_TIME:
//            //[self drawTagSprite:&ts_main[GRAPHICS_maingfx_outoftime] X:0 Y:0 Z:0 RL:&rl_front];
//            //[self drawNumber:gameScore X:184 Y:176 RL:&rl_gui];
//            //[self drawNumber:gameHighScoreBalloon X:184 Y:200 RL:&rl_gui];
//            break;
//
//    }


}

- (int)checkForPlaneTouchedAtX:(int)inX atY:(int)inY returnDistance:(float *)inReturnDistance {
    float nearest_distance = 24.0f, current_distance;
    int nearest_index = -1;
    for (int i = 0; i < NUM_AIRPORTS; i++) {
        current_distance = sqrt(((inX - planes[i].sprite.x) * (inX - planes[i].sprite.x)) + ((inY - planes[i].sprite.y) * (inY - planes[i].sprite.y)));
        if (current_distance < nearest_distance) {
            nearest_index = i;
            nearest_distance = current_distance;
        }
    }

    inReturnDistance[0] = nearest_distance;
    return nearest_index;
}


- (int)checkForAirportTouchedAtX:(int)inX atY:(int)inY returnDistance:(float *)inReturnDistance {
    float nearest_distance = 16.0f;
    float current_distance;
    float x_distance;
    float y_distance;
    int nearest_index = -1;
    BOOL found = NO;

    for (int i = 0; i < NUM_AIRPORTS; i++) {
        x_distance = inX - airports[i].sprite.x;
        y_distance = abs(inY - airports[i].sprite.y);
        current_distance = sqrt((x_distance * x_distance) + (y_distance * y_distance));

        // If distance is postive we have tapped to the right of the airport and might be on the name
        // Only makes sense when zoomed in
        if ((zoomLevel < 40) && (x_distance > 0)) {
            NSString *name;// = [appPtr shortAirportNameToCapitalLong:airports[i].name];
            int padding = [name length] * 10; // Assume 10px per letter

            // JFK and LHR are special cases since their text is shifted up 15px on the map (AND ADAM ADDED ABZ AND GLA)
            if ([airports[i].name isEqualToString:@"LHR"] || [airports[i].name isEqualToString:@"JFK"]) {
                y_distance = abs(inY - (airports[i].sprite.y - 15));
            }
            if ([airports[i].name isEqualToString:@"EDI"] || [airports[i].name isEqualToString:@"ABZ"]) {
                y_distance = abs(inY - (airports[i].sprite.y - 10));
            }
            if ([airports[i].name isEqualToString:@"GLA"]) {
                y_distance = abs(inY - (airports[i].sprite.y + 5));
            }


            if ((inX <= airports[i].sprite.x + padding) && (y_distance < 7)) {
                found = YES;
                nearest_index = i;
                nearest_distance = current_distance;
                break;
            }
        }

        if (current_distance < nearest_distance) {
            nearest_index = i;
            nearest_distance = current_distance;
        }
    }

    inReturnDistance[0] = nearest_distance;
    return nearest_index;
}

- (float)getDistanceForSpriteTouched:(sprite_t *)inSprite AtX:(int)inX atY:(int)inY {
    float current_distance = sqrt(((inX - inSprite->x) * (inX - inSprite->x)) + ((inY - inSprite->y) * (inY - inSprite->y)));
    return current_distance;
    //return 1.0;
}

- (void)setOrthoProjection {
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    float width = self.frame.size.width;
    float height = self.frame.size.height;
    glOrthof(0.0f, width, height, 0.0f, -1.0f, 1.0f);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
};

- (void)setGlobeProjection {
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    float width = self.frame.size.width;
    float height = self.frame.size.height;
    float aspect = width / height;
    float top = tanf((0.785398163397448)) * 1;
    float bottom = -top;
    float left = aspect * bottom;
    float right = aspect * top;
    glFrustumf(right, left, bottom, top, 1, 1000);
    glTranslatef(0.0, 0.0, -zoomLevel);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glRotatef(rotateX, 1.0f, 0.0f, 0.0f);
    glRotatef(rotateY, 0.0f, 1.0f, 0.0f);
}


- (BOOL)initPlane:(plane_t *)ap withName:(NSString *)inName withFlight:(flightpath_t *)inFlight withN:(float)inN withE:(float)inE withR:(GLubyte)inR withG:(GLubyte)inG withB:(GLubyte)inB {
    ap->used = YES;
    ap->name = inName;
    ap->north = inN;
    ap->east = inE;
    ap->flight = NULL;
    ap->r = inR;
    ap->g = inG;
    ap->b = inB;

    ap->name = [[NSString alloc] initWithString:inName];

    return YES;
}


- (BOOL)initAirport:(airport_t *)ap withName:(NSString *)inName withN:(float)inN withE:(float)inE withR:(GLubyte)inR withG:(GLubyte)inG withB:(GLubyte)inB isPrimary:(BOOL)isPrim {
	
	ap->name = inName;
    ap->north = inN;
    ap->east = inE;

    ap->r = inR;
    ap->g = inG;
    ap->b = inB;

    ap->isPrimary = isPrim;

    return YES;
}

- (void)positionPlaneOnFlight:(plane_t *)ap atProgress:(float)inProgress {
    float se = ap->flight->start->east;
    float ee = ap->flight->end->east;
    float sn = ap->flight->start->north;
    float en = ap->flight->end->north;

    while ((ap->flight->direction & DIRECTION_EAST) != 0 && ee < se) {
        ee += 360.0f;
    }

    while ((ap->flight->direction & DIRECTION_WEST) != 0 && se < se) {
        se += 360.0f;
    }


    ap->east = ((se * (1.0f - inProgress)) + (ee * inProgress));
    ap->north = ((sn * (1.0f - inProgress)) + (en * inProgress));

    while (ap->east > 360.0f) {
        ap->east -= 360.0f;
    }

}


- (void)getTouchScale {

    float temp_e = (90.0f) / 57.2958;
    float temp_n = (0) / 57.2958;


    float x = (cos(temp_e) * cos(temp_n)) * globe_radius;
    float z = (sin(temp_e) * cos(temp_n)) * globe_radius;
    float y = (sin(temp_n)) * globe_radius;

    float res[4];
    float res2[4];
    glLoadIdentity();
    glRotatef(0.0f, 1.0f, 0.0f, 0.0f);
    glRotatef(0.0f, 0.0f, 1.0f, 0.0f);

    [self getScreenCoordsForX:x forY:y forZ:z resultX:&res[0] resultY:&res[1] resultZ:&res[2] resultMZ:&res[3]];

    temp_e = (100.0f) / 57.2958;
    temp_n = (0) / 57.2958;


    x = (cos(temp_e) * cos(temp_n)) * globe_radius;
    z = (sin(temp_e) * cos(temp_n)) * globe_radius;
    y = (sin(temp_n)) * globe_radius;

    [self getScreenCoordsForX:x forY:y forZ:z resultX:&res2[0] resultY:&res2[1] resultZ:&res2[2] resultMZ:&res2[3]];

    float unit_size = res2[0] - res[0];
    if (unit_size < 0) {
        unit_size = -unit_size;
    }

    if (unit_size < 1.0f) {
        unit_size = 1.0f;
    }
    touchScale = unit_size / 10;
}


- (void)drawSpriteOnGlobe:(TagSprite *)sp atN:(float)inN atE:(float)inE resultSprite:(sprite_t *)inSprite {

    float temp_e = ((-inE + 180.0f)) / 57.2958;
    float temp_n = (-inN) / 57.2958;


    float x = (cos(temp_e) * cos(temp_n)) * globe_radius;
    float z = (sin(temp_e) * cos(temp_n)) * globe_radius;
    float y = (sin(temp_n)) * globe_radius;

    float res[4];

    glLoadIdentity();
    glRotatef(rotateX, 1.0f, 0.0f, 0.0f);
    glRotatef(rotateY, 0.0f, 1.0f, 0.0f);

    [self getScreenCoordsForX:x forY:y forZ:z resultX:&res[0] resultY:&res[1] resultZ:&res[2] resultMZ:&res[3]];

    if (res[3] < (globe_radius * 0.5)) {

        inSprite->x = 99999;
        inSprite->y = 99999;

    }
    else {

        inSprite->x = res[0];
        inSprite->y = res[1];
        if (drawingBalloon)
            [self drawTagSpritePoint:sp X:res[0] Y:res[1] Z:0 SCALE:1 RL:&rl_front];
        else
            [self drawTagSpritePoint:sp X:res[0] Y:res[1] Z:0 SCALE:0.25 RL:&rl_front];
    }


}


- (void)drawSpriteOnGlobeRotated:(TagSprite *)sp atN:(float)inN atE:(float)inE withAngle:(float)angle withScale:(float)inScale resultSprite:(sprite_t *)inSprite {

    float temp_e = ((-inE + 180.0f)) / 57.2958;
    float temp_n = (-inN) / 57.2958;


    float x = (cos(temp_e) * cos(temp_n)) * globe_radius;
    float z = (sin(temp_e) * cos(temp_n)) * globe_radius;
    float y = (sin(temp_n)) * globe_radius;

    float res[4];
    float res2[4];

    glLoadIdentity();
    glRotatef(rotateX, 1.0f, 0.0f, 0.0f);
    glRotatef(rotateY, 0.0f, 1.0f, 0.0f);

    [self getScreenCoordsForX:x forY:y forZ:z resultX:&res[0] resultY:&res[1] resultZ:&res[2] resultMZ:&res[3]];
    temp_n = (-inN - 2.0f) / 57.2958;


    x = (cos(temp_e) * cos(temp_n)) * globe_radius;
    z = (sin(temp_e) * cos(temp_n)) * globe_radius;
    y = (sin(temp_n)) * globe_radius;

    [self getScreenCoordsForX:x forY:y forZ:z resultX:&res2[0] resultY:&res2[1] resultZ:&res2[2] resultMZ:&res2[3]];

    float unit_size = res2[1] - res[1];
    if (unit_size < 0) {
        unit_size = -unit_size;
    }

    if (res[3] < (globe_radius * 0.5)) {

        inSprite->x = 99999;
        inSprite->y = 99999;

    }
    else {

        inSprite->x = res[0];
        inSprite->y = res[1];
        [self drawTagSpritePointRotated:sp X:res[0] Y:res[1] Z:0 SCALE:inScale UNIT:unit_size ANGLE:angle RL:&rl_front];
    }


}


- (void)drawSpriteOnGlobeAlpha:(TagSprite *)sp atN:(float)inN atE:(float)inE withAlpha:(GLubyte)alpha resultSprite:(sprite_t *)inSprite {

    float temp_e = ((-inE + 180.0f)) / 57.2958;
    float temp_n = (-inN) / 57.2958;


    float x = (cos(temp_e) * cos(temp_n)) * globe_radius;
    float z = (sin(temp_e) * cos(temp_n)) * globe_radius;
    float y = (sin(temp_n)) * globe_radius;

    float res[4];

    glLoadIdentity();
    glRotatef(rotateX, 1.0f, 0.0f, 0.0f);
    glRotatef(rotateY, 0.0f, 1.0f, 0.0f);

    [self getScreenCoordsForX:x forY:y forZ:z resultX:&res[0] resultY:&res[1] resultZ:&res[2] resultMZ:&res[3]];

    if (res[3] < (globe_radius * 0.5)) {

        inSprite->x = 99999;
        inSprite->y = 99999;

    }
    else {

        inSprite->x = res[0];
        inSprite->y = res[1];
        [self drawTagSpritePointAlpha:sp X:res[0] Y:res[1] Z:0 SCALE:touchScale / 20 ALPHA:alpha RL:&rl_front];
    }


}


- (void)drawAirport:(airport_t *)ap {

    NSString *airportName = ap->name;
    //NSLog(@"%s %@ isPrim %u", __PRETTY_FUNCTION__, airportName, ap->isPrimary);

	//NSLog(@"Thread: %i", [NSThread currentThread].isMainThread);
		
    if (!ap->isPrimary) {
        return;
    }

    float temp_e = ((-ap->east + 180.0f)) / 57.2958;
    float temp_n = (-ap->north) / 57.2958;


    float x = (cos(temp_e) * cos(temp_n)) * globe_radius;
    float z = (sin(temp_e) * cos(temp_n)) * globe_radius;
    float y = (sin(temp_n)) * globe_radius;

    float res[4];
    float res2[4];

    glLoadIdentity();
    glRotatef(rotateX, 1.0f, 0.0f, 0.0f);
    glRotatef(rotateY, 0.0f, 1.0f, 0.0f);

    [self getScreenCoordsForX:x forY:y forZ:z resultX:&res[0] resultY:&res[1] resultZ:&res[2] resultMZ:&res[3]];
    temp_e = ((-ap->east + 180.0f)) / 57.2958;
    temp_n = (-ap->north - 2.0f) / 57.2958;

    x = (cos(temp_e) * cos(temp_n)) * globe_radius;
    z = (sin(temp_e) * cos(temp_n)) * globe_radius;
    y = (sin(temp_n)) * globe_radius;

    [self getScreenCoordsForX:x forY:y forZ:z resultX:&res2[0] resultY:&res2[1] resultZ:&res2[2] resultMZ:&res2[3]];
    float unit_size = res2[1] - res[1];
    if (unit_size < 0) {
        unit_size = -unit_size;
    }

    AppDelegate *delegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];

    if (res[3] < (globe_radius * 0.5)) {

        ap->sprite.x = 99999;
        ap->sprite.y = 99999;

    }
    else {

        ap->sprite.x = res[0];
        ap->sprite.y = res[1];


        if (airportName && ([airportName compare:myAirport1] == NSOrderedSame) || ([airportName compare:myAirport2] == NSOrderedSame) || ([airportName compare:myAirport3] == NSOrderedSame)) {
            [self drawTagSpritePointRotated:&ts_main[GRAPHICS_maingfx_marker] X:res[0] Y:res[1] Z:0 SCALE:(point_sprite_scale * 2.0f) UNIT:unit_size ANGLE:0.0f RL:&rl_front];
        }
        else {
            [self drawTagSpritePointRotated:&ts_main[GRAPHICS_maingfx_globe_pin] X:res[0] Y:res[1] Z:0 SCALE:point_sprite_scale UNIT:unit_size ANGLE:0.0f RL:&rl_front];
        }
        if (appMode == APP_MODE_PLANE || appMode == APP_MODE_GAME_BALLOON) {
            NSString *name;// = [delegate shortAirportNameToCapitalLong:airportName];
            [self drawString:[name cStringUsingEncoding:NSUTF8StringEncoding] X:res[0] Y:res[1] RL:&rl_gui];
        }
        else {
            if (drawAirportShortName) {
                if (res[0] < 300 && res[1] < 400) {
                    if (zoomLevel < 50 && zoomLevel >= 40) {
                        if ([airportName isEqualToString:@"LHR"] || [airportName isEqualToString:@"JFK"]) {
                            res[1] -= 15;
                        }
                        if ([airportName isEqualToString:@"GLA"]) {
                            res[1] += 5;
                        }
                        if ([airportName isEqualToString:@"EDI"] || [airportName isEqualToString:@"ABZ"]) {
                            res[1] -= 10;
                        }
                        [self drawString:[airportName cStringUsingEncoding:NSUTF8StringEncoding] X:res[0] + 10 Y:res[1] RL:&rl_gui];
                    }
                    if (zoomLevel < 40) {
                        NSString *name;// = [delegate shortAirportNameToCapitalLong:airportName];
                        if ([airportName isEqualToString:@"LHR"] || [airportName isEqualToString:@"JFK"]) {
                            res[1] -= 15;
                        }
                        if ([airportName isEqualToString:@"GLA"]) {
                            res[1] += 5;
                        }
                        if ([airportName isEqualToString:@"EDI"] || [airportName isEqualToString:@"ABZ"]) {
                            res[1] -= 10;
                        }
                        [self drawString:[name cStringUsingEncoding:NSUTF8StringEncoding] X:res[0] + 10 Y:res[1] RL:&rl_gui];
                    }
                }
            }
        }
    }


}


- (void)drawPlane:(plane_t *)ap {

    float temp_e = ((-ap->east + 180.0f)) / 57.2958;
    float temp_n = (-ap->north) / 57.2958;


    float x = (cos(temp_e) * cos(temp_n)) * globe_radius;
    float z = (sin(temp_e) * cos(temp_n)) * globe_radius;
    float y = (sin(temp_n)) * globe_radius;

    float res[4];
    float res2[4];
    glLoadIdentity();
    glRotatef(rotateX, 1.0f, 0.0f, 0.0f);
    glRotatef(rotateY, 0.0f, 1.0f, 0.0f);

    [self getScreenCoordsForX:x forY:y forZ:z resultX:&res[0] resultY:&res[1] resultZ:&res[2] resultMZ:&res[3]];

    temp_e = ((-ap->east + 180.0f)) / 57.2958;
    temp_n = (-ap->north - 2.0f) / 57.2958;


    x = (cos(temp_e) * cos(temp_n)) * globe_radius;
    z = (sin(temp_e) * cos(temp_n)) * globe_radius;
    y = (sin(temp_n)) * globe_radius;

    [self getScreenCoordsForX:x forY:y forZ:z resultX:&res2[0] resultY:&res2[1] resultZ:&res2[2] resultMZ:&res2[3]];

    float unit_size = res2[1] - res[1];
    if (unit_size < 0) {
        unit_size = -unit_size;
    }

    float angle;

    if (ap->flight != NULL) {
        angle = atan2(ap->flight->end->east - ap->east, ap->flight->end->north - ap->north) + 0.785398163397448;
    }

    if (res[3] < (globe_radius * 0.5)) {

        ap->sprite.x = 99999;
        ap->sprite.y = 99999;

    }
    else {

        ap->sprite.x = res[0];
        ap->sprite.y = res[1];

        ap->screen_x = res[0];
        ap->screen_y = res[1];
        if (zoomLevel < 40) {
            //[self drawString:[[ap->ac getFlightNo] cStringUsingEncoding:NSUTF8StringEncoding] X:res[0] Y:res[1] + 10 RL:&rl_gui];
        }
        [self drawTagSpritePointRotated:&ts_main[GRAPHICS_maingfx_plane2] X:res[0] Y:res[1] Z:0 SCALE:point_sprite_scale * 2.0f UNIT:unit_size ANGLE:angle RL:&rl_front];
    }
}


//- (void)drawFlightpath:(flightpath_t *)ap {
//
//    float x, y, z;
//    float res[4];
//
//    int p = 0;
//    float spacing = 2;
//    float current = 0, last = 0, distance = 0;
//    float lx, ly, lz, ix, iy, iz, ifactor;
//
//    glMatrixMode(GL_MODELVIEW);
//    glLoadIdentity();
//    glRotatef(rotateX, 1.0f, 0.0f, 0.0f);
//    glRotatef(rotateY, 0.0f, 1.0f, 0.0f);
//
//    for (int i = 0; i < ap->dot_count; i++) {
//
//
//        lx = x;
//        ly = y;
//        lz = z;
//        last = current;
//
//        x = ap->dots[p++];
//        y = ap->dots[p++];
//        z = ap->dots[p++];
//
//        if (i > 0) {
//            distance = sqrt(((x - lx) * (x - lx)) + ((y - ly) * (y - ly)) + ((z - lz) * (z - lz)));
//            current += distance;
//            if (current >= spacing) {
//                ifactor = ((spacing - last) / (current - last));
//                ix = (1 - ifactor) * lx + ifactor * x;
//                iy = (1 - ifactor) * ly + ifactor * y;
//                iz = (1 - ifactor) * lz + ifactor * z;
//
//                [self getScreenCoordsForX:ix forY:iy forZ:iz resultX:&res[0] resultY:&res[1] resultZ:&res[2] resultMZ:&res[3]];
//
//                float unit_size = touchScale * 16;
//                if (res[3] < (globe_radius * 0.5)) {
//                    //[self drawTagSpritePoint:&ts_main[GRAPHICS_maingfx_marker] X:res[0] Y:res[1] Z:0 SCALE:point_sprite_scale RL:&rl_back];
//                }
//                else {
//                    [self drawTagSpritePointRotated:&ts_main[GRAPHICS_maingfx_marker3] X:res[0] Y:res[1] Z:0 SCALE:(point_sprite_scale * 0.6) UNIT:unit_size ANGLE:0.0f RL:&rl_front];
//                }
//
//                current -= spacing;
//            }
//        }
//    }
//
//
//    current = 0;
//    last = 0;
//    distance = 0;
//
//    p = 0;
//
//    for (int i = 0; i < ap->dot_count2; i++) {
//
//
//        lx = x;
//        ly = y;
//        lz = z;
//        last = current;
//
//        x = ap->dots2[p++];
//        y = ap->dots2[p++];
//        z = ap->dots2[p++];
//
//        if (i > 0) {
//            distance = sqrt(((x - lx) * (x - lx)) + ((y - ly) * (y - ly)) + ((z - lz) * (z - lz)));
//            current += distance;
//            if (current >= spacing) {
//                ifactor = ((spacing - last) / (current - last));
//                ix = (1 - ifactor) * lx + ifactor * x;
//                iy = (1 - ifactor) * ly + ifactor * y;
//                iz = (1 - ifactor) * lz + ifactor * z;
//
//                [self getScreenCoordsForX:ix forY:iy forZ:iz resultX:&res[0] resultY:&res[1] resultZ:&res[2] resultMZ:&res[3]];
//
//                float unit_size = touchScale * 16;
//
//                if (res[3] < (globe_radius * 0.5)) {
//                    //[self drawTagSpritePoint:&ts_main[GRAPHICS_maingfx_marker] X:res[0] Y:res[1] Z:0 SCALE:point_sprite_scale RL:&rl_back];
//                }
//                else {
//                    [self drawTagSpritePointRotated:&ts_main[GRAPHICS_maingfx_marker2] X:res[0] Y:res[1] Z:0 SCALE:(point_sprite_scale * 0.6) UNIT:unit_size ANGLE:0.0f RL:&rl_front];
//                }
//
//                current -= spacing;
//            }
//        }
//    }
//}


- (void)getScreenCoordsForX:(float)inX forY:(float)inY forZ:(float)inZ resultX:(float *)inRX resultY:(float *)inRY resultZ:(float *)inRZ resultMZ:(float *)inRMZ {
    float m[16];
    float p[16];
    int view[4];
    float vr[4];
    float v[] = {0.0f, 0.0f, 0.0f, 1.0f};
    glGetFloatv(GL_PROJECTION_MATRIX, p);
    glGetFloatv(GL_MODELVIEW_MATRIX, m);
    glGetIntegerv(GL_VIEWPORT, view);

    v[0] = inX;
    v[1] = inY;
    v[2] = inZ;

    //translate point by model	we know v[3]=1.0 so we can make a minor saving
    vr[0] = m[0] * v[0] + m[4] * v[1] + m[8] * v[2] + m[12]; //*v[3];
    vr[1] = m[1] * v[0] + m[5] * v[1] + m[9] * v[2] + m[13]; //*v[3];
    vr[2] = m[2] * v[0] + m[6] * v[1] + m[10] * v[2] + m[14]; //*v[3];
    vr[3] = m[3] * v[0] + m[7] * v[1] + m[11] * v[2] + m[15]; //*v[3];

    inRMZ[0] = vr[2];

    //translate result by projection		
    v[3] = p[3] * vr[0] + p[7] * vr[1] + p[11] * vr[2] + p[15] * vr[3];

    if (v[3] == 0.0)    //invalid result
    {
        inRX[0] = 99999.0f;
        inRY[0] = 99999.0f;
        inRZ[0] = 99999.0f;
    }
    else {
        v[0] = p[0] * vr[0] + p[4] * vr[1] + p[8] * vr[2] + p[12] * vr[3];
        v[1] = p[1] * vr[0] + p[5] * vr[1] + p[9] * vr[2] + p[13] * vr[3];
        v[2] = p[2] * vr[0] + p[6] * vr[1] + p[10] * vr[2] + p[14] * vr[3];
        v[0] /= v[3];
        v[1] /= v[3];
        v[2] /= v[3];
        inRX[0] = view[0] + (1.0f + v[0]) * view[2] / 2.0f;
        inRY[0] = view[1] + (1.0f - v[1]) * view[3] / 2.0f;
        inRZ[0] = (1.0f + v[2]) / 2.0f;
    }
}

- (void)RotateVertex:(float *)v withMatrix:(float *)m result:(float *)res {
    for (int i = 0; i < 4; i++) {
        res[i] = 0;
        for (int j = 0; j < 4; j++) {
            res[i] += (v[j] * m[(i * 4) + j]);
        }
    }
}

- (BOOL)initFlightpath:(flightpath_t *)fp withStart:(airport_t *)inStart withEnd:(airport_t *)inEnd withDirection:(int)inDirection {
    fp->used = YES;
    fp->start = inStart;
    fp->end = inEnd;
    fp->direction = 0;
    fp->dots = NULL;
    fp->dots2 = NULL;

    return YES;
}


- (void)buildFlightpathDots:(flightpath_t *)fp withPlane:(plane_t *)pl {
    float start_e, end_e, start_n, end_n;
    int length_e, length_n;
    float length;
    float x, y, z, factor, temp_e, temp_n;

    float why_curve;
    if ((fp->start->north + pl->north) / 2 < 0.0f) {
        why_curve = -1.0f;
    }
    else {
        why_curve = 1.0f;
    }


    if (fp->dots) {
        free(fp->dots);
        fp->dots = NULL;
    }

    if (fp->dots2) {
        free(fp->dots2);
        fp->dots = NULL;
    }

    fp->direction = 0;

    if (fp->direction == 0) {
        if (fp->start->north > pl->north) {
            fp->direction |= DIRECTION_SOUTH;
        }
        else {
            fp->direction |= DIRECTION_NORTH;
        }

        if (fp->start->east > pl->east) {
            if (fp->start->east - pl->east > 180.0f) {
                fp->direction |= DIRECTION_EAST;
            }
            else {
                fp->direction |= DIRECTION_WEST;
            }
        }
        else {
            if (pl->east - fp->start->east > 180.0f) {
                fp->direction |= DIRECTION_WEST;
            }
            else {
                fp->direction |= DIRECTION_EAST;
            }
        }
    }


    if ((fp->direction & DIRECTION_EAST) != 0) {
        start_e = fp->start->east;
        while (start_e < 0.0f) {
            start_e += 360.0f;
        }
        end_e = pl->east;
        while (end_e < 0.0f || end_e < start_e) {
            end_e += 360.0f;
        }

        length_e = (int) (end_e - start_e);
    }
    else if ((fp->direction & DIRECTION_WEST) != 0) {
        start_e = fp->start->east;
        while (start_e < 0.0f) {
            start_e += 360.0f;
        }
        end_e = pl->east;
        while (end_e < 0.0f) {
            end_e += 360.0f;
        }
        while (start_e < end_e) {
            start_e += 360.0f;
        }

        length_e = (int) (start_e - end_e);
    }

    if ((fp->direction & DIRECTION_NORTH) != 0) {
        start_n = fp->start->north;
        while (start_n < 0.0f) {
            start_n += 360.0f;
        }
        end_n = pl->north;
        while (end_n < 0.0f || end_n < start_n) {
            end_n += 360.0f;
        }
        length_n = end_n - start_n;
    }
    else if ((fp->direction & DIRECTION_SOUTH) != 0) {
        start_n = fp->start->north;
        while (start_n < 0.0f) {
            start_n += 360.0f;
        }
        end_n = pl->north;
        while (end_n < 0.0f) {
            end_n += 360.0f;
        }
        while (start_n < end_n) {
            start_n += 360.0f;
        }
        length_n = (int) (start_n - end_n);
    }


    if (length_e < 1) {
        length_e = 1;
    }

    if (length_n < 1) {
        length_n = 1;
    }

    length = ((sqrt((length_e * length_e) + (length_n * length_n))));
    if (length < 1) {
        length = 1;
    }

    fp->dot_count = ((int) length) + 1;
    fp->dots = (float *) malloc(sizeof(float) * (((int) length) + 1) * 3);

#if EAGLVIEW_ENABLE_PRINTS
	NSLog(@"start n = %f, end n=%f, average=%f\n",start_n,end_n,((start_n + end_n)/2));
#endif

    float why = (length / 8) * why_curve;

    for (int i = 0; i <= ((int) length); i++) {
        factor = (((float) i) / (length));
        temp_e = (-((start_e * (1.0f - factor)) + (end_e * factor)) + 180.0f) / 57.2958;
        temp_n = (-((((start_n * (1.0f - factor)) + (end_n * factor))) + (sin(factor * 3.141593) * why))) / 57.2958;

        x = (cos(temp_e) * cos(temp_n)) * globe_radius;
        z = (sin(temp_e) * cos(temp_n)) * globe_radius;
        y = (sin(temp_n)) * globe_radius;

        fp->dots[(i * 3)] = x;
        fp->dots[(i * 3) + 1] = y;
        fp->dots[(i * 3) + 2] = z;
    }


    if ((fp->end->north + pl->north) / 2 < 0.0f) {
        why_curve = -1.0f;
    }
    else {
        why_curve = 1.0f;
    }


    fp->direction = 0;
    if (fp->direction == 0) {
        if (fp->end->north > pl->north) {
            fp->direction |= DIRECTION_SOUTH;
        }
        else {
            fp->direction |= DIRECTION_NORTH;
        }

        if (fp->end->east > pl->east) {
            if (fp->end->east - pl->east > 180.0f) {
                fp->direction |= DIRECTION_EAST;
            }
            else {
                fp->direction |= DIRECTION_WEST;
            }
        }
        else {
            if (pl->east - fp->end->east > 180.0f) {
                fp->direction |= DIRECTION_WEST;
            }
            else {
                fp->direction |= DIRECTION_EAST;
            }
        }
    }


    if ((fp->direction & DIRECTION_EAST) != 0) {
        start_e = fp->end->east;
        while (start_e < 0.0f) {
            start_e += 360.0f;
        }
        end_e = pl->east;
        while (end_e < 0.0f || end_e < start_e) {
            end_e += 360.0f;
        }

        length_e = (int) (end_e - start_e);
    }
    else if ((fp->direction & DIRECTION_WEST) != 0) {
        start_e = fp->end->east;
        while (start_e < 0.0f) {
            start_e += 360.0f;
        }
        end_e = pl->east;
        while (end_e < 0.0f) {
            end_e += 360.0f;
        }
        while (start_e < end_e) {
            start_e += 360.0f;
        }

        length_e = (int) (start_e - end_e);
    }

    if ((fp->direction & DIRECTION_NORTH) != 0) {
        start_n = fp->end->north;
        while (start_n < 0.0f) {
            start_n += 360.0f;
        }
        end_n = pl->north;
        while (end_n < 0.0f || end_n < start_n) {
            end_n += 360.0f;
        }
        length_n = end_n - start_n;
    }
    else if ((fp->direction & DIRECTION_SOUTH) != 0) {
        start_n = fp->end->north;
        while (start_n < 0.0f) {
            start_n += 360.0f;
        }
        end_n = pl->north;
        while (end_n < 0.0f) {
            end_n += 360.0f;
        }
        while (start_n < end_n) {
            start_n += 360.0f;
        }
        length_n = (int) (start_n - end_n);
    }


    if (length_e < 1) {
        length_e = 1;
    }

    if (length_n < 1) {
        length_n = 1;
    }

    length = ((sqrt((length_e * length_e) + (length_n * length_n))));
    if (length < 1) {
        length = 1;
    }

    fp->dot_count2 = ((int) length) + 1;
    fp->dots2 = (float *) malloc(sizeof(float) * (((int) length) + 1) * 3);
#if EAGLVIEW_ENABLE_PRINTS
	NSLog(@"start n = %f, end n=%f, average=%f\n",start_n,end_n,((start_n + end_n)/2));
#endif
    why = (length / 8) * why_curve;

    for (int i = 0; i <= ((int) length); i++) {
        factor = (((float) i) / (length));
        temp_e = (-((start_e * (1.0f - factor)) + (end_e * factor)) + 180.0f) / 57.2958;
        temp_n = (-((((start_n * (1.0f - factor)) + (end_n * factor))) + (sin(factor * 3.141593) * why))) / 57.2958;


        x = (cos(temp_e) * cos(temp_n)) * globe_radius;
        z = (sin(temp_e) * cos(temp_n)) * globe_radius;
        y = (sin(temp_n)) * globe_radius;

        fp->dots2[(i * 3)] = x;
        fp->dots2[(i * 3) + 1] = y;
        fp->dots2[(i * 3) + 2] = z;
    }


}


- (void)buildFlightpathGraphic:(flightpath_t *)fp withPlane:(plane_t *)pl {
    float start_e, end_e, start_n, end_n;
    int length_e, length_n, length;
    float x, y, z, factor, temp_e, temp_n, fr, fg, fb;

    fp->direction = 0;

    if (fp->direction == 0) {
        if (fp->start->north > pl->north) {
            fp->direction |= DIRECTION_SOUTH;
        }
        else {
            fp->direction |= DIRECTION_NORTH;
        }

        if (fp->start->east > pl->east) {
            if (fp->start->east - pl->east > 180.0f) {
                fp->direction |= DIRECTION_EAST;
            }
            else {
                fp->direction |= DIRECTION_WEST;
            }
        }
        else {
            if (pl->east - fp->start->east > 180.0f) {
                fp->direction |= DIRECTION_WEST;
            }
            else {
                fp->direction |= DIRECTION_EAST;
            }
        }
    }


    if ((fp->direction & DIRECTION_EAST) != 0) {
        start_e = fp->start->east;
        while (start_e < 0.0f) {
            start_e += 360.0f;
        }
        end_e = pl->east;
        while (end_e < 0.0f || end_e < start_e) {
            end_e += 360.0f;
        }

        length_e = (int) (end_e - start_e);
    }
    else if ((fp->direction & DIRECTION_WEST) != 0) {
        start_e = fp->start->east;
        while (start_e < 0.0f) {
            start_e += 360.0f;
        }
        end_e = pl->east;
        while (end_e < 0.0f) {
            end_e += 360.0f;
        }
        while (start_e < end_e) {
            start_e += 360.0f;
        }

        length_e = (int) (start_e - end_e);
    }

    if ((fp->direction & DIRECTION_NORTH) != 0) {
        start_n = fp->start->north;
        while (start_n < 0.0f) {
            start_n += 360.0f;
        }
        end_n = pl->north;
        while (end_n < 0.0f || end_n < start_n) {
            end_n += 360.0f;
        }
        length_n = end_n - start_n;
    }
    else if ((fp->direction & DIRECTION_SOUTH) != 0) {
        start_n = fp->start->north;
        while (start_n < 0.0f) {
            start_n += 360.0f;
        }
        end_n = pl->north;
        while (end_n < 0.0f) {
            end_n += 360.0f;
        }
        while (start_n < end_n) {
            start_n += 360.0f;
        }
        length_n = (int) (start_n - end_n);
    }


    if (length_e < 1) {
        length_e = 1;
    }

    if (length_n < 1) {
        length_n = 1;
    }

    length = sqrt((length_e * length_e) + (length_n * length_n));
    if (length < 1) {
        length = 1;
    }

    fp->graphic = [self allocateNewGraphics:GL_TRIANGLES withVertices:((length + 1) * 2) withIndices:(length * 6) withTexCoords:NO withNormals:NO withColor:YES];


    {

    }


    for (int i = 0; i <= length; i++) {
        factor = (((float) i) / ((float) length));
        temp_e = (-((start_e * (1.0f - factor)) + (end_e * factor)) + 180.0f) / 57.2958;
        temp_n = (-((start_n * (1.0f - factor)) + (end_n * factor))) / 57.2958;

        x = (cos(temp_e) * cos(temp_n)) * globe_radius;
        z = (sin(temp_e) * cos(temp_n)) * globe_radius;
        y = (sin(temp_n)) * globe_radius;

        //NSLog(@"%d:   x=%f  y=%f  z=%f",i,x,y,z);

        fp->graphic->vertex[(i * 6)] = x;
        fp->graphic->vertex[(i * 6) + 1] = y;
        fp->graphic->vertex[(i * 6) + 2] = z;

        fr = ((((float) fp->start->r) * (1.0f - factor)) + (((float) fp->end->r) * (factor)));
        fg = ((((float) fp->start->g) * (1.0f - factor)) + (((float) fp->end->g) * (factor)));
        fb = ((((float) fp->start->b) * (1.0f - factor)) + (((float) fp->end->b) * (factor)));

        fp->graphic->color[(i * 8)] = (GLubyte) fr;
        fp->graphic->color[(i * 8) + 1] = (GLubyte) fg;
        fp->graphic->color[(i * 8) + 2] = (GLubyte) fb;
        fp->graphic->color[(i * 8) + 3] = 255;


        x += 1;
        z += 1;
        y += 1;

        fp->graphic->vertex[(i * 6) + 3] = x;
        fp->graphic->vertex[(i * 6) + 4] = y;
        fp->graphic->vertex[(i * 6) + 5] = z;

        fp->graphic->color[(i * 8) + 4] = 255;
        fp->graphic->color[(i * 8) + 5] = 255;
        fp->graphic->color[(i * 8) + 6] = 255;
        fp->graphic->color[(i * 8) + 7] = 255;

        fp->graphic->vertex_count += 2;
    }

    for (int i = 0; i < length; i++) {
        fp->graphic->index[(i * 6)] = (GLshort) (i * 2);
        fp->graphic->index[(i * 6) + 1] = (GLshort) ((i * 2) + 1);
        fp->graphic->index[(i * 6) + 2] = (GLshort) ((i * 2) + 3);
        fp->graphic->index[(i * 6) + 3] = (GLshort) (i * 2);
        fp->graphic->index[(i * 6) + 4] = (GLshort) ((i * 2) + 2);
        fp->graphic->index[(i * 6) + 5] = (GLshort) ((i * 2) + 3);

        fp->graphic->index_count += 6;
    }


    fp->direction = 0;


    if (fp->direction == 0) {
        if (fp->start->north > pl->north) {
            fp->direction |= DIRECTION_SOUTH;
        }
        else {
            fp->direction |= DIRECTION_NORTH;
        }

        if (fp->start->east > pl->east) {
            if (fp->start->east - pl->east > 180.0f) {
                fp->direction |= DIRECTION_EAST;
            }
            else {
                fp->direction |= DIRECTION_WEST;
            }
        }
        else {
            if (pl->east - fp->start->east > 180.0f) {
                fp->direction |= DIRECTION_WEST;
            }
            else {
                fp->direction |= DIRECTION_EAST;
            }
        }
    }


    if ((fp->direction & DIRECTION_EAST) != 0) {
        start_e = fp->start->east;
        while (start_e < 0.0f) {
            start_e += 360.0f;
        }
        end_e = pl->east;
        while (end_e < 0.0f || end_e < start_e) {
            end_e += 360.0f;
        }

        length_e = (int) (end_e - start_e);
    }
    else if ((fp->direction & DIRECTION_WEST) != 0) {
        start_e = fp->start->east;
        while (start_e < 0.0f) {
            start_e += 360.0f;
        }
        end_e = pl->east;
        while (end_e < 0.0f) {
            end_e += 360.0f;
        }
        while (start_e < end_e) {
            start_e += 360.0f;
        }

        length_e = (int) (start_e - end_e);
    }

    if ((fp->direction & DIRECTION_NORTH) != 0) {
        start_n = fp->start->north;
        while (start_n < 0.0f) {
            start_n += 360.0f;
        }
        end_n = pl->north;
        while (end_n < 0.0f || end_n < start_n) {
            end_n += 360.0f;
        }
        length_n = end_n - start_n;
    }
    else if ((fp->direction & DIRECTION_SOUTH) != 0) {
        start_n = fp->start->north;
        while (start_n < 0.0f) {
            start_n += 360.0f;
        }
        end_n = pl->north;
        while (end_n < 0.0f) {
            end_n += 360.0f;
        }
        while (start_n < end_n) {
            start_n += 360.0f;
        }
        length_n = (int) (start_n - end_n);
    }


    if (length_e < 1) {
        length_e = 1;
    }

    if (length_n < 1) {
        length_n = 1;
    }

    length = sqrt((length_e * length_e) + (length_n * length_n));
    if (length < 1) {
        length = 1;
    }

    fp->graphic = [self allocateNewGraphics:GL_TRIANGLES withVertices:((length + 1) * 2) withIndices:(length * 6) withTexCoords:NO withNormals:NO withColor:YES];


    {

    }


    for (int i = 0; i <= length; i++) {
        factor = (((float) i) / ((float) length));
        temp_e = (-((start_e * (1.0f - factor)) + (end_e * factor)) + 180.0f) / 57.2958;
        temp_n = (-((start_n * (1.0f - factor)) + (end_n * factor))) / 57.2958;

        x = (cos(temp_e) * cos(temp_n)) * globe_radius;
        z = (sin(temp_e) * cos(temp_n)) * globe_radius;
        y = (sin(temp_n)) * globe_radius;

        //NSLog(@"%d:   x=%f  y=%f  z=%f",i,x,y,z);

        fp->graphic->vertex[(i * 6)] = x;
        fp->graphic->vertex[(i * 6) + 1] = y;
        fp->graphic->vertex[(i * 6) + 2] = z;

        fr = ((((float) fp->start->r) * (1.0f - factor)) + (((float) fp->end->r) * (factor)));
        fg = ((((float) fp->start->g) * (1.0f - factor)) + (((float) fp->end->g) * (factor)));
        fb = ((((float) fp->start->b) * (1.0f - factor)) + (((float) fp->end->b) * (factor)));

        fp->graphic->color[(i * 8)] = (GLubyte) fr;
        fp->graphic->color[(i * 8) + 1] = (GLubyte) fg;
        fp->graphic->color[(i * 8) + 2] = (GLubyte) fb;
        fp->graphic->color[(i * 8) + 3] = 255;


        x += 1;
        z += 1;
        y += 1;

        fp->graphic->vertex[(i * 6) + 3] = x;
        fp->graphic->vertex[(i * 6) + 4] = y;
        fp->graphic->vertex[(i * 6) + 5] = z;

        fp->graphic->color[(i * 8) + 4] = 255;
        fp->graphic->color[(i * 8) + 5] = 255;
        fp->graphic->color[(i * 8) + 6] = 255;
        fp->graphic->color[(i * 8) + 7] = 255;

        fp->graphic->vertex_count += 2;
    }

    for (int i = 0; i < length; i++) {
        fp->graphic->index[(i * 6)] = (GLshort) (i * 2);
        fp->graphic->index[(i * 6) + 1] = (GLshort) ((i * 2) + 1);
        fp->graphic->index[(i * 6) + 2] = (GLshort) ((i * 2) + 3);
        fp->graphic->index[(i * 6) + 3] = (GLshort) (i * 2);
        fp->graphic->index[(i * 6) + 4] = (GLshort) ((i * 2) + 2);
        fp->graphic->index[(i * 6) + 5] = (GLshort) ((i * 2) + 3);

        fp->graphic->index_count += 6;
    }


}


- (void)buildFlightpathGraphic:(flightpath_t *)fp {
    float start_e, end_e, start_n, end_n;
    int length_e, length_n, length;


    if (fp->direction == 0) {
        if (fp->start->north > fp->end->north) {
            fp->direction |= DIRECTION_SOUTH;
        }
        else {
            fp->direction |= DIRECTION_NORTH;
        }

        if (fp->start->east > fp->end->east) {
            if (fp->start->east - fp->end->east > 180.0f) {
                fp->direction |= DIRECTION_EAST;
            }
            else {
                fp->direction |= DIRECTION_WEST;
            }
        }
        else {
            if (fp->end->east - fp->start->east > 180.0f) {
                fp->direction |= DIRECTION_WEST;
            }
            else {
                fp->direction |= DIRECTION_EAST;
            }
        }
    }


    if ((fp->direction & DIRECTION_EAST) != 0) {
        start_e = fp->start->east;
        while (start_e < 0.0f) {
            start_e += 360.0f;
        }
        end_e = fp->end->east;
        while (end_e < 0.0f || end_e < start_e) {
            end_e += 360.0f;
        }

        length_e = (int) (end_e - start_e);
    }
    else if ((fp->direction & DIRECTION_WEST) != 0) {
        start_e = fp->start->east;
        while (start_e < 0.0f) {
            start_e += 360.0f;
        }
        end_e = fp->end->east;
        while (end_e < 0.0f) {
            end_e += 360.0f;
        }
        while (start_e < end_e) {
            start_e += 360.0f;
        }

        length_e = (int) (start_e - end_e);
    }

    if ((fp->direction & DIRECTION_NORTH) != 0) {
        start_n = fp->start->north;
        while (start_n < 0.0f) {
            start_n += 360.0f;
        }
        end_n = fp->end->north;
        while (end_n < 0.0f || end_n < start_n) {
            end_n += 360.0f;
        }
        length_n = end_n - start_n;
    }
    else if ((fp->direction & DIRECTION_SOUTH) != 0) {
        start_n = fp->start->north;
        while (start_n < 0.0f) {
            start_n += 360.0f;
        }
        end_n = fp->end->north;
        while (end_n < 0.0f) {
            end_n += 360.0f;
        }
        while (start_n < end_n) {
            start_n += 360.0f;
        }
        length_n = (int) (start_n - end_n);
    }


    if (length_e < 1) {
        length_e = 1;
    }

    if (length_n < 1) {
        length_n = 1;
    }

    length = sqrt((length_e * length_e) + (length_n * length_n));
    if (length < 1) {
        length = 1;
    }

    fp->graphic = [self allocateNewGraphics:GL_TRIANGLES withVertices:((length + 1) * 2) withIndices:(length * 6) withTexCoords:NO withNormals:NO withColor:YES];
    float x, y, z, factor, temp_e, temp_n, fr, fg, fb;

    for (int i = 0; i <= length; i++) {
        factor = (((float) i) / ((float) length));
        temp_e = (-((start_e * (1.0f - factor)) + (end_e * factor)) + 180.0f) / 57.2958;
        temp_n = (-((start_n * (1.0f - factor)) + (end_n * factor))) / 57.2958;

        x = (cos(temp_e) * cos(temp_n)) * globe_radius;
        z = (sin(temp_e) * cos(temp_n)) * globe_radius;
        y = (sin(temp_n)) * globe_radius;
#if EAGLVIEW_ENABLE_PRINTS
		NSLog(@"%d:   x=%f  y=%f  z=%f",i,x,y,z);
#endif
        fp->graphic->vertex[(i * 6)] = x;
        fp->graphic->vertex[(i * 6) + 1] = y;
        fp->graphic->vertex[(i * 6) + 2] = z;

        fr = ((((float) fp->start->r) * (1.0f - factor)) + (((float) fp->end->r) * (factor)));
        fg = ((((float) fp->start->g) * (1.0f - factor)) + (((float) fp->end->g) * (factor)));
        fb = ((((float) fp->start->b) * (1.0f - factor)) + (((float) fp->end->b) * (factor)));

        fp->graphic->color[(i * 8)] = (GLubyte) fr;
        fp->graphic->color[(i * 8) + 1] = (GLubyte) fg;
        fp->graphic->color[(i * 8) + 2] = (GLubyte) fb;
        fp->graphic->color[(i * 8) + 3] = 255;


        x += 1;
        z += 1;
        y += 1;

        fp->graphic->vertex[(i * 6) + 3] = x;
        fp->graphic->vertex[(i * 6) + 4] = y;
        fp->graphic->vertex[(i * 6) + 5] = z;

        fp->graphic->color[(i * 8) + 4] = 255;
        fp->graphic->color[(i * 8) + 5] = 255;
        fp->graphic->color[(i * 8) + 6] = 255;
        fp->graphic->color[(i * 8) + 7] = 255;

        fp->graphic->vertex_count += 2;
    }

    for (int i = 0; i < length; i++) {
        fp->graphic->index[(i * 6)] = (GLshort) (i * 2);
        fp->graphic->index[(i * 6) + 1] = (GLshort) ((i * 2) + 1);
        fp->graphic->index[(i * 6) + 2] = (GLshort) ((i * 2) + 3);
        fp->graphic->index[(i * 6) + 3] = (GLshort) (i * 2);
        fp->graphic->index[(i * 6) + 4] = (GLshort) ((i * 2) + 2);
        fp->graphic->index[(i * 6) + 5] = (GLshort) ((i * 2) + 3);

        fp->graphic->index_count += 6;
    }


}


- (void)freeGraphics:(graphic_t *)g {

    if (!g) {
        return;
    }

    if (g->vertex) {
        free(g->vertex);
    }
    g->vertex_count = 0;
    g->vertex_size = 0;

    if (g->index) {
        free(g->index);
    }
    g->index_count = 0;
    g->index_size = 0;

    if (g->texcoord) {
        free(g->texcoord);
    }

    if (g->normal) {
        free(g->normal);
    }

    if (g->color) {
        free(g->color);
    }

}

- (graphic_t *)allocateNewGraphics:(int)inType withVertices:(int)inVertices withIndices:(int)inIndices withTexCoords:(BOOL)inTexCoords withNormals:(BOOL)inNormals withColor:(BOOL)inColor {
    graphic_t *g = (graphic_t *) malloc(sizeof(graphic_t));

    g->type = inType;

    if (inVertices > 0) {
        g->vertex = (float *) malloc(sizeof(float) * inVertices * 3);
        g->vertex_size = inVertices;
    }
    else {
        g->vertex = NULL;
        g->vertex_size = 0;
    }
    g->vertex_count = 0;

    if (inIndices > 0) {
        g->index = (GLshort *) malloc(sizeof(GLshort) * inIndices);
        g->index_size = inIndices;
    }
    else {
        g->index = NULL;
        g->index_size = 0;
    }
    g->index_count = 0;


    if (inTexCoords) {
        g->texcoord = (float *) malloc(sizeof(float) * g->vertex_size * 2);
    }
    else {
        g->texcoord = NULL;
    }

    if (inNormals) {
        g->normal = (float *) malloc(sizeof(float) * g->vertex_size * 3);
    }
    else {
        g->normal = NULL;
    }

    if (inColor) {
        g->color = (GLubyte *) malloc(sizeof(GLubyte) * g->vertex_size * 4);
    }
    else {
        g->color = NULL;
    }

    return g;


}

- (BOOL)drawSpriteList:(graphic_t *)g {
    if (g->vertex) {
        glVertexPointer(2, GL_FLOAT, 0, g->vertex);
        glEnableClientState(GL_VERTEX_ARRAY);
    }
    else {
        return NO;
    }

    if (g->color) {
        glColorPointer(4, GL_UNSIGNED_BYTE, 0, g->color);
        glEnableClientState(GL_COLOR_ARRAY);
    }
    else {
        glDisableClientState(GL_COLOR_ARRAY);
    }

    if (g->texcoord) {
        glTexCoordPointer(2, GL_FLOAT, 0, g->texcoord);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glEnable(GL_TEXTURE_2D);
    }
    else {
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        glDisable(GL_TEXTURE_2D);
    }

    glDrawArrays(GL_TRIANGLES, 0, g->vertex_count);

    return YES;
}


- (BOOL)drawGraphicIndices:(graphic_t *)g {

    if (g->vertex) {
        glVertexPointer(3, GL_FLOAT, 0, g->vertex);
        glEnableClientState(GL_VERTEX_ARRAY);
    }
    else {
        return NO;
    }

    if (g->color) {
        glColorPointer(4, GL_UNSIGNED_BYTE, 0, g->color);
        glEnableClientState(GL_COLOR_ARRAY);
    }
    else {
        glDisableClientState(GL_COLOR_ARRAY);
    }

    if (g->texcoord) {
        glTexCoordPointer(2, GL_FLOAT, 0, g->texcoord);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glEnable(GL_TEXTURE_2D);
    }
    else {
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        glDisable(GL_TEXTURE_2D);
    }

    glDrawElements(g->type, g->index_count, GL_UNSIGNED_SHORT, g->index);

    return YES;
}


- (BOOL)addSprite:(sprite_t *)s toList:(graphic_t *)g {
    if (g->vertex_count <= g->vertex_size - 4) {
        g->vertex[(g->vertex_count * 2)] = s->x;
        g->vertex[(g->vertex_count * 2) + 1] = s->y;
        g->vertex[(g->vertex_count * 2) + 2] = s->x + s->w;
        g->vertex[(g->vertex_count * 2) + 3] = s->y;
        g->vertex[(g->vertex_count * 2) + 4] = s->x;
        g->vertex[(g->vertex_count * 2) + 5] = s->y + s->h;
        g->vertex[(g->vertex_count * 2) + 6] = s->x + s->w;
        g->vertex[(g->vertex_count * 2) + 7] = s->x + s->h;

        g->color[(g->vertex_count * 4)] = 255;
        g->color[(g->vertex_count * 4) + 1] = 0;
        g->color[(g->vertex_count * 4) + 2] = 0;
        g->color[(g->vertex_count * 4) + 3] = 255;

        g->color[(g->vertex_count * 4)] = 0;
        g->color[(g->vertex_count * 4) + 1] = 255;
        g->color[(g->vertex_count * 4) + 2] = 0;
        g->color[(g->vertex_count * 4) + 3] = 255;

        g->color[(g->vertex_count * 4)] = 0;
        g->color[(g->vertex_count * 4) + 1] = 0;
        g->color[(g->vertex_count * 4) + 2] = 255;
        g->color[(g->vertex_count * 4) + 3] = 255;

        g->color[(g->vertex_count * 4)] = 255;
        g->color[(g->vertex_count * 4) + 1] = 255;
        g->color[(g->vertex_count * 4) + 2] = 0;
        g->color[(g->vertex_count * 4) + 3] = 255;

        g->vertex_count += 4;

        return YES;
    }
    else {
        return NO;
    }
}

- (void)initRenderList:(RenderList *)rl withSize:(int)inSize {
    int size = inSize;
    rl->vertex = (GLfloat *) malloc(sizeof(GLfloat) * 6 * size);
    rl->texcoord = (GLfloat *) malloc(sizeof(GLfloat) * 6 * size);
    rl->color = (GLubyte *) malloc(sizeof(GLubyte) * 12 * size);
    rl->size = size;

    [self resetRenderList:rl];
}

- (void)resetRenderList:(RenderList *)rl {
    rl->count = 0;
    rl->vertex_index = 0;
    rl->texcoord_index = 0;
    rl->color_index = 0;
}

- (void)freeRenderList:(RenderList *)rl {
    if (rl->vertex) {
        free(rl->vertex);
        rl->vertex = NULL;
    }

    if (rl->texcoord) {
        free(rl->texcoord);
        rl->texcoord = NULL;
    }

    if (rl->color) {
        free(rl->color);
        rl->color = NULL;
    }
}


- (void)drawRenderList:(RenderList *)rl {
    glVertexPointer(2, GL_FLOAT, 0, rl->vertex);
    glTexCoordPointer(2, GL_FLOAT, 0, rl->texcoord);
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, rl->color);
    glDrawArrays(GL_TRIANGLES, 0, rl->count * 3); //diagonal

}


- (void)loadTexture:(int)index {
    NSString *fn = texture_files[index];

#if EAGLVIEW_ENABLE_PRINTS
	NSLog(@"EAGLVIEW::Attempting to load %@",fn);
#endif

    CGImageRef textureImage = [UIImage imageNamed:fn].CGImage;
    if (textureImage == nil) {
#if EAGLVIEW_ENABLE_PRINTS
        NSLog(@"EAGLVIEW::Failed to load texture image");
#endif
        return;
    }

    NSInteger texWidth = CGImageGetWidth(textureImage);
    NSInteger texHeight = CGImageGetHeight(textureImage);


#if EAGLVIEW_ENABLE_PRINTS
	NSLog(@"EAGLVIEW::Mallocing memory...");
#endif
    GLubyte *textureData = (GLubyte *) malloc(texWidth * texHeight * 4);

#if EAGLVIEW_ENABLE_PRINTS
	NSLog(@"EAGLVIEW::Creating Texture Context...");
#endif


    CGContextRef textureContext = CGBitmapContextCreate(textureData,
            texWidth,
            texHeight,
            8,
            texWidth * 4,
            CGImageGetColorSpace(textureImage),
            kCGImageAlphaPremultipliedLast);

#if EAGLVIEW_ENABLE_PRINTS
	NSLog(@"EAGLVIEW::Drawing Image onto context...");
#endif
    //EXC_BAD_ACCESS seems to be from here...
    CGContextDrawImage(textureContext, CGRectMake(0.0, 0.0, (float) texWidth, (float) texHeight), textureImage);
#if EAGLVIEW_ENABLE_PRINTS
	NSLog(@"EAGLVIEW::Releasing Context...");
#endif
    CGContextRelease(textureContext);


#if EAGLVIEW_ENABLE_PRINTS
	NSLog(@"EAGLVIEW::Malloccing Texture Mask...");
#endif
    //texture_mask[index]=(unsigned int *)malloc((((texWidth/32)+1) * texHeight)*sizeof(unsigned int));


#if EAGLVIEW_ENABLE_PRINTS
	NSLog(@"EAGLVIEW::Loading Tex Data...");
#endif
    glGenTextures(1, &textures[index]);
    glBindTexture(GL_TEXTURE_2D, textures[index]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texWidth, texHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);

    free(textureData);

    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glEnable(GL_TEXTURE_2D);
#if EAGLVIEW_ENABLE_PRINTS
	NSLog(@"loaded texture %@", fn);
#endif

}

- (void)setTexture:(int)index {
    glBindTexture(GL_TEXTURE_2D, index);

}


- (void)loadTagSpriteData:(NSString *)fn DEST:(TagSprite *)d TEX_W:(float)tex_w TEX_H:(float)tex_h {
    NSData *dataobj = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:fn ofType:@"bin"]];
    GLubyte *data = (GLubyte *) malloc(sizeof(GLubyte) * [dataobj length]);
    [dataobj getBytes:data];

    for (int i = 0; i < [dataobj length]; i++) {
#if EAGLVIEW_ENABLE_PRINTS
		NSLog(@"%d - %d",i,data[i]);
#endif
    }

    int p = 0;
    int sprite_count = (((int) data[p]) << 8) | ((int) data[p + 1]);

    p += 4;

    //	d=(PVCSprite *)malloc(sizeof(TagSprite) * sprite_count);

    for (int i = 0; i < sprite_count; i++) {
        d[i].x = (((int) data[p]) << 8) | ((int) data[p + 1]);
        d[i].y = (((int) data[p + 2]) << 8) | ((int) data[p + 3]);
        d[i].w = (((int) data[p + 4]) << 8) | ((int) data[p + 5]);
        d[i].h = (((int) data[p + 6]) << 8) | ((int) data[p + 7]);
        d[i].ox = (((int) data[p + 8]) << 8) | ((int) data[p + 9]);
        d[i].oy = (((int) data[p + 10]) << 8) | ((int) data[p + 11]);

        d[i]._x = d[i].x / tex_w;
        d[i]._y = d[i].y / tex_h;
        d[i]._w = d[i].w / tex_w;
        d[i]._h = d[i].h / tex_h;
        d[i]._ox = d[i].ox / tex_w;
        d[i]._oy = d[i].oy / tex_h;

        p += 12;
    }
#if EAGLVIEW_ENABLE_PRINTS
	NSLog(@"loaded %d sprites from %@", sprite_count,fn);
#endif
    free(data);
}


- (BOOL)checkForSpriteTouched:(TagSprite *)sprite atX:(float)x atY:(float)y {

    float minX = sprite->ox;
    float minY = sprite->oy;
    float maxX = minX + sprite->w;
    float maxY = minY + sprite->h;

    if (x >= minX && x < maxX && y >= minY && y < maxY) {
        return YES;
    }
    else {
        return NO;
    }
}


- (void)drawTagSprite:(TagSprite *)sprite X:(float)x Y:(float)y Z:(float)z RL:(RenderList *)rl {

    rl->vertex[rl->vertex_index++] = sprite->ox + x;
    rl->vertex[rl->vertex_index++] = sprite->oy + y;

    rl->vertex[rl->vertex_index++] = sprite->ox + x;
    rl->vertex[rl->vertex_index++] = sprite->oy + y + sprite->h;

    rl->vertex[rl->vertex_index++] = sprite->ox + x + sprite->w;
    rl->vertex[rl->vertex_index++] = sprite->oy + y + sprite->h;

    rl->vertex[rl->vertex_index++] = sprite->ox + x;
    rl->vertex[rl->vertex_index++] = sprite->oy + y;

    rl->vertex[rl->vertex_index++] = sprite->ox + x + sprite->w;
    rl->vertex[rl->vertex_index++] = sprite->oy + y + sprite->h;

    rl->vertex[rl->vertex_index++] = sprite->ox + x + sprite->w;
    rl->vertex[rl->vertex_index++] = sprite->oy + y;


    rl->texcoord[rl->texcoord_index++] = sprite->_x;
    rl->texcoord[rl->texcoord_index++] = sprite->_y;

    rl->texcoord[rl->texcoord_index++] = sprite->_x;
    rl->texcoord[rl->texcoord_index++] = sprite->_y + sprite->_h;

    rl->texcoord[rl->texcoord_index++] = sprite->_x + sprite->_w;
    rl->texcoord[rl->texcoord_index++] = sprite->_y + sprite->_h;

    rl->texcoord[rl->texcoord_index++] = sprite->_x;
    rl->texcoord[rl->texcoord_index++] = sprite->_y;

    rl->texcoord[rl->texcoord_index++] = sprite->_x + sprite->_w;
    rl->texcoord[rl->texcoord_index++] = sprite->_y + sprite->_h;

    rl->texcoord[rl->texcoord_index++] = sprite->_x + sprite->_w;
    rl->texcoord[rl->texcoord_index++] = sprite->_y;


    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;

    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;

    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;

    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;

    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;

    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;

    rl->count += 2;
}


- (void)drawTagSpritePoint:(TagSprite *)sprite X:(float)x Y:(float)y Z:(float)z SCALE:(float)scale RL:(RenderList *)rl {

    float tw = (sprite->w * scale) * 0.5;
    float th = (sprite->h * scale) * 0.5;
    float tox = (sprite->ox * scale);
    float toy = (sprite->oy * scale);

    rl->vertex[rl->vertex_index++] = (tox + x - tw);
    rl->vertex[rl->vertex_index++] = (toy + y - th);

    rl->vertex[rl->vertex_index++] = (tox + x - tw);
    rl->vertex[rl->vertex_index++] = (toy + y + th);

    rl->vertex[rl->vertex_index++] = (tox + x + tw);
    rl->vertex[rl->vertex_index++] = (toy + y + th);

    rl->vertex[rl->vertex_index++] = (tox + x - tw);
    rl->vertex[rl->vertex_index++] = (toy + y - th);

    rl->vertex[rl->vertex_index++] = (tox + x + tw);
    rl->vertex[rl->vertex_index++] = (toy + y + th);

    rl->vertex[rl->vertex_index++] = (tox + x + tw);
    rl->vertex[rl->vertex_index++] = (toy + y - th);


    rl->texcoord[rl->texcoord_index++] = sprite->_x;
    rl->texcoord[rl->texcoord_index++] = sprite->_y;

    rl->texcoord[rl->texcoord_index++] = sprite->_x;
    rl->texcoord[rl->texcoord_index++] = sprite->_y + sprite->_h;

    rl->texcoord[rl->texcoord_index++] = sprite->_x + sprite->_w;
    rl->texcoord[rl->texcoord_index++] = sprite->_y + sprite->_h;

    rl->texcoord[rl->texcoord_index++] = sprite->_x;
    rl->texcoord[rl->texcoord_index++] = sprite->_y;

    rl->texcoord[rl->texcoord_index++] = sprite->_x + sprite->_w;
    rl->texcoord[rl->texcoord_index++] = sprite->_y + sprite->_h;

    rl->texcoord[rl->texcoord_index++] = sprite->_x + sprite->_w;
    rl->texcoord[rl->texcoord_index++] = sprite->_y;


    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;

    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;

    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;

    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;

    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;

    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;

    rl->count += 2;
}


- (void)drawTagSpritePointAlpha:(TagSprite *)sprite X:(float)x Y:(float)y Z:(float)z SCALE:(float)scale ALPHA:(GLubyte)alpha RL:(RenderList *)rl {

    float tw = (sprite->w * scale) * 0.5;
    float th = (sprite->h * scale) * 0.5;
    float tox = (sprite->ox * scale);
    float toy = (sprite->oy * scale);

    rl->vertex[rl->vertex_index++] = (tox + x - tw);
    rl->vertex[rl->vertex_index++] = (toy + y - th);

    rl->vertex[rl->vertex_index++] = (tox + x - tw);
    rl->vertex[rl->vertex_index++] = (toy + y + th);

    rl->vertex[rl->vertex_index++] = (tox + x + tw);
    rl->vertex[rl->vertex_index++] = (toy + y + th);

    rl->vertex[rl->vertex_index++] = (tox + x - tw);
    rl->vertex[rl->vertex_index++] = (toy + y - th);

    rl->vertex[rl->vertex_index++] = (tox + x + tw);
    rl->vertex[rl->vertex_index++] = (toy + y + th);

    rl->vertex[rl->vertex_index++] = (tox + x + tw);
    rl->vertex[rl->vertex_index++] = (toy + y - th);


    rl->texcoord[rl->texcoord_index++] = sprite->_x;
    rl->texcoord[rl->texcoord_index++] = sprite->_y;

    rl->texcoord[rl->texcoord_index++] = sprite->_x;
    rl->texcoord[rl->texcoord_index++] = sprite->_y + sprite->_h;

    rl->texcoord[rl->texcoord_index++] = sprite->_x + sprite->_w;
    rl->texcoord[rl->texcoord_index++] = sprite->_y + sprite->_h;

    rl->texcoord[rl->texcoord_index++] = sprite->_x;
    rl->texcoord[rl->texcoord_index++] = sprite->_y;

    rl->texcoord[rl->texcoord_index++] = sprite->_x + sprite->_w;
    rl->texcoord[rl->texcoord_index++] = sprite->_y + sprite->_h;

    rl->texcoord[rl->texcoord_index++] = sprite->_x + sprite->_w;
    rl->texcoord[rl->texcoord_index++] = sprite->_y;


    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = alpha;

    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = alpha;

    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = alpha;

    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = alpha;

    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = alpha;

    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = alpha;

    rl->count += 2;
}


- (void)drawTagSpritePointRotated:(TagSprite *)sprite X:(float)x Y:(float)y Z:(float)z SCALE:(float)scale UNIT:(float)unit ANGLE:(float)angle RL:(RenderList *)rl {

    unit += ICON_UNIT_SIZE_OFFSET;


    if (unit < ICON_UNIT_SIZE_MIN) {
        unit = ICON_UNIT_SIZE_MIN;
    }

    if (unit > ICON_UNIT_SIZE_MAX) {
        unit = ICON_UNIT_SIZE_MAX;
    }


    float ratio = ((float) sprite->w) / ((float) sprite->h);
    float oxratio = ((float) sprite->ox) / ((float) sprite->w);
    float oyratio = ((float) sprite->oy) / ((float) sprite->h);
    float tw = (unit * ratio * scale) * 0.5;
    float th = (unit * scale) * 0.5;
    float tox = (unit * oxratio * scale) * 0.5;
    float toy = (unit * oyratio * scale) * 0.5;

    float x1 = tox - tw;
    float x2 = tox + tw;
    float y1 = toy - th;
    float y2 = toy + th;

    float rx1 = x1 * cos(angle) - y1 * sin(angle);
    float ry1 = x1 * sin(angle) + y1 * cos(angle);

    float rx2 = x2 * cos(angle) - y1 * sin(angle);
    float ry2 = x2 * sin(angle) + y1 * cos(angle);

    float rx3 = x1 * cos(angle) - y2 * sin(angle);
    float ry3 = x1 * sin(angle) + y2 * cos(angle);

    float rx4 = x2 * cos(angle) - y2 * sin(angle);
    float ry4 = x2 * sin(angle) + y2 * cos(angle);

    rl->vertex[rl->vertex_index++] = x + rx1;
    rl->vertex[rl->vertex_index++] = y + ry1;

    rl->vertex[rl->vertex_index++] = x + rx3;
    rl->vertex[rl->vertex_index++] = y + ry3;

    rl->vertex[rl->vertex_index++] = x + rx4;
    rl->vertex[rl->vertex_index++] = y + ry4;

    rl->vertex[rl->vertex_index++] = x + rx1;
    rl->vertex[rl->vertex_index++] = y + ry1;

    rl->vertex[rl->vertex_index++] = x + rx4;
    rl->vertex[rl->vertex_index++] = y + ry4;

    rl->vertex[rl->vertex_index++] = x + rx2;
    rl->vertex[rl->vertex_index++] = y + ry2;


    rl->texcoord[rl->texcoord_index++] = sprite->_x;
    rl->texcoord[rl->texcoord_index++] = sprite->_y;

    rl->texcoord[rl->texcoord_index++] = sprite->_x;
    rl->texcoord[rl->texcoord_index++] = sprite->_y + sprite->_h;

    rl->texcoord[rl->texcoord_index++] = sprite->_x + sprite->_w;
    rl->texcoord[rl->texcoord_index++] = sprite->_y + sprite->_h;

    rl->texcoord[rl->texcoord_index++] = sprite->_x;
    rl->texcoord[rl->texcoord_index++] = sprite->_y;

    rl->texcoord[rl->texcoord_index++] = sprite->_x + sprite->_w;
    rl->texcoord[rl->texcoord_index++] = sprite->_y + sprite->_h;

    rl->texcoord[rl->texcoord_index++] = sprite->_x + sprite->_w;
    rl->texcoord[rl->texcoord_index++] = sprite->_y;


    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;

    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;

    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;

    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;

    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;

    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;
    rl->color[rl->color_index++] = 255;

    rl->count += 2;
}


- (void)drawNumber:(int)number X:(int)x Y:(int)y RL:(RenderList *)rl {
    x = x * (1 / textScale);
    y = y * (1 / textScale);
    int digits[16];
    int dp = 0;
    do {
        digits[dp++] = (number % 10);
        number /= 10;
    } while (number != 0);

    while (dp > 0) {
        dp--;

        [self drawTagSprite:&ts_number[GRAPHICS_font_0 + digits[dp]] X:x Y:y Z:0 RL:rl];
        x += ts_number[digits[dp]].w;
    }
}

- (void)drawString:(const char *)string X:(int)x Y:(int)y RL:(RenderList *)rl {
    if (x < 320 && x > 0 && y < 480 && y > 0) {//only draw text that starts on screen
        x = x * (1 / textScale);
        y = y * (1 / textScale);
        int p = 0, spr;
        char c;
        while (string[p] != 0) {
            c = string[p];
            if (c == 32) {
                x += 10;
            }
            else {
                if (c >= 48 && c < 58) {
                    spr = (c - 48) + GRAPHICS_font_0;
                }
                else if (c >= 65 && c < 91) {
                    spr = (c - 65) + GRAPHICS_font_A;
                    if (c == 73) {
                        //more space for I
                        x += 2;
                    }
                }

                [self drawTagSprite:&ts_number[spr] X:x Y:y Z:0 RL:rl];
                x += (ts_number[spr].w + 1);


            }
            p++;
        }
    }

}


- (void)layoutSubviews { //Where is this method even called??!
    [EAGLContext setCurrentContext:context];
    [self destroyFramebuffer];
    [self createFramebuffer];
    [self drawView]; //How is it getting here when EAGLView is commented out??!
}


- (BOOL)createFramebuffer {

    glGenFramebuffersOES(1, &viewFramebuffer);
    glGenRenderbuffersOES(1, &viewRenderbuffer);

    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer *) self.layer];
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);

    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);

    if (USE_DEPTH_BUFFER) {
        glGenRenderbuffersOES(1, &depthRenderbuffer);
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
        glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
    }

    if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
#if EAGLVIEW_ENABLE_PRINTS
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
#endif
        return NO;
    }

    return YES;
}


- (void)destroyFramebuffer {

    glDeleteFramebuffersOES(1, &viewFramebuffer);
    viewFramebuffer = 0;
    glDeleteRenderbuffersOES(1, &viewRenderbuffer);
    viewRenderbuffer = 0;

    if (depthRenderbuffer) {
        glDeleteRenderbuffersOES(1, &depthRenderbuffer);
        depthRenderbuffer = 0;
    }
}


- (void)startAnimation {
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:animationInterval target:self selector:@selector(drawView) userInfo:nil repeats:YES];
    //[self updateAccelerometerInterval:YES];
    [self updatePerferredAirportList];
}


- (void)stopAnimation {
    self.animationTimer = nil;
    //[self updateAccelerometerInterval:NO];
}


- (void)setAnimationTimer:(NSTimer *)newTimer {
    [animationTimer invalidate];
    animationTimer = newTimer;
}


- (void)setAnimationInterval:(NSTimeInterval)interval {

    animationInterval = interval;
    if (animationTimer) {
        [self stopAnimation];
        [self startAnimation];
    }
}


- (void)dealloc {

    [self stopAnimation];

    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }

    [self freeRenderList:&rl_back];
    [self freeRenderList:&rl_front];
    [self freeRenderList:&rl_gui];

    //[context release];
    //[airportLabels release];

    if (airports) free(airports);
    if (flightpaths) free(flightpaths);
    if (planes) free(planes);

    //[super dealloc];
}


- (void)clearTouches {
    for (int i = 0; i < 4; i++) {
        _touches[i].active = NO;
        _touches[i].used = NO;
    }
    rotateTouch = -1;
    zoomTouch = -1;
}


//Touches moved rewritten to be called by all the other events...
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInView:self];
        CGPoint lastLocation = [touch previousLocationInView:self];
        NSUInteger taps = [touch tapCount];
        UITouchPhase phase = [touch phase];
        int i = 0;
        int idx = -1;
        int free = -1;
        Boolean found = false;

        switch (phase) {
            default:
            case UITouchPhaseEnded:
            case UITouchPhaseCancelled: {
                while (i < kNumTouches && !found) {
                    if (_touches[i].active && ((lastLocation.x == _touches[i].x && lastLocation.y == _touches[i].y) || (location.x == _touches[i].x && location.y == _touches[i].y))) {
                        idx = i;
                        found = true;
                    }
                    i++;
                }

                if (found) {
                    _touches[idx].lastx = _touches[idx].x;
                    _touches[idx].lasty = _touches[idx].y;
                    _touches[idx].x = location.x;
                    _touches[idx].y = location.y;
                    _touches[idx].active = false;
                    _touches[idx].used = false;
                    _touches[idx].moved = false;
                    _touches[idx].taps = taps;
                    _touches[idx].tickLastUpdated = ticks;
                }
                else {
                    //An cancelled touch that we didn't find... clear them all?

                    for (int i = 0; i < kNumTouches; i++) {
                        _touches[i].active = false;
                        _touches[i].used = false;
                        _touches[i].moved = false;
                        _touches[i].tickLastUpdated = 0;
                    }

                }

            }
                break;
            case UITouchPhaseBegan: {
                while (i < kNumTouches && !found) {
                    if (!_touches[i].active) {
                        idx = i;
                        found = true;
                    }
                    i++;
                }

                if (!found) {
                    idx = 0;    //No slots free so use 1st one...
                }

                _touches[idx].lastx = location.x;
                _touches[idx].lasty = location.y;
                _touches[idx].x = location.x;
                _touches[idx].y = location.y;
                _touches[idx].active = true;
                _touches[idx].moved = false;
                _touches[idx].used = false;
                _touches[idx].taps = taps;
                _touches[idx].tickLastUpdated = ticks;
                switch (viewOrientation) {
                    case 2:
                        _touches[idx].tx = _touches[idx].x;
                        _touches[idx].ty = _touches[idx].y;
                        _touches[idx].tlastx = _touches[idx].x;
                        _touches[idx].tlasty = _touches[idx].y;
                }
            }
                break;
            case UITouchPhaseMoved: {
                while (i < kNumTouches && !found) {
                    if (_touches[i].active && lastLocation.x == _touches[i].x && lastLocation.y == _touches[i].y) {
                        idx = i;
                        found = true;
                    } else if (!_touches[i].active && free == -1) {
                        free = i;
                    }
                    i++;
                }

                if (!found) {
                    if (free == -1) {
                        free = 0;
                    }
                    idx = free;
                }
                _touches[idx].lastx = lastLocation.x;
                _touches[idx].lasty = lastLocation.y;
                _touches[idx].x = location.x;
                _touches[idx].y = location.y;
                _touches[idx].taps = taps;
                if (lastLocation.x != location.x) {
                    _touches[idx].moved = true;
                }
                else {
                    _touches[idx].moved = false;
                }
                //_touches[idx].moved=true;
                _touches[idx].tickLastUpdated = ticks;

                switch (viewOrientation) {
                    case 2:
                        _touches[idx].tx = _touches[idx].x;
                        _touches[idx].ty = _touches[idx].y;
                        _touches[idx].tlastx = _touches[idx].lastx;
                        _touches[idx].tlasty = _touches[idx].lasty;
                }

            }
                break;
            case UITouchPhaseStationary: {
                while (i < kNumTouches && !found) {
                    if (_touches[i].active && lastLocation.x == _touches[i].x && lastLocation.y == _touches[i].y) {
                        idx = i;
                        found = true;
                    } else if (!_touches[i].active && free == -1) {
                        free = i;
                    }
                    i++;
                }
                if (!found) {
                    if (free == -1) {
                        free = 0;
                    }
                    idx = free;
                }
                _touches[idx].x = location.x;
                _touches[idx].y = location.y;
                _touches[idx].taps = taps;
                _touches[idx].moved = true;
                _touches[idx].active = true;
                _touches[idx].tickLastUpdated = ticks;
                switch (viewOrientation) {
                    case 2:
                        _touches[idx].tx = _touches[idx].x;
                        _touches[idx].ty = _touches[idx].y;
                        _touches[idx].tlastx = _touches[idx].x;
                        _touches[idx].tlasty = _touches[idx].y;
                }
            }
                break;
        }

    }
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesMoved:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesMoved:touches withEvent:event];
}


- (void)updateAllPlanes {
#if EAGLVIEW_ENABLE_PRINTS
	int planes_in_sky=[sky->planes count];
	printf("number of planes: %d\n",planes_in_sky);
	
	for(int i=0;i<planes_in_sky;i++){
		Aircraft * ac = [sky->planes objectAtIndex:i];
		printf("%d - %p\n",i,ac);
		NSLog(ac->name);
	}
#endif
}

//- (void)newPlaneData:(Aircraft *)ac {
//#if EAGLVIEW_ENABLE_PRINTS
//	NSLog("new aircraft data: %p   name: %p  movement:%p\n",ac,ac->name,ac->position);
//	NSLog(ac->name);
//	NSLog([ac->position objectForKey:@"latitude"]);
//	NSLog([ac->position objectForKey:@"longtitude"]);
//#endif
//
//    int pi = [self findPlaneWithName:ac->name];
//    if (pi == -1) {
//        pi = [self addPlane:ac];
//    }
//    else {
//        [self updatePlane:pi withData:ac];
//    }
//
//    if (ac->flying == NO) {
//        planes[pi].used = NO;
//    }
//    else {
//        //Edit here to test unknown airport
//        int api1 = [self findAirportWithName:[ac->activeFlight beginning]];
//        int api2 = [self findAirportWithName:[ac->activeFlight destination]];
//        if (api1 != -1 && api2 != -1) {
//            [self initFlightpath:&flightpaths[pi] withStart:&airports[api1] withEnd:&airports[api2] withDirection:0];
//            [self buildFlightpathDots:&flightpaths[pi] withPlane:&planes[pi]];
//            planes[pi].flight = &flightpaths[pi];
//        }
//        else {
//            flightpaths[pi].used = NO;
//        }
//
//
//    }
//}

- (int)findPlaneWithName:(NSString *)str {
    for (int i = 0; i < MAX_PLANES; i++) {
        if (planes[i].used == YES && planes[i].name != NULL && [str compare:planes[i].name] == NSOrderedSame) {
            return i;
        }
    }
    return -1;
}

//- (int)addPlane:(Aircraft *)ac {
//    int pi = -1;
//    BOOL space_found = NO;
//    for (int i = 0; i < MAX_PLANES; i++) {
//        if (!planes[i].used) {
//            space_found = YES;
//            pi = i;
//            break;
//        }
//    }
//
//    if (space_found) {
//        [self initPlane:&planes[pi] withName:ac->name withFlight:&flightpaths[pi] withN:[[ac->position objectForKey:@"latitude"] floatValue] withE:[[ac->position objectForKey:@"longtitude"] floatValue] withR:255 withG:255 withB:255];
//        planes[pi].ac = ac;
//    }
//
//    return pi;
//}

//- (void)updatePlane:(int)pi withData:(Aircraft *)ac {
//    planes[pi].east = [[ac->position objectForKey:@"longtitude"] floatValue];
//    planes[pi].north = [[ac->position objectForKey:@"latitude"] floatValue];
//
//    if (planes[pi].east >= 360.0f || planes[pi].east <= -360.0f) {
//#if EAGLVIEW_ENABLE_PRINTS
//		printf("Error in plane east - %f\n",planes[pi].east);
//#endif
//        planes[pi].used = NO;
//    }
//
//    if (planes[pi].north >= 180.0f || planes[pi].north <= -180.0f) {
//#if EAGLVIEW_ENABLE_PRINTS
//		printf("Error in plane north - %f\n",planes[pi].north);
//#endif
//        planes[pi].used = NO;
//    }
//
//    planes[pi].ac = ac;
//
//
//}


- (int)findAirportWithName:(NSString *)name {
    for (int i = 0; i < NUM_AIRPORTS; i++) {
        airport_t ap = airports[i];
        if (ap.name != NULL && [name compare:ap.name] == NSOrderedSame) {
            return i;
        }
    }
    return -1;
}

- (void)setAppPtr:(AppDelegate *)newParent {
    appPtr = newParent;
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

}


- (int)saveHighScores {
    int result = 0;

    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [path objectAtIndex:0];
    NSString *saveFile = [documentsDirectory stringByAppendingPathComponent:@"VirginAtlanticFlightTrackerScores.dat"];

    NSMutableArray *dataArray = [NSMutableArray arrayWithCapacity:2];
    [dataArray addObject:[NSNumber numberWithInt:gameHighScoreAirport]];
    [dataArray addObject:[NSNumber numberWithInt:gameHighScoreBalloon]];

    if ([dataArray writeToFile:saveFile atomically:YES] == NO) {
        //chattyNSLog(@"saveData(): Unable to write Data");
        result = 1;
    }
    else {
        //chattyNSLog(@"saveData(): Data saved successfully");
    }


    return result;
}


- (int)loadHighScores {
    int result = 0;
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [path objectAtIndex:0];
    NSString *saveFile = [documentsDirectory stringByAppendingPathComponent:@"VirginAtlanticFlightTrackerScores.dat"];

    NSMutableArray *fileData = [NSMutableArray arrayWithContentsOfFile:saveFile];


    if (fileData == nil) {
#if SKY_ENABLE_PRINTS
		NSLog(@"loadSkyArrayData - Unable to load data from file \"%@\"",saveFile);
#endif
        result = 1;
    }
    else {
        gameHighScoreAirport = [[fileData objectAtIndex:0] intValue];
        gameHighScoreBalloon = [[fileData objectAtIndex:1] intValue];

#if SKY_ENABLE_PRINTS
		NSLog(@"loadSkyArrayData - Loaded %d things from file \"%@\"",[fileData length],saveFile);
#endif
    }

    return result;
}


- (BOOL)loadTextureFromPNGFileWithName:(NSString *)nameMinusPNG ToTex:(GLuint *)tex {

    NSString *path = [[NSBundle mainBundle] pathForResource:nameMinusPNG ofType:@"png"];
    NSData *texData = [[NSData alloc] initWithContentsOfFile:path];
    UIImage *image = [[UIImage alloc] initWithData:texData];

    GLuint width = CGImageGetWidth(image.CGImage);
    GLuint height = CGImageGetHeight(image.CGImage);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *imageData = malloc(height * width * 4);
    CGContextRef currentContext = CGBitmapContextCreate(imageData, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(currentContext, CGRectMake(0, 0, width, height));
    CGContextTranslateCTM(currentContext, 0, 0);
    CGContextDrawImage(currentContext, CGRectMake(0, 0, width, height), image.CGImage);
    glGenTextures(1, tex);
    glBindTexture(GL_TEXTURE_2D, *tex);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);

    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glEnable(GL_TEXTURE_2D);
    CGContextRelease(currentContext);

    free(imageData);
    //[image release];
    //[texData release];

    return true;
}

- (void)drawShineyOverlay {
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_DST_ALPHA);
    glBindTexture(GL_TEXTURE_2D, 4);
    glRotatef(180, 1, 0, 0);
    float zoomScale = 1 - (zoomLevel / 60);// normalized value 
    glTranslatef(0.0, 0.0, -28 * zoomScale);
    float x = 53;
    float y = 60;
    float x1 = -53;
    float y1 = -60;

    GLfloat squareVertices[] = {
            x, y, 0.0f,
            x1, y, 0.0f,
            x, y1, 0.0f
    };
    GLfloat texcoords[] = {
            1.0f, 1.0f,
            0.0f, 1,
            1, 0.0f
    };

    glVertexPointer(3, GL_FLOAT, 0, squareVertices);
    glEnableClientState(GL_VERTEX_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, 0, texcoords);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glDrawArrays(GL_TRIANGLES, 0, 3);

    GLfloat squareVertices2[] = {
            x1, y1, 0.0f,
            x1, y, 0.0f,
            x, y1, 0.0f
    };
    GLfloat texcoords2[] = {
            0.0f, 0.0f,
            0.0f, 1.0f,
            1.0f, 0.0f
    };

    glVertexPointer(3, GL_FLOAT, 0, squareVertices2);
    glEnableClientState(GL_VERTEX_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, 0, texcoords2);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);


    glDrawArrays(GL_TRIANGLES, 0, 3);
}

- (void)drawQuad {
    glBindTexture(GL_TEXTURE_2D, 5);
    float x = 20;
    float y = 3;
    float x1 = 300;
    float y1 = 67;

    GLfloat squareVertices[] = {
            x, y, 0.0f,
            x1, y, 0.0f,
            x, y1, 0.0f
    };

    GLfloat texcoords[] = {
            0.0f, 0.0f,
            1.0f, 0,
            0, 1.0f
    };

    glVertexPointer(3, GL_FLOAT, 0, squareVertices);
    glEnableClientState(GL_VERTEX_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, 0, texcoords);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glDrawArrays(GL_TRIANGLES, 0, 3);

    GLfloat squareVertices2[] = {
            x1, y1, 0.0f,
            x1, y, 0.0f,
            x, y1, 0.0f
    };

    GLfloat texcoords2[] = {
            1.0f, 1.0f,
            1.0f, 0.0f,
            0.0f, 1.0f
    };

    glVertexPointer(3, GL_FLOAT, 0, squareVertices2);
    glEnableClientState(GL_VERTEX_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, 0, texcoords2);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);


    glDrawArrays(GL_TRIANGLES, 0, 3);
}

//- (GlobeViewController *)globeInterface {
//    if ([interface isKindOfClass:[GlobeViewController class]])
//        return (GlobeViewController *) interface;
//    return nil;
//}

- (GameViewController *)gameInterface {
    if ([interface isKindOfClass:[GameViewController class]])
        return (GameViewController *) interface;
    return nil;
}

@end
