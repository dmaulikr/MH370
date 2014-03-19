//
//  EAGLView.h
//  VAA
//
//  Created by Tag Games on 14/09/2009.
//  Copyright Tag Games Ltd 2009. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#import "VAAAppDelegate.h"

#include "GlobeModel.h"
#include "AirportCoords.h"
#include "TagGraphicsmaingfx.h"
#include "TagGraphicsfont.h"

/*
This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
The view content is basically an EAGL surface you render your OpenGL scene into.
Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
*/

#define MAX_PLANES			64
#define MAX_GAME_OBJECTS	64


#define DIRECTION_EAST		1
#define DIRECTION_WEST		2
#define DIRECTION_SOUTH		4
#define DIRECTION_NORTH		8

#define ICON_UNIT_SIZE_MIN	2
#define ICON_UNIT_SIZE_MAX	12

#define ICON_UNIT_SIZE_OFFSET	0

enum {
	GLOBE_MODE_FREE,
	GLOBE_MODE_TARGET,
};

enum {
	APP_MODE_FREE,
	APP_MODE_PLANE,
	APP_MODE_AIRPORT,
	APP_MODE_GAME_AIRPORT,
	APP_MODE_GAME_BALLOON,
};

enum {
	GS_AIRPORT_INTRO = 0,
	GS_AIRPORT_FIND,
	GS_AIRPORT_FOUND,
	GS_AIRPORT_RESULT,
};

enum {
	GS_BALLOON_INTRO = 100,
	GS_BALLOON_GAMEPLAY,
	GS_BALLOON_WIN,
	GS_BALLOON_CONTINUE,
	GS_BALLOON_LOSE,
	GS_BALLOON_OUT_OF_TIME,
	GS_BALLOON_END,
};


enum {
	kNumTouches=6
};

static NSString * const texture_files[]={
@"globe.png",
@"maingfx.png",
@"font.png",
};

static NSString * const texture_data_files[]={
@"globe",
@"maingfx",
@"font",
};


typedef struct{
	
	float x,y;
	float w,h;
	float ox,oy;
	
	float _x,_y;
	float _w,_h;
	float _ox,_oy;
	
} TagSprite;

typedef struct{
	
	GLfloat * vertex;
	GLfloat * texcoord;
	GLubyte * color;
	
	int vertex_index;
	int texcoord_index;
	int color_index;
	
	int count;
	int size;
	
	int texture;
	
} RenderList;

enum{
	TEX_GLOBE,
	TEX_MAIN,
	TEX_NUMBER,
};

typedef struct
{
		float x,y;
		float lastx,lasty;
	
		int tx,ty;				// translated for screen orientation
		int tlastx,tlasty;		//
	
		bool active;
		bool used;
		bool moved;	//set to true if its a moving point.
		int taps;
		int tickLastUpdated;
} touchPoint;

typedef struct
{
	int type;
	float * vertex;
	float * texcoord;
	float * normal;
	GLubyte * color;
	GLshort * index;
	int vertex_size,vertex_count;
	int triangle_size,triangle_count;
	int index_size,index_count;
	int texture;
} graphic_t;

typedef struct
{
	float x,y;
	float w,h;
} sprite_t;



typedef struct {
    float north;
    float east;
    NSString * name;
    sprite_t sprite;
    GLubyte r,g,b;
    float screen_x,screen_y,screen_z;
    BOOL isPrimary;
} airport_t;


typedef struct
{
		BOOL used;
		airport_t * start;
		airport_t * end;
		int direction;
		graphic_t * graphic;
		graphic_t * graphic2;
		float * dots, * dots2;
		int dot_count,dot_count2;
		GLubyte r,g,b;

} flightpath_t;

typedef struct
{
		BOOL used;
		NSString * name;
		float north;
		float east;
		float altitude;
		flightpath_t * flight;
		sprite_t sprite;
		GLubyte r,g,b;
		float screen_x,screen_y,screen_z;
		
		Aircraft * ac;
		
} plane_t;


typedef struct
{
		float north;
		float east;
		float altitude;
		float dnorth;
		float deast;
		NSString * name;
		sprite_t sprite;
		GLubyte r,g,b;
		float screen_x,screen_y,screen_z;
} gameobj_t;


@interface EAGLView : UIView <UIAccelerometerDelegate, AirPortDataManagerDelegate> {
    
@private
	bool drawFrame;
	bool drawingBalloon;
	VAAAppDelegate * appPtr;
	UIViewController * interface;

