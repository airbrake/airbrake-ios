#import "ABAbstractTestCase.h"
#import "ABCurrentContext.h"
#import "ABConstants.h"

@interface ABCurrentContextTestCase : ABAbstractTestCase {
    ABCurrentContext* testObject;
}
@end

@implementation ABCurrentContextTestCase

-(void)setUp {
    testObject = [[ABCurrentContext alloc] init];
}

-(void)testWhenExecutableUUIDIsRequestedThenItIsReturned {
    NSRegularExpression* re = [[NSRegularExpression alloc] initWithPattern:@"[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}" options:NSRegularExpressionCaseInsensitive error:nil];
    NSString* UUID = testObject.executableUUID;
    GHAssertTrue([re numberOfMatchesInString:UUID options:0 range:NSMakeRange(0, UUID.length)] > 0, nil);
}

-(void)testWhenOSVersionIsRequestedThenItIsReturned {
    GHAssertTrue(testObject.operatingSystem.length > 0, nil);
}

-(void)testWhenPhysicalMemoryIsRequestedThenItIsGreaterThanZero {
    GHAssertTrue(testObject.physicalMemoryInBytes > 0, nil);
}

-(void)testWhenBuildIsRequestedThenItsLengthIsGreaterThanZero {
    GHAssertEqualObjects(testObject.applicationBuild, @"2", nil);
}

-(void)testWhenVersionIsRequestedThenItsLengthIsGreaterThanZero {
    GHAssertEqualObjects(testObject.applicationVersion, @"1.0", nil);
}

-(void)testWhenDebugOrReleaseIsRequestedThenDebugOrReleaseIsReported {
#ifdef DEBUG
    GHAssertEqualObjects(@"Debug",testObject.debugOrRelease, nil);
#else
    GHAssertEqualObjects(@"Release",testObject.debugOrRelease, nil);
#endif
}

-(void)testWhenClientAPIVersionIsRequestedThenItIsReturned {
    GHAssertEqualObjects(testObject.clientAPIVersion, ABClientAPIVersion, nil);
}

@end
