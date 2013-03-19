#import <UIKit/UIKit.h>
#import <mach-o/ldsyms.h>
#import "ABCurrentContext.h"
#import "ABConstants.h"

@interface ABCurrentContext()
@property (nonatomic, strong, readwrite) NSString* deviceName;
@property (nonatomic, strong, readwrite) NSString* operatingSystem;
@property (nonatomic, readwrite) unsigned long long physicalMemoryInBytes;
@property (nonatomic, strong, readwrite) NSString* applicationBuild;
@property (nonatomic, strong, readwrite) NSString* applicationVersion;
@property (nonatomic, strong, readwrite) NSString* debugOrRelease;
@property (nonatomic, strong, readwrite) NSString* clientAPIVersion;
@end

@implementation ABCurrentContext

-(id)init {
    self = [super init];
    if ( self ) {
        NSString* deviceName = [UIDevice currentDevice].model;
        NSProcessInfo* processInfo = [[NSProcessInfo alloc] init];
        NSString* operatingSystemName = [UIDevice currentDevice].systemName;
        NSString* operatingSystemVersion = [UIDevice currentDevice].systemVersion;
        unsigned long long physicalMemoryInBytes = processInfo.physicalMemory;
        NSString* applicationBuild = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        NSString* applicationVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSString* debugOrRelease = @"Release";
        NSString* clientAPIVersion = ABClientAPIVersion;
#if DEBUG 
        debugOrRelease = @"Debug";
#endif
        self.deviceName = deviceName;
        self.operatingSystem = [NSString stringWithFormat:@"%@ %@", operatingSystemName, operatingSystemVersion];
        self.physicalMemoryInBytes = physicalMemoryInBytes;
        self.applicationBuild = applicationBuild;
        self.applicationVersion = applicationVersion;
        self.debugOrRelease = debugOrRelease;
        self.clientAPIVersion = clientAPIVersion;
    }
    return self;
}

-(NSString*)executableUUID {
    // See: http://stackoverflow.com/questions/10119700/how-to-get-mach-o-uuid-of-a-running-process
    const uint8_t *command = (const uint8_t *)(&_mh_execute_header + 1);
    for (uint32_t idx = 0; idx < _mh_execute_header.ncmds; ++idx) {
        if (((const struct load_command *)command)->cmd == LC_UUID) {
            command += sizeof(struct load_command);
            return [NSString stringWithFormat:@"%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X",
                    command[0], command[1], command[2], command[3],
                    command[4], command[5],
                    command[6], command[7],
                    command[8], command[9],
                    command[10], command[11], command[12], command[13], command[14], command[15]];
        } else {
            command += ((const struct load_command *)command)->cmdsize;
        }
    }
    return nil;
}

@end
