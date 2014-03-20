

#import <Foundation/Foundation.h>

#import "Airport.h"

@protocol AirPortDataManagerDelegate <NSObject>
@end

@interface AirportDataManager : NSObject <NSFetchedResultsControllerDelegate>

@property (nonatomic) BOOL hasRefreshed;
@property (assign, nonatomic) id <AirPortDataManagerDelegate> delegate;
@property (retain, nonatomic) NSMutableData *scheduleData;
@property (retain, nonatomic) NSFetchedResultsController * fetchedResultsController;

+ (AirportDataManager *)sharedInstance;



- (Airport *)airportForCode:(NSString *)code;
- (Airport *)airportForName:(NSString *)na;
- (void)requestAirports;

- (int)airportCount;

- (NSArray *)allAirports;

@end