    /* The pixel dimensions of the backbuffer */
    GLint backingWidth;
    GLint backingHeight;
    
    EAGLContext *context;
    
    /* OpenGL names for the renderbuffer and framebuffers used to render to this view */
    GLuint viewRenderbuffer, viewFramebuffer;
    
    /* OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist) */
    GLuint depthRenderbuffer;
    
    NSTimer *animationTimer;
    NSTimeInterval animationInterval;

	int ticks;
	int viewOrientation;
	unsigned int textures[10];
	GLuint globeshine;
	GLuint cloudtex;
	GLuint scoretex;
	unsigned int * texture_mask[10];
	BOOL first;
	float rotate;
	
	GLfloat globe_rotation[16];					// Where The 16 Doubles Of The Modelview Matrix Are To Be Stored


	touchPoint _touches[kNumTouches];

	int rotateTouch;
	int rotateLastX,rotateLastY;
	float rotateX,rotateY,lastRotateX,lastRotateY;
	float rotateDX,rotateDY;
	int zoomTouch;
	int zoomLastX,zoomLastY;
	float zoomLevel,lastZoomLevel, newZoomLevel;
	BOOL tapZoomOn;

	float globe_radius;

	float point_sprite_scale;
	float touchScale;
	
	airport_t ap1,ap2;
	flightpath_t fp1;
	
	airport_t * airports;
	flightpath_t * flightpaths;
	plane_t * planes;
	
	graphic_t * sprite_list;
	
	float flight_progress;
	
	RenderList rl_back;
	RenderList rl_front;
	RenderList rl_gui;
	
	TagSprite ts_main[64];
	TagSprite ts_number[36];
	
	int globeMode;
	float globeTargetX;
	float globeTargetY;
	float globeTargetZoom;
	
	int selectedAirport,selectedPlane;
	int planeToTrack;
	
	int appMode;
	
	int gameState;
	
	int gameAirport;
	int gameStart;
	int gameTimer;
	int gameScore;
	float gameMaxObjectSpeed;
	int gameObjectCount;
	int gameTouch;
	int gameTouchLastX;
	int gameTouchLastY;
	float gameDistance;
	float gameCompassAngle;
	int gameTemperature;
	int bransonAnimation;
	int lastGame;
	gameobj_t objRichard;
	gameobj_t objCompass[4];
	gameobj_t objWhirlwind[MAX_GAME_OBJECTS];

	int gameHighScoreAirport;
	int gameHighScoreBalloon;
	
	NSString*	myAirport1;
	NSString*	myAirport2;
	NSString*	myAirport3;
	
	Sky * sky;
	BOOL updateDraw;
	BOOL drawAirportShortName;
	NSMutableArray* airportLabels;
	float textScale;
	int object_type;
	int nearest_plane;
	int nearest_airport;
	UILabel* perLoaded;
}

@property (nonatomic) NSTimeInterval animationInterval;
@property (nonatomic) int lastGame;
@property (nonatomic) int globeMode;
@property (nonatomic) BOOL first;
@property (nonatomic) int appMode;
@property (nonatomic,assign) UIViewController * interface;
@property (nonatomic) BOOL updateDraw;
@property (nonatomic) float zoomLevel;
@property (nonatomic) float textScale;
- (void) startAccelerometer;

- (void)startAnimation;
- (void)stopAnimation;
- (void)drawView;

-(void)initResources;

-(void)initRenderList:(RenderList *)rl withSize:(int)inSize;
-(void)resetRenderList:(RenderList *)rl;
-(void)freeRenderList:(RenderList *)rl;
-(void)drawRenderList:(RenderList *)rl;

- (void)loadTexture:(int) index;
-(void)loadTagSpriteData:(NSString*)fn DEST:(TagSprite *)d TEX_W:(float)tex_w TEX_H:(float)tex_h;
-(void)setTexture:(int) index;
-(void)drawTagSprite:(TagSprite *)sprite X:(float)x Y:(float)y Z:(float)z RL:(RenderList *)rl;
-(void)drawTagSpritePoint:(TagSprite *)sprite X:(float)x Y:(float)y Z:(float)z SCALE:(float)scale RL:(RenderList *)rl;
-(void)drawTagSpritePointRotated:(TagSprite *)sprite X:(float)x Y:(float)y Z:(float)z SCALE:(float)scale UNIT:(float)unit ANGLE:(float)angle RL:(RenderList *)rl;
-(BOOL)checkForSpriteTouched:(TagSprite *)sprite atX:(float)x atY:(float)y;

