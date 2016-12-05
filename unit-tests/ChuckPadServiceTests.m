//
//  ChuckPadServiceTests.m
//  hello-chuckpad
//  Created by Mark Cerqueira on 7/25/16.
//
//  NOTE: These tests run against the chuckpad-social server running locally on your machine. To run the chuckpad-social
//  server on your computer please see: https://github.com/markcerqueira/chuckpad-social

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

// General exercise of the User API calls
- (void)testUserAPI {
    // Generate a user with credentials locally. We will register a new user and log in using these credentials.
    ChuckPadUser *user = [ChuckPadUser generateUser];

    // 1 - Register a user
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"createUser timed out (1)"];
    [[ChuckPadSocial sharedInstance] createUser:user.username email:user.email password:user.password callback:^(BOOL succeeded, NSError *error) {
        // Log out in this check so we can test logging in next
        [self postAuthCallAssertsChecks:succeeded user:user logOut:YES];
        [expectation1 fulfill];
    }];
    [self waitForExpectations];
    
    // 2 - Log in as the user we created
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"logIn timed out (2)"];
    [[ChuckPadSocial sharedInstance] logIn:user.username password:user.password callback:^(BOOL succeeded, NSError *error) {
        // Do not log in because we are going to change the password in the next call
        [self postAuthCallAssertsChecks:succeeded user:user logOut:NO];
        [expectation2 fulfill];
    }];
    [self waitForExpectations];
    
    // 3 - Change the user's password
    NSString *newPassword = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"changePassword timed out (3)"];
    [[ChuckPadSocial sharedInstance] changePassword:newPassword callback:^(BOOL succeeded, NSError *error) {
        XCTAssertTrue(succeeded);
        
        // Update the local user
        user.password = newPassword;
        
        [self postAuthCallAssertsChecks:succeeded user:user logOut:YES];
        
        [expectation3 fulfill];
    }];
    [self waitForExpectations];

    // 4 - Log in again with the updated password and stay logged in after the test
    XCTestExpectation *expectation4 = [self expectationWithDescription:@"logIn timed out (4)"];
    [[ChuckPadSocial sharedInstance] logIn:user.username password:user.password callback:^(BOOL succeeded, NSError *error) {
        // Do not log in because we are going to change the password in the next call
        [self postAuthCallAssertsChecks:succeeded user:user logOut:NO];
        [expectation4 fulfill];
    }];
    [self waitForExpectations];
    
    // 5 - Log out using the logOut API which invalidates the auth token on the service
    XCTestExpectation *expectation5 = [self expectationWithDescription:@"logOut timed out (5)"];
    [[ChuckPadSocial sharedInstance] logOut:^(BOOL succeeded, NSError *error) {
        XCTAssertTrue(succeeded);
        XCTAssertTrue(error == nil);
        [self doPostLogOutAssertChecks];
        [expectation5 fulfill];
    }];
    [self waitForExpectations];
    
    [self cleanUpFollowingTest];
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

- (void)testAccountCreateWithTakenUsernameEmail {
    // Generate a user with credentials locally. We will register a new user and log in using these credentials.
    ChuckPadUser *user = [ChuckPadUser generateUser];
    
    // Register a user
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"createUser timed out"];
    [[ChuckPadSocial sharedInstance] createUser:user.username email:user.email password:user.password callback:^(BOOL succeeded, NSError *error) {
        // Log out in this check so we can test logging in next
        [self postAuthCallAssertsChecks:succeeded user:user logOut:YES];
        [expectation1 fulfill];
    }];
    [self waitForExpectations];
    
    // Try to create another user with the same email. Note we purposefully use user.email below instead of user2.email
    ChuckPadUser *user2 = [ChuckPadUser generateUser];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"createUser timed out"];
    [[ChuckPadSocial sharedInstance] createUser:user2.username email:user.email password:user2.password callback:^(BOOL succeeded, NSError *error) {
        XCTAssertFalse(succeeded);
        XCTAssertTrue(error != nil && [[error localizedDescription] containsString:@"email"]);
        XCTAssertFalse([[error localizedDescription] containsString:@"username"]);
        [expectation2 fulfill];
    }];
    [self waitForExpectations];
    
    // Try to create another user with the same username. Note we purposefully use user.username below instead of user2.username
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"createUser timed out"];
    [[ChuckPadSocial sharedInstance] createUser:user.username email:user2.email password:user2.password callback:^(BOOL succeeded, NSError *error) {
        XCTAssertFalse(succeeded);
        XCTAssertTrue(error != nil && [[error localizedDescription] containsString:@"username"]);
        XCTAssertFalse([[error localizedDescription] containsString:@"email"]);
        [expectation3 fulfill];
    }];
    [self waitForExpectations];
    
    // Try to create another user with the same username and email. The returned error should mention both email and username
    XCTestExpectation *expectation4 = [self expectationWithDescription:@"createUser timed out"];
    [[ChuckPadSocial sharedInstance] createUser:user.username email:user.email password:user2.password callback:^(BOOL succeeded, NSError *error) {
        XCTAssertFalse(succeeded);
        XCTAssertTrue(error != nil && [[error localizedDescription] containsString:@"username"]);
        XCTAssertTrue(error != nil && [[error localizedDescription] containsString:@"email"]);
        [expectation4 fulfill];
    }];
    [self waitForExpectations];
    
    [self cleanUpFollowingTest];
}

