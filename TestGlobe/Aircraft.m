//
//  Aircraft.m
//  VAA
//
//  Created by Calum McMinn on 30/09/2009.
//  Copyright 2009 Tag Games. All rights reserved.
//

#define AIRCRAFT_ENABLE_PRINTS		0

#import "Aircraft.h"

@implementation Aircraft

@synthesize position;
@synthesize flights;
@synthesize activeFlight;
@synthesize appPtr;
@synthesize flightInProgress;//,reg;
@synthesize currentFlightNo;

@synthesize depTime;
@synthesize depTimeWithStatus;
@synthesize arrTimeWithStatus;
@synthesize inStatus;
@synthesize outStatus;
@synthesize name;

// event based parsing of returned xml for an individual flight
-(id) initWithFeed:(NSURL *)url withDelegate:(VAAAppDelegate *)ad withSky:(Sky *)inSky withCount:(int)inIndex {
	    
    self.outStatus = @"E";
	self.inStatus = @"E";
	valid = YES; // Set to NO when XML parsing fails
	appPtr=ad;
	pSky=inSky;
	
	ready=NO;
	self.name=nil;
	
	flying=NO;
	
	[pSky addRequestToCounter];

	feedLocation = url;
	
	inFlightInfo = FALSE;
	inMovements = FALSE;
	
	currentIndex = inIndex;
		
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
	
	NSURLRequest *theRequest=[NSURLRequest requestWithURL:url cachePolicy: NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0];	
	
	
#warning THIS IS WHERE THE CRASH HAPPENS, IT IS ON THE CONNECTION OBJECT - see the release comment in connection err
	
	// create the connection with the request and start loading the data	
	NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
	if (theConnection) {
		// Create the NSMutableData that will hold the received data
		// receivedData is declared as a method instance elsewhere
		
		receivedData = [[NSMutableData alloc] retain];
		
	}
	else 
	{
		NSLog(@"Aircraft Download Failed");
		// inform the user that the download could not be made
		
		[pSky removeRequestFromCounter];
	}
	
	[theConnection release];
	
	return self;
}


-(id) initWithDataAtIndex:(int)inIndex withDelegate:(VAAAppDelegate *)ad withSky:(Sky *)inSky
{
	self.outStatus = @"E";
	self.inStatus = @"E";
	valid = YES; // Set to NO when XML parsing fails
	appPtr=ad;
	pSky=inSky;
	
	ready=NO;
	self.name=nil;
	
	flying=NO;
	
	[pSky addRequestToCounter];
	
	feedLocation = nil;
	
	inFlightInfo = FALSE;
	inMovements = FALSE;
	
	currentIndex = inIndex;
	
	if([self loadAircraftArrayDataForIndex:inIndex] == 0)
	{
#if AIRCRAFT_ENABLE_PRINTS
		NSLog(@"initWithDataAtIndex - Loaded data from cache successfully");
#endif
		[self parseData];
	}
	else
	{
		//display UIAlert as no data will be loaded
#if AIRCRAFT_ENABLE_PRINTS
		NSLog(@"initWithDataAtIndex - Unable to load saved data from cache");
#endif
		[pSky removeRequestFromCounter];
	}
	
	return self;
}


- (int) saveAircraftArrayDataForIndex:(int)inIndex
{
	int result = 0;
	NSUInteger length = 0;
	
	NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [path objectAtIndex:0];
	NSString *pathComponent = @"VirginAtlanticFlightTrackerAircraftCache";
	pathComponent = [pathComponent stringByAppendingString:[[NSNumber numberWithInt:inIndex] stringValue]];
	pathComponent = [pathComponent stringByAppendingString:@".dat"];
	NSString *saveFile = [documentsDirectory stringByAppendingPathComponent:pathComponent];
	
	length = [receivedData length];
	

	
	if(length > 0)
	{
		if([receivedData writeToFile:saveFile atomically:YES] == NO)
		{

		}
		else
		{

		}
	}
	else
	{

		result = 1;
	}
	
	return result;
}


