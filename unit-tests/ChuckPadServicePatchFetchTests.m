//
//  ChuckPadServicePatchFetchTests.m
//  hello-chuckpad
//  Created by Mark Cerqueira on 12/31/16.
//

#import "ChuckPadBaseTest.h"

@interface ChuckPadServicePatchFetchTests : ChuckPadBaseTest

@end

@implementation ChuckPadServicePatchFetchTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testGetRecentPatches {
    XCTestExpectation *expectation = [self expectationWithDescription:@"getRecentPatches timed out"];
    [[ChuckPadSocial sharedInstance] getRecentPatches:^(NSArray *patchesArray, NSError *error) {
        XCTAssertTrue(patchesArray != nil);
        
        // If the environment was wiped clean recently we will have 0 patches returned by this API.
        XCTAssertTrue([patchesArray count] >= 0);
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    [self cleanUpFollowingTest];
}


- (void)testGetRecentPatchesReturnsMostRecent {
    NSMutableDictionary *guidToTimesSeen = [[NSMutableDictionary alloc] init];
    
    int TIMES_TO_LOOP = 5;
    
    // This is so our uploadPatch in the second for loop below always succeeds.
    XCTAssertTrue([ChuckPadPatch numberOfChuckFilesInSamplesDirectory] > NUMBER_PATCHES_RECENT_API);
    
    // For 5 times, upload the number of patches the getRecent API call returns and track how often we see each GUID.
    // Since we're uploading the number we expect returned, we should see each of the patches exactly once.
    for (int i = 0; i < TIMES_TO_LOOP; i++) {
        // Create user in here so we avoid running into uploading duplicate patch data for a single user.
        [self generateLocalUserAndCreate];
        
        for (int j = 0 ; j < NUMBER_PATCHES_RECENT_API; j++) {
            ChuckPadPatch *patch = [self generatePatch:YES];
            [guidToTimesSeen setObject:@(0) forKey:patch.lastServerPatch.guid];
        }
        
        XCTestExpectation *expectation = [self expectationWithDescription:@"getRecentPatches timed out"];
        [[ChuckPadSocial sharedInstance] getRecentPatches:^(NSArray *patchesArray, NSError *error) {
            XCTAssertTrue(patchesArray != nil);
            XCTAssertTrue([patchesArray count] == NUMBER_PATCHES_RECENT_API);
            
            for (Patch *patch in patchesArray) {
                [guidToTimesSeen setObject:@([guidToTimesSeen[patch.guid] intValue] + 1) forKey:patch.guid];
            }
            
            [expectation fulfill];
        }];
        [self waitForExpectations];
    }
    
    XCTAssertTrue([guidToTimesSeen count] == TIMES_TO_LOOP * NUMBER_PATCHES_RECENT_API);
    for (NSString *guid in guidToTimesSeen) {
        XCTAssertTrue([guidToTimesSeen[guid] intValue] == 1);
    }
    
    [self cleanUpFollowingTest];
}

- (void)testGetRecentReturnsOnlyVisible {
    [self generateLocalUserAndCreate];
    
    NSMutableSet *hiddenPatchesGUIDs = [[NSMutableSet alloc] init];
    
    for (int j = 0 ; j < NUMBER_PATCHES_RECENT_API; j++) {
        BOOL uploadAsHidden = j % 2 == 0;
        
        ChuckPadPatch *patch = [self generatePatch:uploadAsHidden successExpected:YES];
        
        if (uploadAsHidden) {
            [hiddenPatchesGUIDs addObject:patch.lastServerPatch.guid];
        }
    }
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"getRecentPatches timed out"];
    [[ChuckPadSocial sharedInstance] getRecentPatches:^(NSArray *patchesArray, NSError *error) {
        XCTAssertTrue(patchesArray != nil);
        
        for (Patch *patch in patchesArray) {
            XCTAssertFalse([hiddenPatchesGUIDs containsObject:patch.guid]);
        }
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
}

- (void)testGetRecentReturnsInOrder {
    [self generateLocalUserAndCreate];
    
    NSMutableArray *uploadedPatchGUIDs = [[NSMutableArray alloc] init];
    
    for (int j = 0 ; j < NUMBER_PATCHES_RECENT_API; j++) {
        ChuckPadPatch *patch = [self generatePatch:YES];
        
        // Always insert at the front of the array because we want the most recent at the front of the list.
        [uploadedPatchGUIDs insertObject:patch.lastServerPatch.guid atIndex:0];
    }
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"getRecentPatches timed out"];
    [[ChuckPadSocial sharedInstance] getRecentPatches:^(NSArray *patchesArray, NSError *error) {
        XCTAssertTrue(patchesArray != nil);
        
        for (int i = 0; i < NUMBER_PATCHES_RECENT_API; i++) {
            XCTAssertTrue([((Patch *)[patchesArray objectAtIndex:0]).guid isEqualToString:[uploadedPatchGUIDs objectAtIndex:0]]);
        }
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
}

- (void)testGetMyPatches {
    ChuckPadUser *user = [self generateLocalUserAndCreate];
    
    ChuckPadPatch *localPatch = [self generatePatch:YES];
    user.totalPatches++;
    
    // Test get my patches API. This should return one patch for the new user we created and uploaded a patch for.
    XCTestExpectation *expectation = [self expectationWithDescription:@"getMyPatches timed out"];
    [[ChuckPadSocial sharedInstance] getMyPatches:^(NSArray *patchesArray, NSError *error) {
        XCTAssertTrue(patchesArray != nil);
        XCTAssertTrue([patchesArray count] == user.totalPatches);
        
        [self assertPatch:patchesArray[0] localPatch:localPatch isConsistentForUser:user];
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    for (int i = 0; i < 10; i++) {
        [self generatePatch:YES];
        user.totalPatches++;
    }
    
    // We uploaded more patches so check if count is now correct.
    expectation = [self expectationWithDescription:@"getMyPatches timed out"];
    [[ChuckPadSocial sharedInstance] getMyPatches:^(NSArray *patchesArray, NSError *error) {
        XCTAssertTrue(patchesArray != nil);
        XCTAssertTrue([patchesArray count] == user.totalPatches);
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    [self cleanUpFollowingTest];
}

- (void)testGetMyPatchesReturnsOnlyMyPatches {
    for (int i = 0; i < 5; i++) {
        [self generateLocalUserAndCreate];
        ChuckPadPatch *patch = [self generatePatch:YES];
        
        XCTestExpectation *expectation = [self expectationWithDescription:@"getMyPatches timed out"];
        [[ChuckPadSocial sharedInstance] getMyPatches:^(NSArray *patchesArray, NSError *error) {
            XCTAssertTrue([patchesArray count] == 1);
            XCTAssertTrue([[patchesArray objectAtIndex:0] isEqual:patch.lastServerPatch]);
            
            [expectation fulfill];
        }];
        [self waitForExpectations];
    }
    
    [self cleanUpFollowingTest];
}

- (void)testGetPatchesForUser {
    ChuckPadUser *user = [self generateLocalUserAndCreate];
    
    NSInteger patchesToUpload = 12;
    
    NSMutableSet *patchGUIDsUploaded = [NSMutableSet new];
    for (int i = 0; i < patchesToUpload; i++) {
        ChuckPadPatch * patch = [self generatePatch:YES];
        [patchGUIDsUploaded addObject:patch.lastServerPatch.guid];
    }
    
    [[ChuckPadSocial sharedInstance] localLogOut];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"getPatchesForUserId timed out"];
    [[ChuckPadSocial sharedInstance] getPatchesForUserId:user.userId callback:^(NSArray *patchesArray, NSError *error) {
        XCTAssertTrue([patchesArray count] == patchesToUpload);
        
        for (Patch *patch in patchesArray) {
            XCTAssertTrue([patchGUIDsUploaded containsObject:patch.guid]);
            [patchGUIDsUploaded removeObject:patch.guid];
        }
        
        XCTAssertTrue([patchGUIDsUploaded count] == 0);
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    [self cleanUpFollowingTest];
}

- (void)testGetPatchesForUserWithNoPatches {
    ChuckPadUser *user = [self generateLocalUserAndCreate];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"getPatchesForUserId timed out"];
    [[ChuckPadSocial sharedInstance] getPatchesForUserId:user.userId callback:^(NSArray *patchesArray, NSError *error) {
        XCTAssertTrue(error == nil);
        XCTAssertTrue([patchesArray count] == 0);
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    [self cleanUpFollowingTest];
}

- (void)testGetPatchesForNonexistentUser {
    ChuckPadUser *user = [self generateLocalUserAndCreate];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"getPatchesForUserId timed out"];
    [[ChuckPadSocial sharedInstance] getPatchesForUserId:(user.userId + 1) callback:^(NSArray *patchesArray, NSError *error) {
        XCTAssertTrue(error != nil);
        XCTAssertTrue(patchesArray == nil);
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    [self cleanUpFollowingTest];
}

@end
