#import "ABAbstractTestCase.h"
#import "ABCurrentContext.h"

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
    GHAssertNotNil(UUID, nil);
}

@end