- (int) loadAircraftArrayDataForIndex:(int)inIndex
{
	int result = 0;
	NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [path objectAtIndex:0];
	NSString *pathComponent = @"VirginAtlanticFlightTrackerAircraftCache";
	pathComponent = [pathComponent stringByAppendingString:[[NSNumber numberWithInt:inIndex] stringValue]];
	pathComponent = [pathComponent stringByAppendingString:@".dat"];
	NSString *saveFile = [documentsDirectory stringByAppendingPathComponent:pathComponent];
	

	receivedData = [NSMutableData dataWithContentsOfFile:saveFile];
	
	if(receivedData == nil)
	{

		result = 1;
	}
	else
	{

	}
	
	return result;
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // this method is called when the server has determined that it
    // has enough information to create the NSURLResponse
    // it can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
    // receivedData is declared as a method instance elsewhere

	[receivedData setLength:0];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // append the new data to the receivedData
    // receivedData is declared as a method instance elsewhere

    [receivedData appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[self saveAircraftArrayDataForIndex:currentIndex];
	[self parseData];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{

    // release the connection, and the data object
#warning This release was the cause of alot of probs!
	//[connection release];
    // receivedData is declared as a method instance elsewhere
    //[receivedData release];
	
	[pSky removeRequestFromCounter];
}

+ (NSString*) getUnicodeStandardDateAndTimeAsNSString:(NSString*)inDateAndTime withFlag:(int)inFlag
{
	NSString* result = nil;
	NSString* date = nil;
	NSString* time = nil;
	NSRange range;
	
	//reconstruct the date string by removing the T character and replacing with a ' '.
	range = [inDateAndTime rangeOfString:@"T"];
	if( (range.location != NSNotFound) && (range.length != 0) )
	{
		NSRange subRange;
		
		if( (inFlag == FLAG_UNICODE_DATE) || (inFlag == FLAG_UNICODE_DATE_AND_TIME) )
		{
			subRange.location = 0;
			subRange.length = range.location;
			date = [inDateAndTime substringWithRange:subRange];
		}
		
		if( (inFlag == FLAG_UNICODE_TIME) || (inFlag == FLAG_UNICODE_DATE_AND_TIME) || (inFlag == FLAG_UNICODE_TIME_NO_SECONDS) )
		{
			subRange.location = (range.location + range.length);
			subRange.length = ([inDateAndTime length] -  (range.location + range.length));
			time = [inDateAndTime substringWithRange:subRange];
			
			if(inFlag == FLAG_UNICODE_TIME_NO_SECONDS)
			{
				NSRange rangeHrsMins;
				
				rangeHrsMins.location = 0;
				rangeHrsMins.length = 5;
				time = [time substringWithRange:rangeHrsMins];
			}
		}
		
		if(inFlag == FLAG_UNICODE_DATE)
		{
			result = date;
		}
		else
		if( (inFlag == FLAG_UNICODE_TIME) || (inFlag == FLAG_UNICODE_TIME_NO_SECONDS) )
		{
			result = time;
		}
		else
		if(inFlag == FLAG_UNICODE_DATE_AND_TIME)
		{
			result = date;
			result = [result stringByAppendingString:@" "];
			result = [result stringByAppendingString:time];
		}
	}
	
	return result;
}


- (BOOL) isFutureTime:(NSString*)movementTime withCurrentTime:(NSString*)currentTime
{
	BOOL result = NO;
	
	if([movementTime compare:currentTime options:NSNumericSearch] != NSOrderedAscending)
	{
#if AIRCRAFT_ENABLE_PRINTS
		NSLog(@"isFutureTime - %@ is ahead of %@",movementTime,currentTime);
#endif
		result = YES;
	}
#if AIRCRAFT_ENABLE_PRINTS
	else
	{
		NSLog(@"isFutureTime - %@ is behind of %@",movementTime,currentTime);
	}
#endif
	
	return result;
}


- (void) parseData {
	position = [NSMutableDictionary alloc];
	flights = [[NSMutableArray alloc] initWithCapacity:0];
	selectedFlights = [[NSMutableArray alloc] initWithCapacity:0];
	
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:receivedData];
    
    NSString *testString __attribute__((unused)) = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    
    
    
	[parser setDelegate:self];
	[parser setShouldProcessNamespaces:NO];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	[parser parse];
    [parser release];
}

// --------------------------------------------------------------------------------
//
// populate aircraft object from xml
//
// --------------------------------------------------------------------------------
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if(qName)
	{
		elementName = qName;
	}
	
	if([elementName isEqualToString:@"AircraftInformation"])
	{
		NSString* currentDateAndTime = (NSString*)[attributeDict objectForKey:@"createdDateTime"];
		NSString* date = nil;
		NSString* time = nil;
		date = [Aircraft getUnicodeStandardDateAndTimeAsNSString:currentDateAndTime withFlag:FLAG_UNICODE_DATE];
		time = [Aircraft getUnicodeStandardDateAndTimeAsNSString:currentDateAndTime withFlag:FLAG_UNICODE_TIME];
		//store for later
		bufCreatedDate = (unichar*)malloc([date length] * sizeof(unichar));
		bufCreatedDateLength = (NSUInteger)[date length];
		[date getCharacters:bufCreatedDate];
		bufCreatedTime = (unichar*)malloc([time length] * sizeof(unichar));
		bufCreatedTimeLength = (NSUInteger)[time length];
		[time getCharacters:bufCreatedTime];
		
		NSString *reg = (NSString *)[attributeDict objectForKey:@"reg"];
		NSString *type = (NSString *)[attributeDict objectForKey:@"type"];
		NSString *model = (NSString *)[attributeDict objectForKey:@"model"];
		NSString *series = (NSString *)[attributeDict objectForKey:@"series"];
		NSString *description = (NSString *)[attributeDict objectForKey:@"descr"];
		self.name = (NSString *)[attributeDict objectForKey:@"name"];
        
        [self setAircraftTypeFromDescription:description andModel:model andSeries:series];
        
		//saving strings manually as the above data gets lost/jumbled up
		bufName = (unichar*)malloc([name length] * sizeof(unichar));
		bufNameLength = (NSUInteger)[name length];
		[name getCharacters:bufName];
		
		bufReg = (unichar*)malloc([reg length] * sizeof(unichar));
		bufRegLength = (NSUInteger)[reg length];
		[reg getCharacters:bufReg];
		
		bufType = (unichar*)malloc([type length] * sizeof(unichar));
		bufTypeLength = (NSUInteger)[type length];
		[type getCharacters:bufType];
		
		bufModel = (unichar*)malloc([model length] * sizeof(unichar));
		bufModelLength = (NSUInteger)[model length];
		[model getCharacters:bufModel];
		
		bufSeries = (unichar*)malloc([series length] * sizeof(unichar));
		bufSeriesLength = (NSUInteger)[series length];
		[series getCharacters:bufSeries];
		
		bufDesc = (unichar*)malloc([description length] * sizeof(unichar));
		bufDescLength = (NSUInteger)[description length];
		[description getCharacters:bufDesc];
		
		newFlight = nil;
		
	}
	else if([elementName isEqualToString:@"vjfi:Position"])
	{
        // set the aircraft position details
		self.position = [NSDictionary dictionaryWithDictionary:attributeDict];

		if(position != nil)
		{
			NSString* lastReport = (NSString*)[attributeDict objectForKey:@"lastReport"];
			NSString* latitude = (NSString*)[attributeDict objectForKey:@"latitude"];
			NSString* longitude = (NSString*)[attributeDict objectForKey:@"longtitude"];
			NSString* altitude = (NSString*)[attributeDict objectForKey:@"altitude"];
			NSString* heading = (NSString*)[attributeDict objectForKey:@"heading"];
			NSString* speed = (NSString*)[attributeDict objectForKey:@"speed"];
			
			float latValue = [latitude floatValue];
			float longValue = [longitude floatValue];
			
            //if long/lat is 0/0 then reposition to LHR
			if( (latValue == 0.0f) && (longValue == 0.0f) )
			{
				NSDictionary* newDictionary = nil;
				
				latValue = 51.469604f;
				longValue = (-0.453566f);
				latitude = [[NSNumber numberWithFloat:latValue] stringValue];
				longitude = [[NSNumber numberWithFloat:longValue] stringValue];
				
				newDictionary = [NSDictionary dictionaryWithObjectsAndKeys:	lastReport, @"lastReport",
								 latitude,	@"latitude",
								 longitude,	@"longitude",
								 altitude,	@"altitude",
								 heading	,	@"heading",
								 speed,		@"speed", nil];
				
				position = (NSMutableDictionary*)newDictionary;
			}
		}
	}
	else if([elementName isEqualToString:@"vjfi:FlightInformation"])
	{
		NSString* flightDate = (NSString*)[attributeDict objectForKey:@"flightDate"];
		NSString* flightTime = nil;
		flightDate = [Aircraft getUnicodeStandardDateAndTimeAsNSString:flightDate withFlag:FLAG_UNICODE_DATE];
		flightTime = [Aircraft getUnicodeStandardDateAndTimeAsNSString:flightDate withFlag:FLAG_UNICODE_TIME];
#if AIRCRAFT_ENABLE_PRINTS
		NSLog(@"vjfi:FlightInformation - flightDate:%@ and flightTime:%@",flightDate,flightTime);
#endif
		
		inFlightInfo = TRUE;
		newFlight = [Flight alloc];
		
        
        
		newFlight.carrier = [NSString stringWithString:(NSString *)[attributeDict objectForKey:@"carrier"]];
		newFlight.flightNo = [NSString stringWithString:(NSString *)[attributeDict objectForKey:@"flightNo"]];
		newFlight.beginning = [NSString stringWithString:(NSString *)[attributeDict objectForKey:@"origin"]];
		newFlight.destination = [NSString stringWithString:(NSString *)[attributeDict objectForKey:@"destination"]];
		newFlight.acReg = [NSString stringWithString:(NSString *)[attributeDict objectForKey:@"acReg"]];
        newFlight.departureTerminal = [NSString stringWithString:(NSString *)[attributeDict objectForKey:@"depTerm"]];
        newFlight.arrivalTerminal = [NSString stringWithString:(NSString *)[attributeDict objectForKey:@"arrTerm"]];
	}
	else if([elementName isEqualToString:@"vjfi:Movements"])
	{
		if(inFlightInfo)
		{
			inMovements = TRUE;
			flightIsOut = FALSE;
			flightInProgress = FALSE;
		}
	}
	else if([elementName isEqualToString:@"vjfi:Out"])
	{
#if AIRCRAFT_ENABLE_PRINTS
		//Debug - put specific aircraft reg here
		//and add breakpoint at NSLog call
		if([reg compare:@"G-VMEG"] == NSOrderedSame)
		{
			NSLog(@"vjfi:Out");
		}
#endif
		
		if(inMovements)
		{
			newFlight.moveOut = [NSDictionary dictionaryWithDictionary:attributeDict];
			
			NSString* status = (NSString*)[attributeDict objectForKey:@"status"];
			if (![status isEqualToString:@"-"])
			{
				self.outStatus = (NSString*)[attributeDict objectForKey:@"status"];
			}
			
			if([status compare:@"A"] == NSOrderedSame)
			{
				flightIsOut = TRUE;
				
				NSString* tmp = (NSString*)[attributeDict objectForKey:@"local"];
				if(tmp == nil)
				{
					tmp = @"TBC";
				}
				self.depTime = tmp;
			}
		}
	}
	else if([elementName isEqualToString:@"vjfi:In"])
	{
#if AIRCRAFT_ENABLE_PRINTS
		if([reg compare:@"G-VMEG"] == NSOrderedSame)
		{
			NSLog(@"vjfi:In");
		}
#endif
		
		if(inMovements)
		{
			inMovements = FALSE;
			inFlightInfo = FALSE;
			
			newFlight.moveIn = [NSDictionary dictionaryWithDictionary:attributeDict];
			
			NSString* status = (NSString*)[attributeDict objectForKey:@"status"];
			
			if (![status isEqualToString:@"-"])
			{
				self.inStatus = (NSString*)[attributeDict objectForKey:@"status"];
			}
			
			
			if( ([status compare:@"A"] != NSOrderedSame) && (flightIsOut) )
			{
				flightInProgress = TRUE;
			}
			
			if(flightInProgress)
			{
#if AIRCRAFT_ENABLE_PRINTS
				NSLog(@"Aircraft - Flight %@ valid",[self getReg]);
#endif
				NSString* tmp1 = nil;
				NSString* tmp2 = nil;
				NSString* tmp3 = nil;
				
				if([status compare:@"-"] != NSOrderedSame)
				{
					tmp2 = (NSString*)[attributeDict objectForKey:@"local"];
				}
				
				if(tmp2 == nil)
				{
					tmp2 = @"TBC";
				}
				else
				{
					tmp2 = [Aircraft getUnicodeStandardDateAndTimeAsNSString:tmp2 withFlag:FLAG_UNICODE_TIME_NO_SECONDS];
				}
				
				//save dep/arr times
				tmp1 = [Aircraft getUnicodeStandardDateAndTimeAsNSString:depTime withFlag:FLAG_UNICODE_TIME_NO_SECONDS];
				self.depTimeWithStatus = [NSString stringWithFormat:@"%@ (%@)", tmp1, outStatus];
				bufDepTime = (unichar*)malloc([tmp1 length] * sizeof(unichar));
				bufDepTimeLength = (NSUInteger)[tmp1 length];
				[tmp1 getCharacters:bufDepTime];
				
				self.arrTimeWithStatus = [NSString stringWithFormat:@"%@ (%@)", tmp2, inStatus];
				bufArrTime = (unichar*)malloc([tmp2 length] * sizeof(unichar));
				bufArrTimeLength = (NSUInteger)[tmp2 length];
				[tmp2 getCharacters:bufArrTime];
				
				//save flight number
				tmp3 = newFlight.carrier;
				tmp3 = [tmp3 stringByAppendingString:newFlight.flightNo];
#if AIRCRAFT_ENABLE_PRINTS
				NSLog(@"Saving flight no:%@",tmp3);
#endif
				bufFlightNo = (unichar*)malloc([tmp3 length] * sizeof(unichar));
				bufFlightNoLength = (NSUInteger)[tmp3 length];
				[tmp3 getCharacters:bufFlightNo];
								
				tmp3 = [tmp3 stringByReplacingOccurrencesOfString:@"VS" withString:@""];
				currentFlightNo = [NSNumber numberWithInt:[tmp3 intValue]];
				[currentFlightNo retain];
				
				//store flight
				[flights addObject:newFlight];
			}
			else
			{
#if AIRCRAFT_ENABLE_PRINTS
				NSLog(@"Aircraft - Flight %@ not valid",[self getReg]);
#endif
				[newFlight release];
				newFlight = nil;
			}
		}
		else
		{
			if(newFlight != nil)
			{
				[newFlight release];
				newFlight = nil;
			}
		}
	}
}

