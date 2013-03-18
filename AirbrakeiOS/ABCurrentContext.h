#import <Foundation/Foundation.h>

@interface ABCurrentContext : NSObject
@property (nonatomic, strong, readonly) NSString* operatingSystem;
@property (nonatomic, readonly) unsigned long long physicalMemoryInBytes;

@property (nonatomic, strong, readonly) NSString* executableUUID;
@property (nonatomic, readonly) NSString* applicationBuild;
@property (nonatomic, readonly) NSString* applicationVersion;
@property (nonatomic, strong, readonly) NSString* debugOrRelease;

@property (nonatomic, strong, readonly) NSString* clientAPIVersion;
@end
