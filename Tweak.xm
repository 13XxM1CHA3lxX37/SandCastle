#include <CPDistributedMessagingCenter.h>

@interface SCObserver : NSObject {
	CPDistributedMessagingCenter *center;
}

+ (id)sharedObserver;
- (NSDictionary *)handleNotification:(NSString *)name userInfo:(NSDictionary *)userInfo;

@end

#ifdef DEBUG
#define SCLog NSLog
#else
#define SCLog(...)
#endif

typedef enum {
	kSCDestinationPath,
	kSCSourcePath
} SCPathIndex;

@implementation SCObserver

+ (id)sharedObserver {
	static SCObserver *observer = nil;
	
	if (observer == nil)
		observer = [[self alloc] init];
		
	return observer;
}

- (id)init {
	if((self = [super init])) {
		center = [[CPDistributedMessagingCenter centerNamed:@"com.collab.sandcastle.center"] retain];
		[center runServerOnCurrentThread];

		[center registerForMessageName:@"sandcastle.notification" target:self selector:@selector(handleNotification:userInfo:)];
	}
	
	return self;
}

/* Valid actions: [remove|delete], move, copy, write, read, append, link, mkdir, stat, list, exists */

- (NSDictionary *)handleNotification:(NSString *)name userInfo:(NSDictionary *)userInfo {
	SCLog(@"SC:Debug: handleNotification:%@ userInfo:%@", name, userInfo);

	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *error = nil;
	NSData *resultData = nil;
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	
	NSString *type = [userInfo objectForKey:@"type"];
	NSArray *paths = [userInfo objectForKey:@"target"];
	
	NSString *destPath = [paths objectAtIndex:kSCDestinationPath];
	NSString *sourcePath = [paths objectAtIndex:kSCSourcePath];
	
	if ([type isEqual:@"remove"] || [type isEqual:@"delete"]) {
		if (destPath == nil) { error = @"No destination path provided to remove."; goto error; }
		
		BOOL ret = [manager removeItemAtPath:destPath error:NULL]; 
		
		if (!ret) { error = @"Unable to remove file."; goto error; }
	} else if ([type isEqual:@"move"]) {
		if (sourcePath == nil || destPath == nil) { error = @"No source or destination path provided."; goto error; }
		
		BOOL ret = [manager copyItemAtPath:sourcePath toPath:destPath error:NULL];
		if (ret) ret = [manager removeItemAtPath:sourcePath error:NULL];
		
		if (!ret) { error = @"Unable to move file."; goto error; }
	} else if ([type isEqual:@"copy"]) {
		if (sourcePath == nil || destPath == nil) { error = @"No source or destination path provided."; goto error; }
		
		BOOL ret = [manager copyItemAtPath:sourcePath toPath:destPath error:NULL];
		
		if (!ret) { error = @"Unable to copy file."; goto error; }
	} else if ([type isEqual:@"read"]) {
		if (sourcePath == nil) { error = @"No source path provided."; goto error; }
		
		resultData = [NSData dataWithContentsOfFile:sourcePath];
		
		if (resultData == nil) { error = @"Unable to read file."; goto error; }
	} else if ([type isEqual:@"write"]) {
		NSData *data = [userInfo objectForKey:@"data"];
		
		if (data == nil) { error = @"No data provided to append to file."; goto error; }
		if (destPath == nil) { error = @"No desintation path provided to write to."; goto error; }
		
		BOOL ret = [data writeToFile:destPath atomically:YES];
		
		if (!ret) { error = @"Unable to write to file."; goto error; }
	} else if ([type isEqual:@"append"]) {
		NSData *data = [userInfo objectForKey:@"data"];
		
		if (data == nil) { error = @"No data provided to append to file."; goto error; }
		if (destPath == nil) { error = @"No desintation path provided to append to."; goto error; }
		
		NSFileHandle *fd = [NSFileHandle fileHandleForWritingAtPath:destPath];
		
		if (fd == nil) { error = @"No file found at the destination path."; goto error; }
		
		[fd seekToEndOfFile];
		[fd writeData:data];
		[fd closeFile];
	} else if ([type isEqual:@"link"]) {
		if (sourcePath == nil || destPath == nil) { error = @"No source or destination path provided."; goto error; }

		BOOL ret = [manager createSymbolicLinkAtPath:destPath withDestinationPath:sourcePath error:NULL];

		if (!ret) { error = @"Unable to link file."; goto error; }
	} else if ([type isEqual:@"mkdir"]) {
		if (destPath == nil) { error = @"No destination path provided."; goto error; }

		BOOL ret = [manager createDirectoryAtPath:destPath withIntermediateDirectories:[[userInfo objectForKey:@"intermediate"] boolValue] attributes:nil error:NULL];

		if (!ret) { error = @"Unable to make directory."; goto error; }
	} else if ([type isEqual:@"list"]) {
		if (sourcePath == nil) { error = @"No source path provided."; goto error; }

		NSArray *contents = [manager contentsOfDirectoryAtPath:sourcePath error:NULL];

		if (!contents) { error = @"Unable to list directory."; goto error; }
		
		[result setObject:contents forKey:@"list"];
	} else if ([type isEqual:@"exists"]) {
		if (sourcePath == nil) { error = @"No source path provided."; goto error; }

		BOOL exists = [manager fileExistsAtPath:sourcePath];
		[result setObject:[NSNumber numberWithBool:exists] forKey:@"exists"];
	} else if ([type isEqual:@"stat"]) {
		if (sourcePath == nil) { error = @"No source path provided."; goto error; }
		
		NSDictionary *stat = [manager attributesOfItemAtPath:sourcePath error:NULL];
		
		if (!stat) { error = @"Unable to obtain file attributes."; goto error; }
		
		[result setObject:stat forKey:@"stat"];
	} else {
		{ error = @"Invalid action requested."; goto error; }
	}
	
	if (error != nil) { error:
		[result setObject:error forKey:@"error"];
		[result setObject:@"error" forKey:@"status"];
		
		NSLog(@"SC:Error: %s", error);
	} else {
		if (resultData != nil) {
			[result setObject:resultData forKey:@"data"];
		}
		
		[result setObject:@"success" forKey:@"status"];
	}
	
	return result;
}

- (void)dealloc {
	[center release];
	[super dealloc];
}

@end

static __attribute__((constructor)) void sandcastle_init() {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	%init;	      
	[[SCObserver alloc] sharedObserver];
	
	[pool release];
}