-(void)setAircraftTypeFromDescription:(NSString *)desc andModel:(NSString *)mod andSeries:(NSString *)series {
    
    if((desc != nil) && (series != nil)) {
    
        BOOL (^containsString)(NSString *, NSString *) = ^(NSString* input, NSString* match) {
            BOOL doesContain = YES;
            NSRange range;
            range = [match rangeOfString:input];
            if (range.location == NSNotFound) {
                doesContain = NO;
            }
            return doesContain;
        };
        
        BOOL containsCapsAirbus = containsString(@"AIRBUS", desc);
        BOOL containsCamelAirbus = containsString(@"Airbus", desc);
        BOOL containsLowerAirbus = containsString(@"airbus", desc);
        
        BOOL isAirbus = (containsCapsAirbus || containsCamelAirbus || containsLowerAirbus) ? YES : NO;
    
        if (isAirbus) {
            if ([mod isEqualToString:@"330"]) {
                if ([series isEqualToString:@"300"]) {
                    self.aircraftType = AircraftTypeAirbus330300;
                } else {
                    self.aircraftType = AircraftTypeAirbusGeneric;
                }
            } else if ([mod isEqualToString:@"340"]) {
                if ([series isEqualToString:@"300"]) {
                    self.aircraftType = AircraftTypeAirbus340300;
                } else if ([series isEqualToString:@"600"]) {
                    self.aircraftType = AircraftTypeAirbus340600;
                } else {
                    self.aircraftType = AircraftTypeAirbusGeneric;
                }
            }
        
        } else {
            
            self.isBoeing = YES;
            
            if ([series isEqualToString:@"200"]) {
                self.aircraftType = AircraftTypeBoeing747200;
            } else if ([series isEqualToString:@"400"]) {
                self.aircraftType = AircraftTypeBoeing747400;
            } else {
                self.aircraftType = AircraftTypeBoeingGeneric;
            }
        }
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
#if AIRCRAFT_ENABLE_PRINTS
	NSLog(@"finished Aircraft XML parsing");
#endif
	ready=YES;
	[pSky removeRequestFromCounter];
	[self findActiveFlight];
	[appPtr setPlaneDataAvailable:self];
}


- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
	NSLog(@"Error on Aircraft XML Parse: %@", [parseError localizedDescription] );
	valid = NO;
}

