
#import "ABCrashReport.h"

@interface ABCrashReport()
@property (nonatomic, strong, readwrite) NSString* UUID;
@property (nonatomic, strong, readwrite) PLCrashReport* crashReport;
@end

@implementation ABCrashReport

-(id)initWithCrashReport:(PLCrashReport*)crashReport {
    self = [super init];
    if ( self ) {
        CFUUIDRef UUIDObject = CFUUIDCreate(NULL);
        self.UUID = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, UUIDObject));
    }
    return self;
}

-(NSString*)stringValue { 
    return [PLCrashReportTextFormatter stringValueForCrashReport:self.crashReport withTextFormat:PLCrashReportTextFormatiOS];
}

@end
