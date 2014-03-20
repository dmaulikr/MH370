

#import <Foundation/Foundation.h>

@interface Flight : NSObject {
	NSString *carrier;
	NSString *flightNo;
	NSString *beginning;
	NSString *destination;
	NSString *acReg;
	NSDictionary *moveOut;	//Contains NSString *status, NSDate *local, NSDate *utc
	NSDictionary *moveIn;	//Contains NSString *status, NSDate *local, NSDate *utc
	NSDictionary *moveOn;	//Contains NSString *status, NSDate *local, NSDate *utc
	NSDictionary *moveOff;	//Contains NSString *status, NSDate *local, NSDate *utc
    NSString *departureTerminal;
    NSString *arrivalTerminal;
}

@property (nonatomic, retain) NSString *carrier;
@property (nonatomic, retain) NSString *flightNo;
@property (nonatomic, retain) NSString *beginning;
@property (nonatomic, retain) NSString *destination;
@property (nonatomic, retain) NSString *acReg;
@property (nonatomic, retain) NSDictionary *moveOut;
@property (nonatomic, retain) NSDictionary *moveIn;
@property (nonatomic, retain) NSDictionary *moveOn;
@property (nonatomic, retain) NSDictionary *moveOff;
@property (nonatomic, retain) NSString *departureTerminal;
@property (nonatomic, retain) NSString *arrivalTerminal;

@end
