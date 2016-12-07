//
//  ChuckPadServicePatchTests.m
//  hello-chuckpad
//  Created by Mark Cerqueira on 7/25/16.
//
//  NOTE: These tests run against the chuckpad-social server running locally on your machine. To run the chuckpad-social
//  server on your computer please see: https://github.com/markcerqueira/chuckpad-social

#import "ChuckPadBaseTest.h"

@interface ChuckPadServicePatchTests : ChuckPadBaseTest

@end

@implementation ChuckPadServicePatchTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

// General exercise of the Patch API
- (void)testPatchAPI {
    ChuckPadUser *user = [ChuckPadUser generateUser];
    
    // 1 - Create a new user so we can upload patches
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"createUser timed out (1)"];
    [[ChuckPadSocial sharedInstance] createUser:user.username email:user.email password:user.password callback:^(BOOL succeeded, NSError *error) {
        [self doPostAuthAssertChecks:user];
        [expectation1 fulfill];
    }];
    [self waitForExpectations];
    
    // 2 - Upload a new patch
    ChuckPadPatch *localPatch = [ChuckPadPatch generatePatch:@"demo0.ck"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"uploadPatch timed out (2)"];
    [[ChuckPadSocial sharedInstance] uploadPatch:localPatch.name description:localPatch.patchDescription parent:-1 filename:localPatch.filename fileData:localPatch.fileData callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        user.totalPatches++;
        
        XCTAssertTrue(succeeded);
        
        // Verify times are accurate on patch created
        NSString *now = [NSDate stringFromDate:[NSDate date] withFormat:@"h:mm a"];
        NSString *timeCreated = [patch getTimeCreatedWithPrefix:NO];
        NSString *timeUpdated = [patch getTimeLastUpdatedWithPrefix:NO];
        XCTAssertTrue([now isEqualToString:timeCreated]);
        XCTAssertTrue([now isEqualToString:timeUpdated]);
        
        // Assert our username and owner username of patch match and once we confirm that is the case, update our local
        // user object with its user id.
        XCTAssertTrue([patch.creatorUsername isEqualToString:user.username]);
        [user updateUserId:patch.creatorId];
        
        [self assertPatch:patch localPatch:localPatch isConsistentForUser:user];
        
        [expectation2 fulfill];
    }];
    [self waitForExpectations];
    
    
    // 3 - Test get my patches API. This should return one patch for the new user we created in step 1 for which we
    // uploaded a sigle patch in step 2.
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"getMyPatches timed out (3)"];
    [[ChuckPadSocial sharedInstance] getMyPatches:^(NSArray *patchesArray, NSError *error) {
        XCTAssertTrue(patchesArray != nil);
        XCTAssertTrue([patchesArray count] == user.totalPatches);
        
        [self assertPatch:patchesArray[0] localPatch:localPatch isConsistentForUser:user];
        
        [expectation3 fulfill];
    }];
    [self waitForExpectations];
    
    // 4 - We uploaded a patch in step 2. If we download the file data for that patch it should match exactly the
    // data we uploaded during step 2.
    XCTestExpectation *expectation4 = [self expectationWithDescription:@"downloadPatchResource timed out (4)"];
    [[ChuckPadSocial sharedInstance] downloadPatchResource:localPatch.lastServerPatch callback:^(NSData *patchData, NSError *error) {
        // We downloaded the patch so we expect subsequent calls to get the patch to have an updated download count
        localPatch.downloadCount++;
        
        XCTAssert([localPatch.fileData isEqualToData:patchData]);
        [expectation4 fulfill];
    }];
    [self waitForExpectations];
    
    // 5 - Test the update patch API. We will first mutate our local patch and then call updatePatch passing in
    // parameters from our updated localPatch and then verify the response against our localPatch.
    localPatch.isHidden = YES;
    [localPatch setNewNameAndDescription];
    
    XCTestExpectation *expectation5 = [self expectationWithDescription:@"updatePatch timed out (5)"];
    [[ChuckPadSocial sharedInstance] updatePatch:localPatch.lastServerPatch hidden:[NSNumber numberWithBool:localPatch.isHidden] name:localPatch.name description:localPatch.patchDescription filename:nil fileData:nil callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertTrue(succeeded);
        
        [self assertPatch:patch localPatch:localPatch isConsistentForUser:user];
        
        XCTAssertTrue([[NSDate stringFromDate:[NSDate date] withFormat:@"h:mm a"] isEqualToString:[patch getTimeLastUpdatedWithPrefix:NO]]);
        
        [expectation5 fulfill];
    }];
    [self waitForExpectations];
    
    // 6 - Getting patches for this user would normally return 0 patches because in step 5 we set the only uploaded
    // patch this user has to hidden. But since we are the owning user, we should get back 1 patch because patch owners
    // can see patches even if they are hidden.
    XCTestExpectation *expectation6 = [self expectationWithDescription:@"getPatchesForUserId timed out (6)"];
    [[ChuckPadSocial sharedInstance] getPatchesForUserId:[user.userId integerValue] callback:^(NSArray *patchesArray, NSError *error) {
        XCTAssertTrue(patchesArray != nil);
        XCTAssertTrue([patchesArray count] == user.totalPatches);
        
        [self assertPatch:patchesArray[0] localPatch:localPatch isConsistentForUser:user];
        
        [expectation6 fulfill];
    }];
    [self waitForExpectations];
    
    // 7 - Get recent patches API.
    XCTestExpectation *expectation7 = [self expectationWithDescription:@"getRecentPatches timed out (7)"];
    [[ChuckPadSocial sharedInstance] getRecentPatches:^(NSArray *patchesArray, NSError *error) {
        XCTAssertTrue(patchesArray != nil);
        
        // If the environment was wiped clean recently we will have 0 patches returned by this API.
        XCTAssertTrue([patchesArray count] >= 0);
        
        [expectation7 fulfill];
    }];
    [self waitForExpectations];
    
    // 8 - Report a patch as abusive
    XCTestExpectation *expectation8 = [self expectationWithDescription:@"reportAbuse timed out (8)"];
    [[ChuckPadSocial sharedInstance] reportAbuse:localPatch.lastServerPatch isAbuse:YES callback:^(BOOL succeeded, NSError *error) {
        XCTAssertTrue(succeeded);
        
        localPatch.abuseReportCount++;
        
        [expectation8 fulfill];
    }];
    [self waitForExpectations];
    
    // 9 - Check patch metadata to ensure abuse count has been incremented
    XCTestExpectation *expectation9 = [self expectationWithDescription:@"getPatchInfo timed out (9)"];
    [[ChuckPadSocial sharedInstance] getPatchInfo:localPatch.lastServerPatch.patchId callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertTrue(succeeded);
        
        [self assertPatch:patch localPatch:localPatch isConsistentForUser:user];
        
        [expectation9 fulfill];
    }];
    
    // 10 - Now unreport the patch as abusive
    XCTestExpectation *expectation10 = [self expectationWithDescription:@"reportAbuse timed out (10)"];
    [[ChuckPadSocial sharedInstance] reportAbuse:localPatch.lastServerPatch isAbuse:NO callback:^(BOOL succeeded, NSError *error) {
        XCTAssertTrue(succeeded);
        
        localPatch.abuseReportCount--;
        
        [expectation10 fulfill];
    }];
    [self waitForExpectations];
    
    // 11 - And now verify the patch metadata has been updated to have 0 abuse reports
    XCTestExpectation *expectation11 = [self expectationWithDescription:@"getPatchInfo timed out (11)"];
    [[ChuckPadSocial sharedInstance] getPatchInfo:localPatch.lastServerPatch.patchId callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertTrue(succeeded);
        
        [self assertPatch:patch localPatch:localPatch isConsistentForUser:user];
        
        [expectation11 fulfill];
    }];
    [self waitForExpectations];
    
    // 12 - Delete the patch we uploaded in step 2.
    XCTestExpectation *expectation12 = [self expectationWithDescription:@"deletePatch timed out (12)"];
    [[ChuckPadSocial sharedInstance] deletePatch:localPatch.lastServerPatch callback:^(BOOL succeeded, NSError *error) {
        XCTAssertTrue(succeeded);
        
        // We deleted a patch so decrease our local count of our total patch count
        user.totalPatches--;
        
        // Assert our patch count is correct
        [[ChuckPadSocial sharedInstance] getMyPatches:^(NSArray *patchesArray, NSError *error) {
            XCTAssertTrue(patchesArray != nil);
            XCTAssertTrue([patchesArray count] == user.totalPatches);
            
            [expectation12 fulfill];
        }];
    }];
    [self waitForExpectations];
    
    [self cleanUpFollowingTest];
}

