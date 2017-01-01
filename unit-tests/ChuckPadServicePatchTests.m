//
//  ChuckPadServicePatchTests.m
//  hello-chuckpad
//  Created by Mark Cerqueira on 7/25/16.
//

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

- (void)testSinglePatchUpload {
    [self generateLocalUserAndCreate];
    
    [self generatePatchAndUpload:YES];
    
    [self cleanUpFollowingTest];
}

- (void)testReportAbuse {
    ChuckPadUser *patchOwner = [self generateLocalUserAndCreate];
    
    ChuckPadPatch *localPatch = [self generatePatchAndUpload:YES];
    patchOwner.totalPatches++;
    
    // A user cannot report their own patches so log out and create a new user
    [[ChuckPadSocial sharedInstance] localLogOut];
    [self generateLocalUserAndCreate];

    // Report a patch as abusive
    XCTestExpectation *expectation = [self expectationWithDescription:@"reportAbuse timed out"];
    [[ChuckPadSocial sharedInstance] reportAbuse:localPatch.lastServerPatch isAbuse:YES callback:^(BOOL succeeded, NSError *error) {
        XCTAssertTrue(succeeded);
        
        localPatch.abuseReportCount++;
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    // Check patch metadata to ensure abuse count has been incremented
    expectation = [self expectationWithDescription:@"getPatchInfo timed out"];
    [[ChuckPadSocial sharedInstance] getPatchInfo:localPatch.lastServerPatch.guid callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertTrue(succeeded);
        
        [self assertPatch:patch localPatch:localPatch isConsistentForUser:patchOwner];
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    // Now unreport the patch as abusive
    expectation = [self expectationWithDescription:@"reportAbuse timed out"];
    [[ChuckPadSocial sharedInstance] reportAbuse:localPatch.lastServerPatch isAbuse:NO callback:^(BOOL succeeded, NSError *error) {
        XCTAssertTrue(succeeded);
        
        localPatch.abuseReportCount--;
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    // And now verify the patch metadata has been updated to have 0 abuse reports
    expectation = [self expectationWithDescription:@"getPatchInfo timed out"];
    [[ChuckPadSocial sharedInstance] getPatchInfo:localPatch.lastServerPatch.guid callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertTrue(succeeded);
        
        [self assertPatch:patch localPatch:localPatch isConsistentForUser:patchOwner];
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    [self cleanUpFollowingTest];
}

- (void)testMultipleReportAbuse {
    ChuckPadUser *patchOwner = [self generateLocalUserAndCreate];
    
    ChuckPadPatch *localPatch = [self generatePatchAndUpload:YES];
    
    NSMutableArray *reportingUsers = [NSMutableArray new];
    
    NSInteger numberReportingUsers = 10;
    
    // Generate a bunch of users
    for (int i = 0; i < numberReportingUsers; i++) {
        [reportingUsers addObject:[self generateLocalUserAndCreate]];
    }
    
    for (ChuckPadUser *user in reportingUsers) {
        [[ChuckPadSocial sharedInstance] localLogOut];
        
        [self logInWithLocalUser:user];
        
        // Report the patch as abusive
        XCTestExpectation *expectation = [self expectationWithDescription:@"reportAbuse timed out"];
        [[ChuckPadSocial sharedInstance] reportAbuse:localPatch.lastServerPatch isAbuse:YES callback:^(BOOL succeeded, NSError *error) {
            XCTAssertTrue(succeeded);
            
            localPatch.abuseReportCount++;
            
            [expectation fulfill];
        }];
        [self waitForExpectations];
    }
    
    // Check patch metadata to make sure abuse report count is correct
    XCTestExpectation *expectation = [self expectationWithDescription:@"getPatchInfo timed out"];
    [[ChuckPadSocial sharedInstance] getPatchInfo:localPatch.lastServerPatch.guid callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertTrue(succeeded);
        
        [self assertPatch:patch localPatch:localPatch isConsistentForUser:patchOwner];
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    [self cleanUpFollowingTest];
}

- (void)testReportAbuseOnDeletedPatch {
    [self generateLocalUserAndCreate];
    
    ChuckPadPatch *patch = [self generatePatchAndUpload:YES];
    
    // Delete the patch we just uploaded
    [self deletePatch:patch];
    
    // Switch to a new user
    [[ChuckPadSocial sharedInstance] localLogOut];
    [self generateLocalUserAndCreate];
    
    // Report a patch as abusive. We expect this to fail because we deleted the patch right after uploading it.
    XCTestExpectation *expectation = [self expectationWithDescription:@"reportAbuse timed out"];
    [[ChuckPadSocial sharedInstance] reportAbuse:patch.lastServerPatch isAbuse:YES callback:^(BOOL succeeded, NSError *error) {
        XCTAssertFalse(succeeded);
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
}

- (void)testReportAbuseOnOwnPatchNotAllowed {
    [self generateLocalUserAndCreate];
    
    ChuckPadPatch *localPatch = [self generatePatchAndUpload:YES];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"reportAbuse timed out"];
    [[ChuckPadSocial sharedInstance] reportAbuse:localPatch.lastServerPatch isAbuse:YES callback:^(BOOL succeeded, NSError *error) {
        XCTAssertFalse(succeeded);
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    [self cleanUpFollowingTest];
}

- (void)testPatchUploadAndUpdate {
    ChuckPadUser *user = [self generateLocalUserAndCreate];
    
    // Upload a new patch
    ChuckPadPatch *localPatch = [ChuckPadPatch generatePatch:@"demo0.ck"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"uploadPatch timed out"];
    [[ChuckPadSocial sharedInstance] uploadPatch:localPatch.name description:localPatch.patchDescription parent:nil patchData:localPatch.fileData extraMetaData:nil callback:^(BOOL succeeded, Patch *patch, NSError *error) {
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
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    // We uploaded a patch in above. If we download the file data for that patch it should match exactly the data in
    // that uploaded patch.
    expectation = [self expectationWithDescription:@"downloadPatchResource timed out"];
    [[ChuckPadSocial sharedInstance] downloadPatchResource:localPatch.lastServerPatch callback:^(NSData *resourceData, NSError *error) {
        // We downloaded the patch so we expect subsequent calls to get the patch to have an updated download count
        localPatch.downloadCount++;
        
        XCTAssert([localPatch.fileData isEqualToData:resourceData]);
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    // Test the update patch API. We will first mutate our local patch and then call updatePatch passing in
    // parameters from our updated localPatch and then verify the response against our localPatch.
    localPatch.isHidden = YES;
    [localPatch setNewNameAndDescription];
    
    expectation = [self expectationWithDescription:@"updatePatch timed out"];
    [[ChuckPadSocial sharedInstance] updatePatch:localPatch.lastServerPatch hidden:@(localPatch.isHidden) name:localPatch.name description:localPatch.patchDescription patchData:nil extraMetaData:nil callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertTrue(succeeded);
        
        [self assertPatch:patch localPatch:localPatch isConsistentForUser:user];
        
        XCTAssertTrue([[NSDate stringFromDate:[NSDate date] withFormat:@"h:mm a"] isEqualToString:[patch getTimeLastUpdatedWithPrefix:NO]]);
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    // Getting patches for this user would normally return 0 patches because above we set the only uploaded patch this
    // user has to hidden. But since we are the owning user, we should get back 1 patch because patch owners can see
    // patches even if they are hidden.
    expectation = [self expectationWithDescription:@"getPatchesForUserId timed out"];
    [[ChuckPadSocial sharedInstance] getPatchesForUserId:user.userId callback:^(NSArray *patchesArray, NSError *error) {
        XCTAssertTrue(patchesArray != nil);
        XCTAssertTrue([patchesArray count] == user.totalPatches);
        
        [self assertPatch:patchesArray[0] localPatch:localPatch isConsistentForUser:user];
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
  
    [self cleanUpFollowingTest];
}

- (void)testMultiplePatchUpload {
    [self generateLocalUserAndCreate];
    [self uploadMultiplePatches:[ChuckPadPatch numberOfChuckFilesInSamplesDirectory]];
    [self cleanUpFollowingTest];
}

- (void)testAllowEmptyNameAndDescription {
    [self generateLocalUserAndCreate];
    
    ChuckPadPatch *patch = [ChuckPadPatch generatePatch];
    patch.name = @"";
    patch.patchDescription = @"";
    
    [self uploadPatch:patch successExpected:YES callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertTrue([patch.name isEqualToString:@""]);
        XCTAssertTrue([patch.patchDescription isEqualToString:@""]);
    }];
    
    // If we pass nil for name and description the service should set them to blank strings for us
    ChuckPadPatch *patch2 = [ChuckPadPatch generatePatch];
    patch2.name = nil;
    patch2.patchDescription = nil;
    
    [self uploadPatch:patch2 successExpected:YES callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertTrue([patch.name isEqualToString:@""]);
        XCTAssertTrue([patch.patchDescription isEqualToString:@""]);
    }];
    
    [self cleanUpFollowingTest];
}

- (void)testUploadingVisibleAndHiddenPatch {
    [self generateLocalUserAndCreate];

    ChuckPadPatch *patch = [ChuckPadPatch generatePatch];
    patch.isHidden = YES;
    [self uploadPatch:patch successExpected:YES];
    
    ChuckPadPatch *patch2 = [ChuckPadPatch generatePatch];
    patch2.isHidden = NO;
    [self uploadPatch:patch2 successExpected:YES];
    
    [self cleanUpFollowingTest];
}

- (void)testPatchDataRequiredWithNil {
    [self generateLocalUserAndCreate];

    ChuckPadPatch *patch = [ChuckPadPatch generatePatch];
    patch.fileData = nil;
    
    [self uploadPatch:patch successExpected:NO];
    
    [self cleanUpFollowingTest];
}

- (void)testPatchDataRequiredWithZeroLengthData {
    [self generateLocalUserAndCreate];
    
    ChuckPadPatch *patch = [ChuckPadPatch generatePatch];
    patch.fileData = [[NSData alloc] init];
    
    [self uploadPatch:patch successExpected:NO];
    
    [self cleanUpFollowingTest];
}

- (void)testUpdatePatchWithZeroLengthData {
    [self generateLocalUserAndCreate];
    
    ChuckPadPatch *localPatch = [self generatePatchAndUpload:YES];
    
    localPatch.fileData = [[NSData alloc] init];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"updatePatch timed out"];
    [[ChuckPadSocial sharedInstance] updatePatch:localPatch.lastServerPatch hidden:nil name:nil description:nil patchData:localPatch.fileData extraMetaData:nil callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertFalse(succeeded);
        [expectation fulfill];
    }];
    [self waitForExpectations];
}

- (void)testExtraDataTooLarge {
    [self generateLocalUserAndCreate];
    
    ChuckPadPatch *patch = [ChuckPadPatch generatePatch];
    [patch addExtraData:@"chuck-samples-xl" filename:@"demo10kb.ck"];
    
    [self uploadPatch:patch successExpected:NO];
    
    [self cleanUpFollowingTest];
}

- (void)testDataAndExtraDataTooLarge {
    [self generateLocalUserAndCreate];
    
    ChuckPadPatch *patch = [ChuckPadPatch generatePatch:@"chuck-samples-xl" filename:@"demo10kb.ck"];
    [patch addExtraData:@"chuck-samples-xl" filename:@"demo10kb.ck"];
    
    [self uploadPatch:patch successExpected:NO];
    
    [self cleanUpFollowingTest];
}

- (void)testUploadingOnlyExtraData {
    [self generateLocalUserAndCreate];
    
    ChuckPadPatch *patch = [ChuckPadPatch generatePatch];
    patch.fileData = nil;
    [patch addExtraData:@"demo01.ck"];
    
    [self uploadPatch:patch successExpected:NO];
    
    [self cleanUpFollowingTest];
}

- (void)testUpdatingDeletedPatch {
    [self generateLocalUserAndCreate];

    ChuckPadPatch *localPatch = [self generatePatchAndUpload:YES];
    
    [self deletePatch:localPatch];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"updatePatch timed out"];
    [[ChuckPadSocial sharedInstance] updatePatch:localPatch.lastServerPatch hidden:@(YES) name:@"n" description:@"d" patchData:nil extraMetaData:nil callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertFalse(succeeded);
        [expectation fulfill];
    }];
    [self waitForExpectations];

    [self cleanUpFollowingTest];
}

- (void)testParentPatch {
    ChuckPadUser *parent = [self generateLocalUserAndCreate];
    ChuckPadPatch *parentPatch = [self generatePatchAndUpload:YES];
    
    [[ChuckPadSocial sharedInstance] localLogOut];
    
    ChuckPadUser *child = [self generateLocalUserAndCreate];
    ChuckPadPatch *childPatch = [ChuckPadPatch generatePatch];
    childPatch.hasParent = YES;
    childPatch.parentGUID = parentPatch.lastServerPatch.guid;
    
    [self uploadPatch:childPatch successExpected:YES callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertTrue([patch.parentGUID isEqualToString:parentPatch.lastServerPatch.guid]);
    }];
    
    [[ChuckPadSocial sharedInstance] localLogOut];

    [self logInWithLocalUser:parent];
    
    // Set the parent patch to hidden
    XCTestExpectation *expectation = [self expectationWithDescription:@"updatePatch timed out"];
    [[ChuckPadSocial sharedInstance] updatePatch:parentPatch.lastServerPatch hidden:@(YES) name:nil description:nil patchData:nil extraMetaData:nil callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertTrue(succeeded);
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    [[ChuckPadSocial sharedInstance] localLogOut];
    
    [self logInWithLocalUser:child];
    
    // This patch should now say it does not have a parent because the owner of the parent set it to hidden above.
    expectation = [self expectationWithDescription:@"updatePatch timed out"];
    [[ChuckPadSocial sharedInstance] getPatchInfo:childPatch.lastServerPatch.guid callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertTrue(succeeded);
        XCTAssertFalse([patch hasParentPatch]);
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    [self cleanUpFollowingTest];
}

- (void)testUploadingDataAndExtraData {
    [self generateLocalUserAndCreate];
    
    ChuckPadPatch *localPatch = [ChuckPadPatch generatePatch:@"demo0.ck"];
    [localPatch addExtraData:@"adsr.ck"];
    
    [self uploadPatch:localPatch successExpected:YES callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertTrue([patch hasExtraResource]);
    }];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"downloadPatchResource timed out"];
    [[ChuckPadSocial sharedInstance] downloadPatchResource:localPatch.lastServerPatch callback:^(NSData *resourceData, NSError *error) {
        XCTAssertTrue([resourceData isEqualToData:localPatch.fileData]);
        [expectation fulfill];
    }];
    [self waitForExpectations];

    expectation = [self expectationWithDescription:@"downloadPatchExtraData timed out"];
    [[ChuckPadSocial sharedInstance] downloadPatchExtraData:localPatch.lastServerPatch callback:^(NSData *resourceData, NSError *error) {
        XCTAssertTrue([resourceData isEqualToData:localPatch.extraData]);
        [expectation fulfill];
    }];
    [self waitForExpectations];

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
    [[ChuckPadSocial sharedInstance] uploadPatch:largePatch.name description:largePatch.patchDescription parent:nil patchData:largePatch.fileData extraMetaData:nil callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertFalse(succeeded);
        
        [self assertError:error descriptionContainsStrings:@[[NSString stringWithFormat:@"%ld", (long)MAX_SIZE_FOR_DATA], @"KB"]];
        
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
    [[ChuckPadSocial sharedInstance] updatePatch:patch.lastServerPatch hidden:@(NO) name:@"Name" description:nil patchData:nil extraMetaData:nil callback:^(BOOL succeeded, Patch *patch, NSError *error) {
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
    [[ChuckPadSocial sharedInstance] updatePatch:patch.lastServerPatch hidden:@(NO) name:@"Name" description:nil patchData:nil extraMetaData:nil callback:^(BOOL succeeded, Patch *patch, NSError *error) {
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

- (void)testDownloadDataCallsWithBadGUID {
    Patch *patch = [[Patch alloc] init];
    
    // Set a random GUID for resource and extra resource URLs. Below we expect these downloads to fail.
    NSString *randomGUID = [self randomStringWithLength:20];
    patch.resourceUrl = [NSString stringWithFormat:@"/patch/download/%@", randomGUID];
    patch.extraResourceUrl = [NSString stringWithFormat:@"/patch/download/extra/%@", randomGUID];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"downloadPatchResource timed out"];
    [[ChuckPadSocial sharedInstance] downloadPatchResource:patch callback:^(NSData *resourceData, NSError *error) {
        XCTAssertTrue(resourceData == nil);
        XCTAssertTrue(error != nil);
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    expectation = [self expectationWithDescription:@"downloadPatchExtraData timed out"];
    [[ChuckPadSocial sharedInstance] downloadPatchExtraData:patch callback:^(NSData *resourceData, NSError *error) {
        XCTAssertTrue(resourceData == nil);
        XCTAssertTrue(error != nil);
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    [self cleanUpFollowingTest];
}

@end
