//
//  Flight.m
//  VAA
//
//  Created by Calum McMinn on 30/09/2009.
//  Copyright 2009 Tag Games. All rights reserved.
//

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