- (void)testMultiplePatchUpload {
    [self generateLocalUserAndCreate];
    [self uploadMultiplePatches:[ChuckPadPatch numberOfChuckFilesInSamplesDirectory]];
    [self cleanUpFollowingTest];
}

- (void)testSamePatchDataUploadDisallowed {
    [self generateLocalUserAndCreate];
    
    for (int i = 0; i < 2; i++) {
        // The call should only succeed the first time. Any subsequent uploadPatch requests with the same patch data should fail.
        [self generatePatchAndUpload:@"demo0.ck" successExpected:(i == 0)];
    }
    
    [self cleanUpFollowingTest];
}

- (void)testSamePatchDataUploadForDifferentUsersAllowed {
    for (int i = 0; i < 5; i++) {
        [self generateLocalUserAndCreate];
        
        // This should always succeed because we are uploading it each time as a different user.
        [self generatePatchAndUpload:@"demo0.ck" successExpected:YES];
        
        // Log out so we can create a new user on the next iteration.
        [[ChuckPadSocial sharedInstance] localLogOut];
    }
    
    [self cleanUpFollowingTest];
}

- (void)testSamePatchAllowedAcrossDifferentPatchTypes {
    [self generateLocalUserAndCreate];
    
    // Upload demo0.ck as MiniAudicle patch
    [self resetChuckPadSocialForPatchType:MiniAudicle];
    [self generatePatchAndUpload:@"demo0.ck" successExpected:YES];
    
    // Switch to Auraglyph and upload the same patch
    [self resetChuckPadSocialForPatchType:Auraglyph];
    [self generatePatchAndUpload:@"demo0.ck" successExpected:YES];
    
    // Switch back to MiniAudicle and upload the same patch (this should fail now)
    [self resetChuckPadSocialForPatchType:MiniAudicle];
    [self generatePatchAndUpload:@"demo0.ck" successExpected:NO];
    
    [self cleanUpFollowingTest];
}