-(void) findActiveFlight
{
	NSString *stat;
	Flight *tempFlight = NULL;
	activeFlight = NULL;
	flying=NO;
	
	for(int i=0;i<flights.count;i++)
	{ 
		stat = @"A";
		tempFlight = [flights objectAtIndex:i];
		if( ([[tempFlight.moveOut objectForKey:@"status"] isEqualToString:stat]) && (![[tempFlight.moveIn objectForKey:@"status"] isEqualToString:stat]) )
		{
			activeFlight = [flights objectAtIndex:i];
			flying=YES;
#if AIRCRAFT_ENABLE_PRINTS
			NSLog(@"Active Flight");
#endif
		}
		else
		{
#if AIRCRAFT_ENABLE_PRINTS
			NSLog(@"Not Active Flight");
#endif
		}
		
	}
}

-(void) selectActiveFlight
{
	[selectedFlights removeAllObjects];
	if(activeFlight != NULL)
	{
		[selectedFlights addObject:activeFlight];
	}
}

-(void) selectFlightsFrom:(NSMutableArray *)inFlights to:(NSMutableArray *)inSelectedFlights withStart:(NSString *)inStart withEnd:(NSString *)inEnd
{
	[inSelectedFlights removeAllObjects];
	int flight_count=[inFlights count];
	for(int j=0;j<flight_count;j++){
		Flight * f = [inFlights objectAtIndex:j];
		NSString * start=[f beginning];
		if([start compare:inStart]==NSOrderedSame){
			NSString * end=[f destination];
				if([end compare:inEnd]==NSOrderedSame){
					// add plane
					[inSelectedFlights addObject:f];
				}
		}
	}
}

