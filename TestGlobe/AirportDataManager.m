//
//  AirportPersistenceManager.m
//  VAA
//
//  Created by waitea on 02/04/2013.
//
//

#warning This code is should be revised. It was written with very little time remaining. The refresh CoreData in particular.

#import "AirportDataManager.h"
#import "VAAAppDelegate.h"

#import "CoreDataStack.h"

static NSString *const kAirportDataExistsInCoreDataFlagKey = @"airportDataExistsInCoreData";

@interface AirportDataManager () {

    NSPredicate *airportByCodePredicate;
}


@end

@implementation AirportDataManager {
    NSPredicate *airportByNamePredicate;
    NSArray *_allAirports;
    NSFetchedResultsController *_fetchedResultsController;
    NSError *error;
}

#pragma mark Init

static AirportDataManager *sharedInstance = nil;

+ (AirportDataManager *)sharedInstance {
    @synchronized (self) {
        if (sharedInstance == nil) {
            sharedInstance = [[self alloc] init];
        }
    }
    return sharedInstance;
}

- (id)init {

    NSLog(@"%s ", __PRETTY_FUNCTION__);
    self = [super init];
    if (self) {
        airportByCodePredicate = [[NSPredicate predicateWithFormat:@"code = $CODE"] retain];
        airportByNamePredicate = [[NSPredicate predicateWithFormat:@"name = $NAME"] retain];
		_hasRefreshed = NO;
		[self loadData];
    }
    return self;
}

- (void)loadData {
	
    NSUInteger count = self.fetchedResultsController.fetchedObjects.count;
    if ((count < 1)) {
        [self initialPopulateCoreData];
    }
		
}

- (NSFetchedResultsController *)fetchedResultsController {

    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *context = [[CoreDataStack sharedInstance] managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription
            entityForName:@"Airport" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];

    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"code" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];

    [fetchRequest setFetchBatchSize:20];

    NSFetchedResultsController *theFetchedResultsController =
            [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                managedObjectContext:context sectionNameKeyPath:nil cacheName:@"com.lbi.vaa.airportsCache"];

    _fetchedResultsController = [theFetchedResultsController retain];

    _fetchedResultsController.delegate = self;

    [_fetchedResultsController performFetch:&error];

    //NSLog(@"Thread %@", [NSThread currentThread]);

    [theFetchedResultsController release];
    [sort release];
    [fetchRequest release];
    return _fetchedResultsController;

}

#pragma mark Dealloc

- (void)dealloc {

    [self.scheduleData release];

    [_allAirports release];

    [self.fetchedResultsController release];

    [_fetchedResultsController release];
    [super dealloc];
}

#pragma mark Request Airports

- (void)requestAirports {
	
	if (!_hasRefreshed) {
		NSLog(@"Requesting Airports from Service");
		NSURL *url = [NSURL URLWithString:kVAServiceURLSchedule];
		NSMutableURLRequest *r = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0f];
		NSURLConnection *c = [[NSURLConnection alloc] initWithRequest:r delegate:self];
		[c release];
	} else {
		NSLog(@"Airports refreshed already, no need");
	}
    
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {

}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (self.scheduleData == nil) {
        self.scheduleData = [[NSMutableData alloc] init];
    }
    [self.scheduleData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    //NSString *completedResponse = [[NSString alloc] initWithData:self.scheduleData encoding:NSUTF8StringEncoding];
    [self processScheduleResponse:self.scheduleData];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.scheduleData = nil;
}

