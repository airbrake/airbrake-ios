
#import "ABAbstractTestCase.h"
#import "ABCrashReport.h"
#import <CrashReporter/CrashReporter.h>

@interface ABCrashReportTestCase : ABAbstractTestCase {
    ABCrashReport* testObject;
    PLCrashReport* crashReport;
}
@end

@implementation ABCrashReportTestCase

-(void)setUp {
    NSError* error = nil;
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"fuzz_report" ofType:@"plcrash"];
    NSData *crashData = [NSData dataWithContentsOfFile:filePath];
    crashReport = [[PLCrashReport alloc] initWithData:crashData error:&error];
    testObject = [[ABCrashReport alloc] initWithCrashReport:crashReport];
    GHAssertNotNil(crashData, nil);
    GHAssertNil(error, nil);
}

-(void)testWhenUUIDIsRequestedThenItIsReturnedAndThatIsUnique {
    NSRegularExpression* re = [[NSRegularExpression alloc] initWithPattern:@"[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}" options:NSRegularExpressionCaseInsensitive error:nil];
    
    ABCrashReport* testObject1 = [[ABCrashReport alloc] initWithCrashReport:crashReport];
    NSString* uuid1 = testObject1.UUID;
    GHAssertTrue([re numberOfMatchesInString:uuid1 options:0 range:NSMakeRange(0, uuid1.length)] > 0, nil);

    GHAssertNotNil(uuid1, nil);
    GHAssertEqualObjects(uuid1, testObject1.UUID, nil);
    
    ABCrashReport* testObject2 = [[ABCrashReport alloc] initWithCrashReport:crashReport];
    NSString* uuid2 = testObject2.UUID;
    GHAssertTrue([re numberOfMatchesInString:uuid2 options:0 range:NSMakeRange(0, uuid2.length)] > 0, nil);
    
    GHAssertNotNil(uuid2, nil);
    GHAssertNotEqualObjects(uuid1, uuid2, nil);
}

-(void)testWhenCrashReportIsRequestedAsStringThenItIsReturned {
    GHAssertNotNil(testObject.stringValue,nil);
}

@end