- (NSMutableArray *)getFlights
{
	return flights;
}


- (NSMutableArray *)getSelectedFlights
{
	return selectedFlights;
}


- (Flight *)getActiveFlight
{
	return activeFlight;
}



- (NSString*)getCreatedDate
{
	NSString* result = nil;
	
	result = (NSString*)[NSString stringWithCharacters:bufCreatedDate length:bufCreatedDateLength];
	
	return result;
}


- (NSString*)getCreatedTime
{
	NSString* result = nil;
	
	result = (NSString*)[NSString stringWithCharacters:bufCreatedTime length:bufCreatedTimeLength];
	
	return result;
}


- (NSString*)getName
{
	NSString* result = nil;
	
	result = (NSString*)[NSString stringWithCharacters:bufName length:bufNameLength];
	
	return result;
}

- (NSString*) getFlightNo
{
	NSString* result = nil;
	
	result = (NSString*)[NSString stringWithCharacters:bufFlightNo length:bufFlightNoLength];
	
	return result;
}

- (NSString*) getReg
{
	NSString* result = nil;
	
	result = (NSString*)[NSString stringWithCharacters:bufReg length:bufRegLength];
	
	return result;
}


- (NSString*) getType
{
	NSString* result = nil;
	
	result = (NSString*)[NSString stringWithCharacters:bufType length:bufTypeLength];
	
	return result;
}


