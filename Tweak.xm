#include <CPDistributedMessagingCenter.h>

@interface SandCastleObserver : NSObject {
	CPDistributedMessagingCenter *center;
}

@end

@implementation SandCastleObserver

- (id)init {
	if((self = [super init])) {
		center = [[CPDistributedMessagingCenter centerNamed:@"com.collab.sandcastle.center"] retain];
		[center runServerOnCurrentThread];

		[center registerForMessageName:@"sandcastle.notification" target:self selector:@selector(handleNotification:userInfo:)];
	}
	
	return self;
}

- (void)handleNotification:(NSString *)name userInfo:(NSDictionary *)userInfo {
	NSLog(@"handleNotification:%@ userInfo:%@", name, userInfo);

	NSString *type = [userInfo objectForKey:@"type"];
	id paths = [userInfo objectForKey:@"target"];
	NSFileManager *manager = [NSFileManager defaultManager];
	NSError *error = nil;
	NSData *result = nil;
	
	if ([type isEqual:@"remove"] || [type isEqual:@"delete"]) {
		NSString *path = [paths isKindOfClass:[NSArray class]] ? [paths objectAtIndex:0] : paths;
		[manager removeItemAtPath:path error:&error]; 
	} else if ([type isEqual:@"move"]) {
		NSString *sourcePath = [paths objectAtIndex:0];
		NSString *destPath = [paths objectAtIndex:1];
		[manager copyItemAtPath:sourcePath toPath:destPath error:&error];
		if (!error) [manager removeItemAtPath:sourcePath error:&error];
	} else if ([type isEqual:@"copy"]) {
		NSString *sourcePath = [paths objectAtIndex:0];
		NSString *destPath = [paths objectAtIndex:1];
		[manager copyItemAtPath:sourcePath toPath:destPath error:&error];
	} else if ([type isEqual:@"append"]) {
		NSData *data = [userInfo objectForKey:@"data"];
	} else if ([type isEqual:@"write"]) {
		NSData *data = [userInfo objectForKey:@"data"];
	} else if ([type isEqual:@"read"]) {
		// FIXME: read path then send back result
	} else { // invalid action
		// FIXME: generate appropriate error into the error variable
	}

	if (error) {
		// FIXME: handle error case, send error back
	} else {
		// FIXME: generate success message

		if (result) {
			// FIXME: add result to return data
		}

		// FIXME: send back success message
	}
}

- (void)dealloc {
	[center release];
	[super dealloc];
}

@end

static SandCastleObserver *observer = nil;

static __attribute__((constructor)) void sandcastle_init() {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	%init;	      
	observer = [[SandCastleObserver alloc] init];
	
	[pool release];
}