- (void)testPatchTypeSeparation {
    [self generateLocalUserAndCreate];
    
    // We are currently configured for MiniAudicle patches
    NSInteger miniAudiclePatchUploadCount = 5;
    [self uploadMultiplePatches:miniAudiclePatchUploadCount];
    
    // We uploaded 5 patches so we expect to get 5 patches
    XCTestExpectation *expectation = [self expectationWithDescription:@"getMyPatches timed out"];
    [[ChuckPadSocial sharedInstance] getMyPatches:^(NSArray *patchesArray, NSError *error) {
        XCTAssertTrue(patchesArray != nil);
        XCTAssertTrue([patchesArray count] == miniAudiclePatchUploadCount);
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    // Switch to Auraglyph and upload patches
    [self resetChuckPadSocialForPatchType:Auraglyph];
    
    NSInteger auraglyphPatchUploadCount = 10;
    [self uploadMultiplePatches:auraglyphPatchUploadCount];
    
    // We uploaded 10 patches so we expect to get 10 patches
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"getMyPatches timed out"];
    [[ChuckPadSocial sharedInstance] getMyPatches:^(NSArray *patchesArray, NSError *error) {
        XCTAssertTrue(patchesArray != nil);
        XCTAssertTrue([patchesArray count] == auraglyphPatchUploadCount);
        [expectation2 fulfill];
    }];
    [self waitForExpectations];
    
    [self cleanUpFollowingTest];
    
    // This test is done so reset back to the original MiniAudicle patch type
    [self resetChuckPadSocialForPatchType:MiniAudicle];
}

- (void)testPatchSizeTooLarge {
    [self generateLocalUserAndCreate];
    
    ChuckPadPatch *largePatch = [ChuckPadPatch generatePatch:@"chuck-samples-xl" filename:@"demo10kb.ck"];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"uploadPatch timed out"];
    [[ChuckPadSocial sharedInstance] uploadPatch:largePatch.name description:largePatch.patchDescription parent:-1 filename:largePatch.filename fileData:largePatch.fileData callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertFalse(succeeded);
        
        [self assertError:error descriptionContainsString:@"10 KB"];
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    [self cleanUpFollowingTest];
}

- (void)testOnlyPatchCreatorCanUpdateAndDeletePatch {
    // Create a user, upload a patch, and log out.
    ChuckPadUser *patchOwner = [self generateLocalUserAndCreate];
    ChuckPadPatch *patch = [self generatePatchAndUpload:@"demo0.ck" successExpected:YES];
    [[ChuckPadSocial sharedInstance] localLogOut];

    // Create a new user.
    [self generateLocalUserAndCreate];
    
    // This new user should NOT be able to update patchOwner's patch.
    XCTestExpectation *expectation = [self expectationWithDescription:@"updatePatch timed out"];
    [[ChuckPadSocial sharedInstance] updatePatch:patch.lastServerPatch hidden:@(NO) name:@"Name" description:nil filename:nil fileData:nil callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertFalse(succeeded);
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    // This new user should NOT be able to delete patchOwner's patch.
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"deletePatch timed out"];
    [[ChuckPadSocial sharedInstance] deletePatch:patch.lastServerPatch callback:^(BOOL succeeded, NSError *error) {
        XCTAssertFalse(succeeded);
        [expectation2 fulfill];
    }];
    [self waitForExpectations];
    
    // Log out of our new user and log back in with patchOwner - the owner of the patch we uploaded earlier.
    [[ChuckPadSocial sharedInstance] localLogOut];
    
    [self logInWithLocalUser:patchOwner];
    
    // The patch owner should be able to update the patch...
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"updatePatch timed out"];
    [[ChuckPadSocial sharedInstance] updatePatch:patch.lastServerPatch hidden:@(NO) name:@"Name" description:nil filename:nil fileData:nil callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertTrue(succeeded);
        [expectation3 fulfill];
    }];
    [self waitForExpectations];
    
    // ...and delete it.
    XCTestExpectation *expectation4 = [self expectationWithDescription:@"deletePatch timed out"];
    [[ChuckPadSocial sharedInstance] deletePatch:patch.lastServerPatch callback:^(BOOL succeeded, NSError *error) {
        XCTAssertTrue(succeeded);
        [expectation4 fulfill];
    }];
    [self waitForExpectations];
    
    [self cleanUpFollowingTest];
}

@end