- (NSString*) getModel
{
	NSString* result = nil;
	
	result = (NSString*)[NSString stringWithCharacters:bufModel length:bufModelLength];
	
	return result;
}


- (NSString*) getSeries
{
	NSString* result = nil;
	
	result = (NSString*)[NSString stringWithCharacters:bufSeries length:bufSeriesLength];
	
	return result;
}


- (NSString*) getDescription {
	NSString* result = nil;
	
	result = (NSString*)[NSString stringWithCharacters:bufDesc length:bufDescLength];
	
	return result;
}


- (NSString*) getDepTime
{
	NSString* result = nil;
	
	result = (NSString*)[NSString stringWithCharacters:bufDepTime length:bufDepTimeLength];
	
	return result;
}


- (NSString*) getArrTime
{
	NSString* result = nil;
	
	result = (NSString*)[NSString stringWithCharacters:bufArrTime length:bufArrTimeLength];
	
	return result;
}

- (NSString*) getDepTimeWithStatus
{
	return depTimeWithStatus;
}


- (NSString*) getArrTimeWithStatus
{
	return arrTimeWithStatus;
}


- (BOOL) isReady
{
	return ready;
}

- (void) dealloc
{
	if(bufCreatedDate)
	{
		free(bufCreatedDate);
		bufCreatedDate = nil;
	}
	
	if(bufCreatedTime)
	{
		free(bufCreatedTime);
		bufCreatedTime = nil;
	}
	
	if(bufName)
	{
		free(bufName);
		bufName = nil;
	}
	
	if(bufReg)
	{
		free(bufReg);
		bufReg = nil;
	}
	
	if(bufType)
	{
		free(bufType);
		bufType = nil;
	}
	
	if(bufModel)
	{
		free(bufModel);
		bufModel = nil;
	}
	
	if(bufSeries)
	{
		free(bufSeries);
		bufSeries = nil;
	}
	
	if(bufDesc)
	{
		free(bufDesc);
		bufDesc = nil;
	}
	
	if(bufDepTime)
	{
		free(bufDepTime);
		bufDepTime = nil;
	}
	
	if(bufArrTime)
	{
		free(bufArrTime);
		bufArrTime = nil;
	}

  [depTime release];
  [depTimeWithStatus release];
  [arrTimeWithStatus release];
  [inStatus release];
  [outStatus release];
  [name release];
	
	[super dealloc];
}

@end















