//
//  ChuckPadSeedTests.m
//  hello-chuckpad
//
//  Created by Cerqueira, Mark Morais on 5/17/17.
//
//  A "test" that creates a user and uploads all documentation patches to the production
//  ChuckPad service.

#import "ChuckPadBaseTest.h"

// These must be non-nil for testSeedProductionServerWithPatches to succeed!
NSString *const SEED_USERNAME = nil;
NSString *const SEED_PASSWORD = nil;
NSString *const SEED_EMAIL = nil;

@interface ChuckPadSeedTests : ChuckPadBaseTest

@end

@implementation ChuckPadSeedTests

- (void)testSeedProductionServerWithPatches {
    if (SEED_USERNAME == nil || SEED_PASSWORD == nil || SEED_EMAIL == nil) {
        return;
    }
    
    // Point to production
    [self callSecretStaticMethod:@"resetSharedInstanceAndBoostrap" class:@"ChuckPadSocial"];
    [ChuckPadSocial bootstrapForPatchType:MiniAudicle];
    [[ChuckPadSocial sharedInstance] setEnvironment:Production];
    
    // Log out
    [[ChuckPadSocial sharedInstance] localLogOut];
    
    // Create our user
    ChuckPadUser *user = [[ChuckPadUser alloc] init];
    user.username = SEED_USERNAME;
    user.password = SEED_PASSWORD;
    user.email = SEED_EMAIL;
    user.totalPatches = 0;

    [self createUserFromLocalUser:user];
    
    // Upload all documentation patches
    for (int i = 0; i < [ChuckPadPatch numberOfChuckFilesInSamplesDirectory]; i++) {
        ChuckPadPatch *patch = [ChuckPadPatch generatePatch];
        patch.patchDescription = @"";
        [self uploadPatch:patch successExpected:YES];
    }
        
    [self cleanUpFollowingTest];
}

@end