- (void)processScheduleResponse:(NSMutableData *)d {

    //provide this
    NSMutableArray *arrayOfSchedules = [NSMutableArray array];

	NSError *err = nil;
    CXMLDocument *schedules = [[CXMLDocument alloc] initWithData:d options:0 error:&err];
	
	if (err != nil) {
		NSLog(@"THERE WAS AN ERROR PARSING THE XML, UPDATE FAILED");
		return;
	}
	
	
    NSDictionary *mappings = [NSDictionary dictionaryWithObject:@"http://schemas.virgin-atlantic.com/IT.Lite/VJam/ScheduleInfo/2010/02/04" forKey:@"vjsi"];

    NSString *startDate;
    NSString *endDate;
    NSString *seasonName;

    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy-MM-dd"];

    NSDate *now = [[[NSDate alloc] init] autorelease];
    now = [format dateFromString:[format stringFromDate:now]];

    NSArray *seasons = [schedules nodesForXPath:@"//vjsi:Season" namespaceMappings:mappings error:nil];
    NSArray *flights;

    for (CXMLElement *season in seasons) {

        startDate = [[season attributeForName:@"startDate"] stringValue];
        endDate = [[season attributeForName:@"endDate"] stringValue];
        seasonName = [[season attributeForName:@"season"] stringValue];

        NSComparisonResult dateCompare = [now compare:[format dateFromString:startDate]]; //The receiver is later in time than anotherDate, NSOrderedDescending
        NSComparisonResult dateEndCompare = [now compare:[format dateFromString:endDate]];

        if (((dateCompare == NSOrderedDescending) || (dateCompare == NSOrderedSame)) && ((dateEndCompare == NSOrderedAscending) || (dateEndCompare == NSOrderedSame))) {
            flights = season.children;
            for (CXMLElement *flight in flights) {
                NSArray *entries = [flight children];
                for (CXMLElement *entry in entries) {
                    [arrayOfSchedules addObject:entry];
                }
            }
        }
    }
	

    [self updateCoreDataWithScheduleData:arrayOfSchedules];

}


#pragma mark Core Data Existence/Init

- (void)initialPopulateCoreData {

    NSLog(@"Initially populating CoreData");
    //Create a context for the current thread

    NSManagedObjectContext *context = [[CoreDataStack sharedInstance] managedObjectContext];

    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"AirportData" ofType:@"plist"];
    NSArray *apArray = [NSArray arrayWithContentsOfFile:plistPath];

    static NSString *const codeKey = @"code";
    static NSString *const nameKey = @"name";
    static NSString *const capsNameKey = @"capsname";
    static NSString *const primaryKey = @"isPrimary";
    static NSString *const latKey = @"latitude";
    static NSString *const lonKey = @"longitude";

    for (NSDictionary *apDic in apArray) {
        Airport *ap = [NSEntityDescription insertNewObjectForEntityForName:[NSString stringWithFormat:@"%@", [Airport class]] inManagedObjectContext:context];
        ap.code = [apDic objectForKey:codeKey];
        ap.name = [apDic objectForKey:nameKey];
        ap.capsname = [apDic objectForKey:capsNameKey];
        ap.latitude = [apDic objectForKey:latKey];
        ap.longitude = [apDic objectForKey:lonKey];
        ap.primary = [apDic objectForKey:primaryKey];
    }

    NSError *err;
    if (![context save:&err]) {
        NSLog(@"Handle errors here?");
    }

    [self saveInitialPopulatedFlag];

}

- (void)saveInitialPopulatedFlag {
    NSLog(@"Default Airport data saved to Core Data");
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kAirportDataExistsInCoreDataFlagKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}



#pragma mark CoreData Interface

