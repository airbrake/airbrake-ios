
#import "ABAbstractTestCase.h"
#import "ABCrashReport.h"

@interface ABCrashReportTestCase : ABAbstractTestCase {
    ABCrashReport* testObject;
}
@end

@implementation ABCrashReportTestCase

-(void)setUp {
    testObject = [[ABCrashReport alloc] init];
}

-(void)testWhenUUIDIsRequestedThenItIsReturnedAndThatIsUnique {
    NSRegularExpression* re = [[NSRegularExpression alloc] initWithPattern:@"[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}" options:NSRegularExpressionCaseInsensitive error:nil];
    
    ABCrashReport* testObject1 = [[ABCrashReport alloc] init];
    NSString* uuid1 = testObject1.UUID;
    GHAssertTrue([re numberOfMatchesInString:uuid1 options:0 range:NSMakeRange(0, uuid1.length)] > 0, nil);

    GHAssertNotNil(uuid1, nil);
    GHAssertEqualObjects(uuid1, testObject1.UUID, nil);
    
    ABCrashReport* testObject2 = [[ABCrashReport alloc] init];
    NSString* uuid2 = testObject2.UUID;
    GHAssertTrue([re numberOfMatchesInString:uuid2 options:0 range:NSMakeRange(0, uuid2.length)] > 0, nil);
    
    GHAssertNotNil(uuid2, nil);
    GHAssertNotEqualObjects(uuid1, uuid2, nil);
}

@end