-(void)drawNumber:(int) number X:(int)x Y:(int)y RL:(RenderList *)rl;
-(void)drawString:(const char *) string X:(int)x Y:(int)y RL:(RenderList *)rl;

-(int) checkForPlaneTouchedAtX:(int)inX atY:(int)inY returnDistance:(float *)inReturnDistance;
-(int) checkForAirportTouchedAtX:(int)inX atY:(int)inY returnDistance:(float *)inReturnDistance;
-(float) getDistanceForSpriteTouched:(sprite_t *)inSprite AtX:(int)inX atY:(int)inY;

-(void) setOrthoProjection;
-(void) setGlobeProjection;

- (void)drawSpriteOnGlobe:(TagSprite *)sp atN:(float)inN atE:(float)inE resultSprite:(sprite_t *)inSprite;
- (void)drawSpriteOnGlobeRotated:(TagSprite *)sp atN:(float)inN atE:(float)inE withAngle:(float)angle withScale:(float)inScale resultSprite:(sprite_t *)inSprite;
- (void)drawSpriteOnGlobeAlpha:(TagSprite *)sp atN:(float)inN atE:(float)inE withAlpha:(GLubyte)alpha resultSprite:(sprite_t *)inSprite;
-(void)drawTagSpritePointAlpha:(TagSprite *)sprite X:(float)x Y:(float)y Z:(float)z SCALE:(float)scale ALPHA:(GLubyte)alpha RL:(RenderList *)rl;
- (BOOL)initPlane:(plane_t *)ap withName:(NSString*)inName withFlight:(flightpath_t *)inFlight withN:(float)inN withE:(float)inE withR:(GLubyte)inR withG:(GLubyte)inG withB:(GLubyte)inB;
- (void)positionPlaneOnFlight:(plane_t *)ap atProgress:(float)inProgress;
- (void)getTouchScale;
- (void)drawPlane:(plane_t *)ap;

- (BOOL)initAirport:(airport_t *)ap withName:(NSString*)inName withN:(float)inN withE:(float)inE withR:(GLubyte)inR withG:(GLubyte)inG withB:(GLubyte)inB isPrimary:(BOOL)isPrim;
- (void)drawAirport:(airport_t *)ap;

- (void)drawFlightpath:(flightpath_t *)ap;


- (void)RotateVertex:(float *)v withMatrix:(float *)m result:(float *)res;

-(void)getScreenCoordsForX:(float)inX forY:(float)inY forZ:(float)inZ resultX:(float *)inRX resultY:(float *)inRY resultZ:(float *)inRZ resultMZ:(float *)inRMZ;
- (BOOL)initFlightpath:(flightpath_t *)fp withStart:(airport_t *)inStart withEnd:(airport_t *)inEnd withDirection:(int)inDirection;
-(void)buildFlightpathDots:(flightpath_t *)fp withPlane:(plane_t *)pl;
-(void)buildFlightpathGraphic:(flightpath_t *)fp withPlane:(plane_t *)pl;
- (void)buildFlightpathGraphic:(flightpath_t *)fp;
- (graphic_t *)allocateNewGraphics:(int)inType withVertices:(int)inVertices withIndices:(int)inIndices withTexCoords:(BOOL)inTexCoords withNormals:(BOOL)inNormals withColor:(BOOL)inColor;
- (void)freeGraphics:(graphic_t *)g;
- (BOOL)drawGraphicIndices:(graphic_t *) g;

-(int) findAirportWithName:(NSString *)name;
-(void) updatePlane:(int)pi withData:(Aircraft *)ac;
-(int) findPlaneWithName:(NSString *)str;
-(int)	addPlane:(Aircraft *)ac;

-(void) clearTouches;

-(void) setupObjectsForBalloonGame;
-(int) getGameState;
-(void) setGameState:(int)inNewState;
-(void) endCurrentGame;
-(void) initAlternateGame;
-(void) chooseRandomAirportForAirportGame;
-(void) drawAirportGame;
-(void) drawBalloonGame;
-(void)	initAirportGame;
-(void)	initBalloonGame;
-(void)	processAirportGame;
-(void)	processBalloonGame;
-(void)	initTrackPlane:(NSString *)plane_name;
-(void) processTrackPlane;
-(void) newPlaneData:(Aircraft *)ac;
-(void) setAppPtr:(VAAAppDelegate*)newParent;

-(void) initFreeMode;

- (int) saveHighScores;
- (int) loadHighScores;

@end
