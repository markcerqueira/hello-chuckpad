//
//  ChuckPadServiceTests.m
//  hello-chuckpad
//  Created by Mark Cerqueira on 7/25/16.
//
//  NOTE: These tests run against the chuckpad-social server running locally on your machine. To run the chuckpad-social
//  server on your computer please see: https://github.com/markcerqueira/chuckpad-social

#import <XCTest/XCTest.h>

#import "ChuckPadKeychain.h"
#import "ChuckPadSocial.h"
#import "NSDate+Helper.h"
#import "Patch.h"
#import "PatchCache.h"

@interface ChuckPadUser : NSObject

@property(nonatomic, strong) NSNumber *userId;
@property(nonatomic, strong) NSString *username;
@property(nonatomic, strong) NSString *password;
@property(nonatomic, strong) NSString *email;
@property(nonatomic, assign) NSInteger totalPatches;

@end

@implementation ChuckPadUser

+ (ChuckPadUser *)generateUser {
    ChuckPadUser *user = [[ChuckPadUser alloc] init];
    
    user.username = [[[[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@"iOS"] substringToIndex:12] lowercaseString];
    user.password = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    user.email = [NSString stringWithFormat:@"%@@%@.com", user.username, user.username];
    user.totalPatches = 0;
    
    return user;
}

- (void)updateUserId:(NSInteger)userId {
    self.userId = @(userId);
}

@end


@interface ChuckPadPatch : NSObject

@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSString *filename;
@property(nonatomic, strong) NSString *patchDescription;
@property(nonatomic, strong) NSData *fileData;
@property(nonatomic, assign) BOOL hasParent;
@property(nonatomic, assign) BOOL isHidden;
@property(nonatomic, assign) NSInteger abuseReportCount;
@property(nonatomic, assign) NSInteger downloadCount;

@property(nonatomic, strong) Patch *lastServerPatch;

@end

@implementation ChuckPadPatch

// Generates a local patch object that we can use to contact the API and then verify its contents. With this default
// method the name of the patch will be the filename, it will have NO parent, and it will not be hidden.
+ (ChuckPadPatch *)generatePatch:(NSString *)filename {
    ChuckPadPatch *patch = [[ChuckPadPatch alloc] init];
    
    NSString *chuckSamplesPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"chuck-samples"];

    patch.name = filename;
    patch.filename = filename;
    patch.patchDescription = [[NSUUID UUID] UUIDString];
    patch.fileData = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", chuckSamplesPath, filename]];
    
    patch.hasParent = NO;
    patch.isHidden = NO;
    patch.downloadCount = 0;
    patch.abuseReportCount = 0;
    
    return patch;
}

- (void)setHidden:(BOOL)hidden {
    self.isHidden = hidden;
}

- (void)setNewNameAndDescription {
    self.name = [[NSUUID UUID] UUIDString];
    self.patchDescription = [[NSUUID UUID] UUIDString];
}

@end


@interface ChuckPadServiceTests : XCTestCase

@end

@implementation ChuckPadServiceTests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [[ChuckPadSocial sharedInstance] setEnvironment:Local];
    [[ChuckPadSocial sharedInstance] logOut];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [[ChuckPadSocial sharedInstance] logOut];
    
    [super tearDown];
}

- (void)waitForExpectations {
    [self waitForExpectations:5.0];
}

- (void)waitForExpectations:(NSTimeInterval)timeout {
    [self waitForExpectationsWithTimeout:timeout handler:^(NSError *error) {
        if (error) {
            NSLog(@"waitForExpectations - exceptation not met with error: %@", error);
        }
    }];
}

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

    // 4 - Log in again with the updated password
    XCTestExpectation *expectation4 = [self expectationWithDescription:@"logIn timed out (4)"];
    [[ChuckPadSocial sharedInstance] logIn:user.username password:user.password callback:^(BOOL succeeded, NSError *error) {
        // Do not log in because we are going to change the password in the next call
        [self postAuthCallAssertsChecks:succeeded user:user logOut:YES];
        [expectation4 fulfill];
    }];
    [self waitForExpectations];
    
    // Log out of our existing user
    [[ChuckPadSocial sharedInstance] logOut];
    
    // 5 - Try to create another user with the same email. Note we purposefully use user.email below instead of user2.email
    ChuckPadUser *user2 = [ChuckPadUser generateUser];
    XCTestExpectation *expectation5 = [self expectationWithDescription:@"createUser timed out (5)"];
    [[ChuckPadSocial sharedInstance] createUser:user2.username email:user.email password:user2.password callback:^(BOOL succeeded, NSError *error) {
        XCTAssertFalse(succeeded);
        XCTAssertTrue(error != nil && [[error localizedDescription] containsString:@"email"]);
        XCTAssertFalse([[error localizedDescription] containsString:@"username"]);
        [expectation5 fulfill];
    }];
    [self waitForExpectations];
    
    // 6 - Try to create another user with the same username. Note we purposefully use user.username below instead of user2.username
    XCTestExpectation *expectation6 = [self expectationWithDescription:@"createUser timed out (6)"];
    [[ChuckPadSocial sharedInstance] createUser:user.username email:user2.email password:user2.password callback:^(BOOL succeeded, NSError *error) {
        XCTAssertFalse(succeeded);
        XCTAssertTrue(error != nil && [[error localizedDescription] containsString:@"username"]);
        XCTAssertFalse([[error localizedDescription] containsString:@"email"]);
        [expectation6 fulfill];
    }];
    [self waitForExpectations];
    
    // 7 - Try to create another user with the same username and email. The returned error should mention both email and username
    XCTestExpectation *expectation7 = [self expectationWithDescription:@"createUser timed out (7)"];
    [[ChuckPadSocial sharedInstance] createUser:user.username email:user.email password:user2.password callback:^(BOOL succeeded, NSError *error) {
        XCTAssertFalse(succeeded);
        XCTAssertTrue(error != nil && [[error localizedDescription] containsString:@"username"]);
        XCTAssertTrue(error != nil && [[error localizedDescription] containsString:@"email"]);
        [expectation7 fulfill];
    }];
    [self waitForExpectations];
}

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
    [localPatch setHidden:YES];
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
        
        localPatch.lastServerPatch.abuseReportCount++;
        
        [expectation8 fulfill];
    }];
    [self waitForExpectations];
    
    // 9 - Check patch metadata to ensure abuse count has been incremented
    XCTestExpectation *expectation9 = [self expectationWithDescription:@"getPatchInfo timed out (9)"];
    [[ChuckPadSocial sharedInstance] getPatchInfo:localPatch.lastServerPatch.patchId callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertTrue(succeeded);

        XCTAssertTrue(patch.abuseReportCount == 1);
        
        [expectation9 fulfill];
    }];
    
    // 10 - Now unreport the patch as abusive
    XCTestExpectation *expectation10 = [self expectationWithDescription:@"reportAbuse timed out (10)"];
    [[ChuckPadSocial sharedInstance] reportAbuse:localPatch.lastServerPatch isAbuse:NO callback:^(BOOL succeeded, NSError *error) {
        XCTAssertTrue(succeeded);
        
        localPatch.lastServerPatch.abuseReportCount--;
        
        [expectation10 fulfill];
    }];
    [self waitForExpectations];
    
    // 11 - And now verify the patch metadata has been updated to have 0 abuse reports
    XCTestExpectation *expectation11 = [self expectationWithDescription:@"getPatchInfo timed out (11)"];
    [[ChuckPadSocial sharedInstance] getPatchInfo:localPatch.lastServerPatch.patchId callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertTrue(succeeded);
        
        XCTAssertTrue(patch.abuseReportCount == 0);
        
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
}

