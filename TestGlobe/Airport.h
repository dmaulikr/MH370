//
//  Airport.h
//  VAA
//
//  Created by waitea on 03/04/2013.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Airport : NSManagedObject

@property (nonatomic, retain) NSString * code;
@property (nonatomic, retain) NSString * capsname;
@property (nonatomic, retain) NSString * youtube;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * primary;

@end
