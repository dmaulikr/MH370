

#import "Flight.h"


@implementation Flight

@synthesize carrier, flightNo, beginning, destination, acReg, moveOut, moveIn, moveOn, moveOff, departureTerminal, arrivalTerminal;

- (void)dealloc {
    [carrier release];
    [flightNo release];
    [beginning release];
    [destination release];
    [acReg release];
    [moveOut release];
    [moveIn release];
    [moveOn release];
    [moveOff release];
    [departureTerminal release];
    [arrivalTerminal release];
    [super dealloc]; 
}

@end