- (void)updateCoreDataWithScheduleData:(NSMutableArray *)arr {

    NSLog(@"%s ", __PRETTY_FUNCTION__);

    dispatch_queue_t backgroundProcess;
    backgroundProcess = dispatch_queue_create("coreDataRefresh", NULL);
    dispatch_async(backgroundProcess, ^(void) {

        @autoreleasepool {

            //Create a context for the current thread
            NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];
            [context setPersistentStoreCoordinator:[CoreDataStack sharedInstance].persistentStoreCoordinator];
            context.undoManager = nil;

            //Get all airports
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Airport"];

            NSError *err;
            NSArray *airports = [context executeFetchRequest:fetchRequest error:&error];

            //Set all airports not primary
            for (Airport *a in airports) {
                a.primary = [NSNumber numberWithBool:NO];
            }
			
			NSMutableArray *recentlyAddedAirportCodes = [NSMutableArray array];
			
            for (CXMLElement *schedule in arr) {

                @autoreleasepool {

                    //Process origin airport
                    NSString *originCode = [[[schedule attributeForName:@"origin"] stringValue] retain];
                    NSPredicate *pred = [airportByCodePredicate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:originCode forKey:@"CODE"]];
                    Airport *existingOrigin = [[airports filteredArrayUsingPredicate:pred] lastObject];
                    if (existingOrigin) {
                        (existingOrigin.primary = [NSNumber numberWithBool:YES]);
                    }
                    else {
						NSPredicate *recentPred = [NSPredicate predicateWithFormat:@"(self like[c] %@)", originCode];
						NSArray *filteredRecent = [recentlyAddedAirportCodes filteredArrayUsingPredicate:recentPred];
						if ([filteredRecent count] == 0) {
							[self createNewAirportFromSchedule:schedule withDestination:NO inManagedObjectContext:context];
							[recentlyAddedAirportCodes addObject:originCode];
						}
					}

                    NSString *destinationCode = [[[schedule attributeForName:@"destination"] stringValue] retain];
                    pred = [airportByCodePredicate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:destinationCode forKey:@"CODE"]];
                    Airport *existingDest = [[airports filteredArrayUsingPredicate:pred] lastObject];
                    if (existingDest) {
                        existingDest.primary = [NSNumber numberWithBool:YES];
                    }
					else {
						NSPredicate *recentPred = [NSPredicate predicateWithFormat:@"(self like[c] %@)", destinationCode];
						NSArray *filteredRecent = [recentlyAddedAirportCodes filteredArrayUsingPredicate:recentPred];
						if ([filteredRecent count] == 0) {
							[self createNewAirportFromSchedule:schedule withDestination:YES inManagedObjectContext:context];
							[recentlyAddedAirportCodes addObject:destinationCode];
						}
                    }

                    [originCode release];
                    [destinationCode release];
                }

            }

            [context save:&err];
            [context release];
            [fetchRequest release];
			
            NSLog(@"Airport data refreshed from service.");
			
			_hasRefreshed = YES;
			
        }


    });

    //[self refreshAirportsFromCoreData];

}


- (Airport *)createNewAirportFromSchedule:(CXMLElement *)el withDestination:(BOOL)dest inManagedObjectContext:(NSManagedObjectContext *)context {

    
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
	
    Airport *ap = [NSEntityDescription insertNewObjectForEntityForName:[NSString stringWithFormat:@"%@", [Airport class]] inManagedObjectContext:context];
    ap.primary = [NSNumber numberWithBool:YES];

    if (dest) {
        ap.code = [[el attributeForName:@"destination"] stringValue];
        ap.name = [[el attributeForName:@"destinationName"] stringValue];
        ap.capsname = [[[el attributeForName:@"destinationName"] stringValue] uppercaseString];
        ap.latitude = [f numberFromString:[[el attributeForName:@"destinationY"] stringValue]];
        ap.longitude = [f numberFromString:[[el attributeForName:@"destinationX"] stringValue]];
    } else {
        ap.code = [[el attributeForName:@"origin"] stringValue];
        ap.name = [[el attributeForName:@"originName"] stringValue];
        ap.capsname = [[[el attributeForName:@"originName"] stringValue] uppercaseString];
        ap.latitude = [f numberFromString:[[el attributeForName:@"originY"] stringValue]];
        ap.longitude = [f numberFromString:[[el attributeForName:@"originX"] stringValue]];
    }
	
	NSLog(@"Creating new Airport in CoreData: %@", ap.name);
	
    [f release];
    return ap;

}

#pragma mark Airport Lookups

- (Airport *)airportForCode:(NSString *)code {

	if (!code) {
		return nil;
	}
	
    NSPredicate *pred = [airportByCodePredicate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:code forKey:@"CODE"]];
    NSArray *array = [self.fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:pred];
    return [array lastObject];

}

- (Airport *)airportForName:(NSString *)na {

	if (!na) {
		return nil;
	}
	
    NSPredicate *pred = [airportByNamePredicate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:na forKey:@"NAME"]];
    NSArray *array = [self.fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:pred];
    return [array lastObject];

}

- (int)airportCount {
    return [[self allAirports] count];
}

- (NSArray *)allAirports {
    return [self.fetchedResultsController fetchedObjects];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    NSLog(@"%s ", __PRETTY_FUNCTION__);
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    NSLog(@"%s ", __PRETTY_FUNCTION__);
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    NSLog(@"%s ", __PRETTY_FUNCTION__);
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    NSLog(@"%s ", __PRETTY_FUNCTION__);
    //[self.fetchedResultsController performFetch:&error];
}


@end
