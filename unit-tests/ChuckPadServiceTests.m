//
//  ChuckPadServiceTests.m
//  hello-chuckpad
//  Created by Mark Cerqueira on 12/16/16.
//

#import "ChuckPadBaseTest.h"

@interface ChuckPadServiceTests : ChuckPadBaseTest

@end

@implementation ChuckPadServiceTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testDuplicateRandomValue {
    [self generateLocalUserAndCreate];
    
    NSString *randomString = [self randomStringWithLength:12];
    
    // This should succeed because it's the first time we are using the random value.
    [self callSecretStaticMethod:@"overrideRandomValueForNextRequest:" class:@"ChuckPadSocial" argument:randomString];
    [self generatePatchAndUpload:YES];
    
    // This should fail because we are re-using the random value we used in the above request.
    [self callSecretStaticMethod:@"overrideRandomValueForNextRequest:" class:@"ChuckPadSocial" argument:randomString];
    [self generatePatchAndUpload:NO];
    
    // This should succeed because we are now using a newly generated random value. Note the random value override is cleared
    // after it is used so this will use a properly generated (and new) random value.
    [self generatePatchAndUpload:YES];
    
    [self cleanUpFollowingTest];
}

- (void)testIncorrectDigestValue {
    [self generateLocalUserAndCreate];
    
    // This should fail because we are setting an incorrect value for the digest.
    [self callSecretStaticMethod:@"overrideDigestValueForNextRequest:" class:@"ChuckPadSocial" argument:@"bad-digest-value-1"];
    [self generatePatchAndUpload:NO];
    
    // Now we use a proper digest and this should succeed.
    [self generatePatchAndUpload:YES];
    
    [self cleanUpFollowingTest];
}

@end
