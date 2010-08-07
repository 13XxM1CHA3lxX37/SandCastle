#include <Foundation/Foundation.h>

@class SCClient, CPDistributedMessagingCenter;

@interface SCClient : NSObject {
	CPDistributedMessagingCenter *center;
}

+ (SCClient *)sharedInstance;

- (BOOL)copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)error;
- (BOOL)moveItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)error;
- (BOOL)linkItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)error;
- (NSString *)temporaryPathToMove;
- (BOOL)removeItemAtPath:(NSString *)path error:(NSError **)error;
- (BOOL)fileExistsAtPath:(NSString *)path error:(NSError **)error;
- (BOOL)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)createIntermediates error:(NSError **)error;
- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error;
- (NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError **)error;


@end