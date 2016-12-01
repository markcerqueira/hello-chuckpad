//
//  ChuckPadBaseTest.m
//  hello-chuckpad
//
//  Created by Mark Cerqueira on 11/30/16.
//
//

#import "ChuckPadBaseTest.h"

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

@implementation ChuckPadPatch

// This will let us cycle through the chuck-samples files when calling the generatePatch method
static int sDirectoryIndex = 0;

// Generates a local patch object that we can use to contact the API and then verify its contents. With this default
// method the name of the patch will be the filename, it will have NO parent, and it will not be hidden.
+ (ChuckPadPatch *)generatePatch {
    NSString *chuckSamplesPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"chuck-samples"];
    NSArray * dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:chuckSamplesPath error:nil];
    NSString * filename = [dirContents objectAtIndex:sDirectoryIndex];
    
    if (++sDirectoryIndex == [dirContents count]) {
        sDirectoryIndex = 0;
    }
    
    return [self generatePatch:filename];
}

+ (ChuckPadPatch *)generatePatch:(NSString *)filename {
    ChuckPadPatch *patch = [[ChuckPadPatch alloc] init];
    
    patch.name = filename;
    patch.filename = filename;
    patch.patchDescription = [[NSUUID UUID] UUIDString];
    
    NSString *chuckSamplesPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"chuck-samples"];
    patch.fileData = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", chuckSamplesPath, filename]];
    
    patch.hasParent = NO;
    patch.isHidden = NO;
    patch.downloadCount = 0;
    patch.abuseReportCount = 0;
    
    return patch;
}

+ (NSInteger)numberOfChuckFilesInSamplesDirectory {
    NSString *chuckSamplesPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"chuck-samples"];
    return [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:chuckSamplesPath error:nil] count];
}

- (void)setHidden:(BOOL)hidden {
    self.isHidden = hidden;
}

- (void)setNewNameAndDescription {
    self.name = [[NSUUID UUID] UUIDString];
    self.patchDescription = [[NSUUID UUID] UUIDString];
}

@end

@implementation ChuckPadBaseTest

- (void)callSecretStaticMethod:(NSString *)method class:(NSString *)className {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [NSClassFromString(className) performSelector:NSSelectorFromString(method)];
#pragma clang diagnostic pop
}

// Source: http://stackoverflow.com/a/2633948/265791
- (NSString *)randomStringWithLength:(int)len {
    // 66 character length string
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex:arc4random_uniform((int)[letters length])]];
    }
    return randomString;
}

- (void)resetChuckPadSocialForPatchType:(PatchType)patchType {
    // Before unit tests run, the code in AppDelegate.m runs that bootstraps our ChuckPadSocail class to a particular
    // instance. Call a special debug method to reset all that bootstrapping so we start tests from a clean slate.
    [self callSecretStaticMethod:@"resetSharedInstanceAndBoostrap" class:@"ChuckPadSocial"];
    
    [ChuckPadSocial bootstrapForPatchType:patchType];
    [[ChuckPadSocial sharedInstance] setEnvironment:Local];
}

- (void)setUp {
    [self resetChuckPadSocialForPatchType:MiniAudicle];
    
    [super setUp];
}

- (void)tearDown {
    [[ChuckPadSocial sharedInstance] localLogOut];
    
    [super tearDown];
}

- (ChuckPadUser *)generateLocalUserAndCreate {
    ChuckPadUser *user = [ChuckPadUser generateUser];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"createUser timed out"];
    [[ChuckPadSocial sharedInstance] createUser:user.username email:user.email password:user.password callback:^(BOOL succeeded, NSError *error) {
        [self postAuthCallAssertsChecks:succeeded user:user logOut:NO];
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    return user;
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
        [[ChuckPadSocial sharedInstance] localLogOut];
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

@end
