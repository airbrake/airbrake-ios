#import <CrashReporter/CrashReporter.h>
#import <Foundation/Foundation.h>

@interface ABCrashReport : NSObject
@property (nonatomic, strong, readonly) NSString* UUID;
@property (nonatomic, strong, readonly) NSString* stringValue;
-(id)initWithCrashReport:(PLCrashReport*)crashReport;
@end
