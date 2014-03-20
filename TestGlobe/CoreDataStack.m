

#import "CoreDataStack.h"

@interface CoreDataStack ()
- (void)contextHasChanged:(NSNotification *)notification;
@end

@implementation CoreDataStack

static CoreDataStack *sharedInstance = nil;

+ (CoreDataStack *)sharedInstance{
	@synchronized(self){
		if(sharedInstance == nil) {
            sharedInstance = [[self alloc] init];
        }
	}
	return sharedInstance;
}

- (id)init {
    if ((self = [super init])) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextHasChanged:) name:NSManagedObjectContextDidSaveNotification object:nil];
    }
    return self;
}

#pragma mark Core Data Stack

- (void)contextHasChanged:(NSNotification*)notification
{
//    NSLog(@"%s ", __PRETTY_FUNCTION__);
//
//  if ([notification object] == self.managedObjectContext) return;
//
//  if (![NSThread isMainThread]) {
//    [self performSelectorOnMainThread:@selector(contextHasChanged:) withObject:notification waitUntilDone:YES];
//    return;
//  }
//
//  [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
}

- (NSManagedObjectContext *) managedObjectContext {
       
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return _managedObjectContext;
}


- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    _managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"datastore.sqlite"]];
	NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
 //   NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    
   // persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    // Create options dictionary to handle automatic migration
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];


    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
    }
    return _persistentStoreCoordinator;
}

#pragma mark Application's Documents directory

- (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

@end