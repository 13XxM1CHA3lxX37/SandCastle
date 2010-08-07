#include <CPDistributedMessagingCenter.h>
#include <SandCastle.h>

@implementation SCClient

- (id)init {
	if((self = [super init])) {
		center = [CPDistributedMessagingCenter centerNamed:@"com.collab.sandcastle.center"];
	}
	
	return self;
}

+ (id)sharedInstance {
	static SCClient *sharedInstance = nil;
	
	@synchronized(self) {
		if (sharedInstance == nil)
			sharedInstance = [[SCClient alloc] init];
	}
	
	return sharedInstance;
}

- (id)messageDictionaryWithAction:(NSString *)action sourcePath:(NSString *)sourcePath destPath:(NSString *)destPath {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	[dict setObject:action forKey:@"type"];
	[dict setObject:[NSArray arrayWithObjects:destPath ?: @"", sourcePath ?: @"", nil] forKey:@"target"];
	
	return dict;
}

- (NSDictionary *)performActionWithDictionary:(NSDictionary *)dict error:(NSError **)error {
	NSDictionary *reply = [center sendMessageAndReceiveReplyName:@"sandcastle.notification" userInfo:dict];
	
	if (error) {
		NSString *err = [reply objectForKey:@"error"];
		if (err) *error = [NSError errorWithDomain:@"SCError" code:[err hash] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:err, NSLocalizedDescriptionKey, nil]];
		else *error = nil;
	}
	
	return reply;
}

- (NSData *)readFileAtPath:(NSString *)path error:(NSError **)error {
	NSMutableDictionary *info = [self messageDictionaryWithAction:@"read" sourcePath:path destPath:nil];	
	NSDictionary *result = [self performActionWithDictionary:info error:error];
	return [result objectForKey:@"data"];
} 

- (BOOL)writeData:(NSData *)data toPath:(NSString *)path error:(NSError **)error {
	NSMutableDictionary *info = [self messageDictionaryWithAction:@"write" sourcePath:nil destPath:path];	
	[info setObject:data forKey:@"data"];
	[self performActionWithDictionary:info error:error];
	return !*error;
}

- (BOOL)appendData:(NSData *)data toPath:(NSString *)path error:(NSError **)error {
	NSMutableDictionary *info = [self messageDictionaryWithAction:@"append" sourcePath:nil destPath:path];	
	[info setObject:data forKey:@"data"];
	[self performActionWithDictionary:info error:error];
	return !*error;
}

- (BOOL)copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)error {
	NSMutableDictionary *info = [self messageDictionaryWithAction:@"copy" sourcePath:srcPath destPath:dstPath];	
	[self performActionWithDictionary:info error:error];
	return !*error;
}

- (BOOL)moveItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)error {
	NSMutableDictionary *info = [self messageDictionaryWithAction:@"move" sourcePath:srcPath destPath:dstPath];	
	[self performActionWithDictionary:info error:error];
	return !*error;
}

- (BOOL)linkItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)error {
	NSMutableDictionary *info = [self messageDictionaryWithAction:@"link" sourcePath:srcPath destPath:dstPath];	
	[self performActionWithDictionary:info error:error];
	return !*error;
}

- (BOOL)removeItemAtPath:(NSString *)path error:(NSError **)error {
	NSMutableDictionary *info = [self messageDictionaryWithAction:@"remove" sourcePath:nil destPath:path];	
	[self performActionWithDictionary:info error:error];
	return !*error;
}

- (BOOL)fileExistsAtPath:(NSString *)path error:(NSError **)error {
	NSMutableDictionary *info = [self messageDictionaryWithAction:@"exists" sourcePath:path destPath:nil];	
	[self performActionWithDictionary:info error:error];
	return [[info objectForKey:@"exists"] boolValue];
}

- (BOOL)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)createIntermediates error:(NSError **)error {
	NSMutableDictionary *info = [self messageDictionaryWithAction:@"mkdir" sourcePath:nil destPath:path];	
	[info setObject:[NSNumber numberWithBool:createIntermediates] forKey:@"create-intermediates"];
	[self performActionWithDictionary:info error:error];
	return !*error;
}

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error {
	NSMutableDictionary *info = [self messageDictionaryWithAction:@"list" sourcePath:path destPath:nil];	
	NSDictionary *result = [self performActionWithDictionary:info error:error];
	return [result objectForKey:@"items"];
}

- (NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError **)error { 
	NSMutableDictionary *info = [self messageDictionaryWithAction:@"stat" sourcePath:path destPath:nil];	
	NSDictionary *result = [self performActionWithDictionary:info error:error];
	return [result objectForKey:@"stat"];
}

- (NSString *)temporaryPathToMove {
	char path[] = "sandcastle.XXXXXX";
	return [NSString stringWithUTF8String:mktemp(path)];
}

@end


static __attribute__((constructor)) void sandcastle_init() {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	%init;
	[SCClient sharedInstance];
	
	[pool release];
}