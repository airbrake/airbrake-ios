
#import "ABCrashReport.h"

@interface ABCrashReport()
@property (nonatomic, strong, readwrite) NSString* UUID;
@end

@implementation ABCrashReport

-(id)init {
    self = [super init];
    if ( self ) {
        CFUUIDRef UUIDObject = CFUUIDCreate(NULL);
        self.UUID = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, UUIDObject));
    }
    return self;
}

@end