- (void)assertPatch:(Patch *)patch localPatch:(ChuckPadPatch *)localPatch isConsistentForUser:(ChuckPadUser *)user {
    XCTAssertTrue(patch != nil);
    XCTAssertTrue(localPatch != nil);
    XCTAssertTrue(user != nil);

    XCTAssertTrue([localPatch.name isEqualToString:patch.name]);
    XCTAssertTrue([localPatch.filename isEqualToString:patch.filename]);
    XCTAssertTrue([localPatch.patchDescription isEqualToString:patch.patchDescription]);

    XCTAssertTrue([patch.creatorUsername isEqualToString:user.username]);
    
    XCTAssertTrue(localPatch.isHidden == patch.hidden);
    XCTAssertTrue(localPatch.hasParent == [patch hasParentPatch]);
    
    XCTAssertTrue(localPatch.downloadCount == patch.downloadCount);
    XCTAssertTrue(localPatch.abuseReportCount == patch.abuseReportCount);
    
    XCTAssertFalse(patch.isFeatured);
    XCTAssertFalse(patch.isDocumentation);
    
    // If we pass all these assertions, attach the patch as the server knows it to our local patch object so we
    // have the option of mutating the server patch in subsequent tests. NOTE: lastServerPatch should NEVER be
    // mutated locally. It should simply be used to pass into API calls.
    localPatch.lastServerPatch = patch;
    
    // For every assert patch operation convert that patch to a dictionary and then initialize a new patch with that
    // dictionary. Assert both patches are equal.
    NSDictionary *patchAsDictionary = [localPatch.lastServerPatch asDictionary];
    Patch *patchFromDictionary = [[Patch alloc] initWithDictionary:patchAsDictionary];
    XCTAssertTrue([patchFromDictionary isEqual:localPatch.lastServerPatch]);
}

// Verifies logged in user state is consistent, logs out the user, and verifies logged out state is consistent.
- (void)postAuthCallAssertsChecks:(BOOL)succeeded user:(ChuckPadUser *)user logOut:(BOOL)logOut {
    XCTAssertTrue(succeeded);

    [self doPostAuthAssertChecks:user];

    if (logOut) {
        [[ChuckPadSocial sharedInstance] logOut];
        [self doPostLogOutAssertChecks];
    }
}

// Once a user logs in this asserts that ChuckPadSocial is in a consistent state for the user that just logged in.
- (void)doPostAuthAssertChecks:(ChuckPadUser *)user {
    XCTAssertTrue([[ChuckPadSocial sharedInstance] isLoggedIn]);

    XCTAssertTrue([user.username isEqualToString:[[ChuckPadSocial sharedInstance] getLoggedInUserName]]);
    XCTAssertTrue([user.username isEqualToString:[[ChuckPadKeychain sharedInstance] getLoggedInUserName]]);
    
    XCTAssertTrue([user.email isEqualToString:[[ChuckPadSocial sharedInstance] getLoggedInEmail]]);
    XCTAssertTrue([user.email isEqualToString:[[ChuckPadKeychain sharedInstance] getLoggedInEmail]]);
}

// Once a user is logged out this asserts that ChuckPadSocial and its internal keychain are in a consistent state.
- (void)doPostLogOutAssertChecks {
    XCTAssertFalse([[ChuckPadSocial sharedInstance] isLoggedIn]);

    XCTAssertTrue([[ChuckPadKeychain sharedInstance] getLoggedInUserName] == nil);
    XCTAssertTrue([[ChuckPadKeychain sharedInstance] getLoggedInAuthToken] == nil);
    XCTAssertTrue([[ChuckPadKeychain sharedInstance] getLoggedInEmail] == nil);
}

@end