- (void)testForgotPassword {
    // Generate a user with credentials locally. We will register a new user and log in using these credentials.
    ChuckPadUser *user = [ChuckPadUser generateUser];
    
    // Register a user
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"createUser timed out"];
    [[ChuckPadSocial sharedInstance] createUser:user.username email:user.email password:user.password callback:^(BOOL succeeded, NSError *error) {
        // Log out in this check so we can test logging in next
        [self postAuthCallAssertsChecks:succeeded user:user logOut:YES];
        [expectation1 fulfill];
    }];
    [self waitForExpectations];
    
    // Hit the forgot password API for our user. Account should be found with either email or username so exercise the
    // API first using username and then email
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"forgotPassword timed out"];
    [[ChuckPadSocial sharedInstance] forgotPassword:user.username callback:^(BOOL succeeded, NSError *error) {
        XCTAssertTrue(succeeded);
        
        [[ChuckPadSocial sharedInstance] forgotPassword:user.email callback:^(BOOL succeeded, NSError *error) {
            XCTAssertTrue(succeeded);
            [expectation2 fulfill];
        }];
    }];
    [self waitForExpectations];
    
    // This is only a local user. It is not created on the service.
    ChuckPadUser *localUser = [ChuckPadUser generateUser];
    
    // Hit the forgot password API for a user that does not exist with both email and username.
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"forgotPassword timed out"];
    [[ChuckPadSocial sharedInstance] forgotPassword:localUser.username callback:^(BOOL succeeded, NSError *error) {
        XCTAssertFalse(succeeded);
        
        [[ChuckPadSocial sharedInstance] forgotPassword:localUser.email callback:^(BOOL succeeded, NSError *error) {
            XCTAssertFalse(succeeded);
            [expectation3 fulfill];
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
        [expectation fulfill];
    }];
    [self waitForExpectations];
}

- (void)testWeakPassword {
    // Generate a user with credentials locally and set the password to something weak
    ChuckPadUser *user = [ChuckPadUser generateUser];
    user.password = @"1234";

    // This createUser call should fail as the password is too weak
    XCTestExpectation *expectation = [self expectationWithDescription:@"createUser timed out"];
    [[ChuckPadSocial sharedInstance] createUser:user.username email:user.email password:user.password callback:^(BOOL succeeded, NSError *error) {
        XCTAssertFalse(succeeded);
        XCTAssertTrue([[error localizedDescription] containsString:@"password"]);
        XCTAssertTrue([[error localizedDescription] containsString:@"weak"]);
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    [self cleanUpFollowingTest];
}

- (void)testValidAndInvalidUsernames {
    // Note - we will append a random 5 character prefix to these in the for loop below to avoid hitting the case where
    // we are trying to create multiple users with the same username.
    NSDictionary *usernameValidityDictionary = @{@"super-long-username" : @NO, // Too long
                                                 @"~~$o$_/|\\" : @NO, // Invalid characters
                                                 @"abC-._.-567$" : @NO, // Almost valid except $ is invalid character
                                                 @"abC-._.-567" : @YES}; // Should be valid
    
    for (NSString *username in [usernameValidityDictionary allKeys]) {
        ChuckPadUser *user = [ChuckPadUser generateUser];
        
        user.username = [NSString stringWithFormat:@"%@%@", [self randomStringWithLength:5], username];

        BOOL shouldSucceed = [[usernameValidityDictionary objectForKey:username] boolValue];

        XCTestExpectation *expectation = [self expectationWithDescription:@"createUser timed out"];
        [[ChuckPadSocial sharedInstance] createUser:user.username email:user.email password:user.password callback:^(BOOL succeeded, NSError *error) {
            XCTAssertTrue(shouldSucceed == succeeded);
            
            // Need to do a localLogOut to clear credentials so we can log in again.
            [[ChuckPadSocial sharedInstance] localLogOut];
            
            [expectation fulfill];
        }];
        [self waitForExpectations];
    }
    
    [self cleanUpFollowingTest];
}

- (void)testUsernameCaseSensitivity {
    NSString *baseUsername = [self randomStringWithLength:20];
    NSArray *usernames = @[baseUsername, [baseUsername uppercaseString], [baseUsername lowercaseString]];
    
    for (int i = 0; i < [usernames count]; i++) {
        ChuckPadUser *user = [ChuckPadUser generateUser];
        user.username = [usernames objectAtIndex:i];
        
        XCTestExpectation *expectation = [self expectationWithDescription:@"createUser timed out"];
        [[ChuckPadSocial sharedInstance] createUser:user.username email:user.email password:user.password callback:^(BOOL succeeded, NSError *error) {
            // Only the first call should succeed because the rest are upper/lower case variations of the first username used
            XCTAssertTrue(succeeded == (i == 0));
            
            // The error message should only mention that the username is used, not the email.
            if (i != 0) {
                XCTAssertTrue([[error localizedDescription] containsString:@"username"]);
                XCTAssertFalse([[error localizedDescription] containsString:@"email"]);
            }
            
            // Need to do a localLogOut to clear credentials so we can log in again.
            [[ChuckPadSocial sharedInstance] localLogOut];
            
            [expectation fulfill];
        }];
        [self waitForExpectations];
    }
    
    [self cleanUpFollowingTest];
}

- (void)testEmailCaseSensitivity {
    ChuckPadUser *user = [ChuckPadUser generateUser];
    for (int i = 0; i <= 2; i++) {
        // Change username for every pass so we don't hit the duplicate username case
        user.username = [self randomStringWithLength:20];
        
        // 0 pass - leave email as (should succeed)
        
        // 1 pass - make email upper case (should fail)
        if (i == 1) {
            user.email = [user.email uppercaseString];
        }
        
        // 2 pass - make email lower case (should fail)
        if (i == 2) {
            user.email = [user.email lowercaseString];
        }
        
        XCTestExpectation *expectation = [self expectationWithDescription:@"createUser timed out"];
        [[ChuckPadSocial sharedInstance] createUser:user.username email:user.email password:user.password callback:^(BOOL succeeded, NSError *error) {
            // Only the first call should succeed because the rest are upper/lower case variations of the first email used
            XCTAssertTrue(succeeded == (i == 0));
            
            // The error message should only mention that the email is used, NOT the username.
            if (i != 0) {
                XCTAssertTrue([[error localizedDescription] containsString:@"email"]);
                XCTAssertFalse([[error localizedDescription] containsString:@"username"]);
            }
            
            // Need to do a localLogOut to clear credentials so we can log in again.
            [[ChuckPadSocial sharedInstance] localLogOut];
            
            [expectation fulfill];
        }];
        [self waitForExpectations];
    }
    
    [self cleanUpFollowingTest];
}

- (void)testAuthTokenInvalidResponseCode {
    // Create a user
    [self generateLocalUserAndCreate];
    
    // Call a secret method on ChuckPadKeychain to save keychain information in memory
    [self callSecretStaticMethod:@"copyKeychainInfoToMemory" class:@"ChuckPadKeychain"];
    
    // Log out using the logOut API which invalidates the auth token on the service
    XCTestExpectation *expectation = [self expectationWithDescription:@"logOut timed out"];
    [[ChuckPadSocial sharedInstance] logOut:^(BOOL succeeded, NSError *error) {
        XCTAssertTrue(succeeded);
        XCTAssertTrue(error == nil);
        [self doPostLogOutAssertChecks];
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    // Our auth token should now be invalidated and our keychain has been cleared.
    
    // Call another secret method on ChuckPadKeychain to push our in-memory copy back into the keychain
    // Note that we are copying an invalid auth token into the keychain.
    [self callSecretStaticMethod:@"copyMemoryInfoToKeychain" class:@"ChuckPadKeychain"];
    
    // Try to upload a patch but this should fail because our auth token that we restored into the keychain is invalid.
    [self generatePatchAndUpload:NO];
  
    [self callSecretStaticMethod:@"copyMemoryInfoToKeychain" class:@"ChuckPadKeychain"];
    
    // Logging out should fail because we are already logged out
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"logOut timed out"];
    [[ChuckPadSocial sharedInstance] logOut:^(BOOL succeeded, NSError *error) {
        XCTAssertFalse(succeeded);
        [expectation2 fulfill];
    }];
    [self waitForExpectations];
    
    // TODO Restore again and test more APIs for catching and responding to the invalid auth token!
    
    [self cleanUpFollowingTest];
}

@end
