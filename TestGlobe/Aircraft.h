//
//  Aircraft.h
//  VAA
//
//  Created by Calum McMinn on 30/09/2009.
//  Copyright 2009 Tag Games. All rights reserved.
//


#ifndef AIRCRAFT_H
#define AIRCRAFT_H


#import <Foundation/Foundation.h>
#import "Flight.h"
#import "AppDelegate.h"
//#import "Sky.h"

@class VAAAppDelegate;
@class Sky;

enum
{
	FLAG_UNICODE_DATE,
	FLAG_UNICODE_TIME,
	FLAG_UNICODE_DATE_AND_TIME,
	FLAG_UNICODE_TIME_NO_SECONDS,
};

typedef enum {
    AircraftTypeBoeingGeneric,
    AircraftTypeBoeing747200,
    AircraftTypeBoeing747400,
    AircraftTypeAirbusGeneric,
    AircraftTypeAirbus340300,
    AircraftTypeAirbus340600,
    AircraftTypeAirbus330300
} AircraftType;

@interface Aircraft : NSObject<NSXMLParserDelegate> {

@private
	int		currentIndex;
	
@public
	VAAAppDelegate			*appPtr;
	Sky						*pSky;
	BOOL					ready;
	NSURL					*feedLocation;
	BOOL					inFlightInfo;
	BOOL					inMovements;
	BOOL					flying;
	BOOL					flightIsOut;
	BOOL					flightInProgress;
	Flight					*newFlight;
	NSMutableData			*receivedData;
	BOOL					valid;
	
	NSString *depTime;
	NSString *depTimeWithStatus;
	NSString *arrTimeWithStatus;
	NSString *inStatus;
	NSString *outStatus;
	NSString *name;
	NSNumber *currentFlightNo;
	NSMutableDictionary *position;  //Contains: NSDate *lastReport, float latitude, float longitude, float altitude, float heading, float speed
    NSMutableArray *flights; //Contains Flight objects
	NSMutableArray *selectedFlights; //Contains Flight objects

	Flight*			activeFlight;

	unichar*		bufCreatedDate;
	NSUInteger		bufCreatedDateLength;
	unichar*		bufCreatedTime;
	NSUInteger		bufCreatedTimeLength;
	unichar*		bufName;
	NSUInteger		bufNameLength;
	unichar*		bufFlightNo;
	NSUInteger		bufFlightNoLength;
	unichar*		bufReg;
	NSUInteger		bufRegLength;
	unichar*		bufType;
	NSUInteger		bufTypeLength;
	unichar*		bufModel;
	NSUInteger		bufModelLength;
	unichar*		bufSeries;
	NSUInteger		bufSeriesLength;
	unichar*		bufDesc;
	NSUInteger		bufDescLength;
	unichar*		bufDepTime;
	NSUInteger		bufDepTimeLength;
	unichar*		bufArrTime;
	NSUInteger		bufArrTimeLength;
}

@property (nonatomic, retain) NSNumber *currentFlightNo;
@property (nonatomic, retain) NSMutableDictionary *position;
@property (nonatomic, retain) NSMutableArray *flights;
@property (nonatomic, retain) Flight *activeFlight;
@property (nonatomic, retain) VAAAppDelegate * appPtr;
@property (nonatomic, readonly) BOOL flightInProgress;
//@property (nonatomic, retain) NSString *reg;

@property (nonatomic, copy) NSString *depTime;
@property (nonatomic, copy) NSString *depTimeWithStatus;
@property (nonatomic, copy) NSString *arrTimeWithStatus;
@property (nonatomic, copy) NSString *inStatus;
@property (nonatomic, copy) NSString *outStatus;
@property (nonatomic, copy) NSString *name;

@property (assign, nonatomic) AircraftType aircraftType;
@property (assign, nonatomic) BOOL isBoeing;

- (id) initWithFeed:(NSURL *)url withDelegate:(VAAAppDelegate *)ad withSky:(Sky *)inSky withCount:(int)inIndex;
- (id) initWithDataAtIndex:(int)inIndex withDelegate:(VAAAppDelegate *)ad withSky:(Sky *)inSky;
- (int) saveAircraftArrayDataForIndex:(int)inIndex;
- (int) loadAircraftArrayDataForIndex:(int)inIndex;
- (void) parseData;
- (NSMutableArray *) getFlights;
- (NSMutableArray *) getSelectedFlights;
- (Flight *) getActiveFlight;
- (NSString *) getCreatedDate;
- (NSString *) getCreatedTime;
- (NSString *) getName;
- (NSString *) getFlightNo;
- (NSString *) getReg;
- (NSString *) getType;
- (NSString *) getModel;
- (NSString *) getSeries;
- (NSString *) getDescription;
- (NSString *) getDepTime;
- (NSString *) getArrTime;
- (NSString *) getDepTimeWithStatus;
- (NSString *) getArrTimeWithStatus;
+ (NSString *) getUnicodeStandardDateAndTimeAsNSString:(NSString*)inDateAndTime withFlag:(int)inFlag;
- (BOOL) isFutureTime:(NSString*)movementTime withCurrentTime:(NSString*)currentTime;
- (BOOL) isReady;
- (void) findActiveFlight;
- (void) selectFlightsFrom:(NSMutableArray *)inFlights to:(NSMutableArray *)inSelectedFlights withStart:(NSString *)inStart withEnd:(NSString *)inEnd;
- (void) selectActiveFlight;
@end

#endif