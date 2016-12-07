//
//  ChuckPadBaseTest.h
//  hello-chuckpad
//
//  Created by Mark Cerqueira on 11/30/16.
//
//  Subclass of XCTestCase with helper methods that can be used by subclass implementations.

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "ChuckPadSocial.h"

@interface ChuckPadUser : NSObject

@property(nonatomic, strong) NSNumber *userId;
@property(nonatomic, strong) NSString *username;
@property(nonatomic, strong) NSString *password;
@property(nonatomic, strong) NSString *email;
@property(nonatomic, assign) NSInteger totalPatches;

// Generate a "local" user object that can be used to create a user on the service.
+ (ChuckPadUser *)generateUser;

// The userId we generate for our local user is likely not correct. When we are given the proper
// userId from the service one can call this method to make the value consistent.
- (void)updateUserId:(NSInteger)userId;

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

// The service will return a patch object in certain APIs. This property contains the last known
// Patch (as the service knows it).
@property(nonatomic, strong) Patch *lastServerPatch;

// Generates a local patch object that we can use to contact the API and then verify its contents. With this default
// method the name of the patch will be the filename, it will have NO parent, and it will not be hidden. This method
// does not take a filename so it will cycle through the files in the chuck-samples folder when called.
+ (ChuckPadPatch *)generatePatch;

// Similar to the above generatePatch method but creates a patch with the filename specified.
+ (ChuckPadPatch *)generatePatch:(NSString *)filename;

// The other versions of generatePatch use the "chuck-samples" folder but this method allows one to pull patches from
// other folders.
+ (ChuckPadPatch *)generatePatch:(NSString *)folderName filename:(NSString *)filename;

// Returns the number of files in the chuck-samples directory. Given the service disallows uploading duplicate files
// for the same user, a single user should never upload more than this amount of patches during a test.
+ (NSInteger)numberOfChuckFilesInSamplesDirectory;

// Generates a new random name and description on the local ChuckPadPatch object.
- (void)setNewNameAndDescription;

@end

@interface ChuckPadBaseTest : XCTestCase

// There are some special methods in ChuckPadSocial and ChuckPadKeychain that are not exposed in header files because
// they should only be used by unit tests. These methods allow you to call those methods without getting compiler warnings.
- (void)callSecretStaticMethod:(NSString *)method class:(NSString *)className;

// Returns a random string (using lowercase letters, upper case letters, numbers, period, hyphen, and underscore) with
// the specified length.
- (NSString *)randomStringWithLength:(int)length;

// Once ChuckPadSocial is bootstrapped for a particular patch type (e.g. MiniAudicle) changing that value throws an
// exception. This method allows one to "reset" ChuckPadSocial's state.
- (void)resetChuckPadSocialForPatchType:(PatchType)patchType;

// This generates a local ChuckPadUser object, calls the createUser API with the credentials for that user, and then
// returns the local object to the caller. This method asserts the createUser API succeeds.
- (ChuckPadUser *)generateLocalUserAndCreate;

// Given a local ChuckPadUser object that's been created already, this calls the createUser API using credentials stored
// in that local ChuckPadUser object.
- (ChuckPadUser *)createUserFromLocalUser:(ChuckPadUser *)user;

// Given a local ChuckPadUser object logs in via the logIn API.
- (void)logInWithLocalUser:(ChuckPadUser *)user;

// Generates a patch with data from the given filename and checks API success against the successExpected parameter. 
- (ChuckPadPatch *)generatePatchAndUpload:(NSString *)filename successExpected:(BOOL)successExpected;

// Generates a patch and calls the uploadPatch API. Cases expected to fail can pass NO for the BOOL parameter.
- (ChuckPadPatch *)generatePatchAndUpload:(BOOL)successExpected;

// Uploads multiple patches. Note that for a single user, the number of patches uploaded should not exceed
// [ChuckPadPatch numberOfChuckFilesInSamplesDirectory] as this will cause duplicate data to be attempted to be uploaded
// which the service forbids.
- (void)uploadMultiplePatches:(NSInteger)patchCount;

// Given a Patch from the service, a local ChuckPadPatch that was used to create it, and the user the patch belongs to,
// this method asserts state is consistent all parameters.
- (void)assertPatch:(Patch *)patch localPatch:(ChuckPadPatch *)localPatch isConsistentForUser:(ChuckPadUser *)user;

// Verifies logged in user state is consistent, logs out the user (if logOut is YES), and verifies logged out state is
// consistent.
- (void)postAuthCallAssertsChecks:(BOOL)succeeded user:(ChuckPadUser *)user logOut:(BOOL)logOut;

// Once a user logs in this asserts that ChuckPadSocial is in a consistent state for the user that just logged in.
- (void)doPostAuthAssertChecks:(ChuckPadUser *)user;

// Once a user is logged out this asserts that ChuckPadSocial and its internal keychain are in a consistent state.
- (void)doPostLogOutAssertChecks;

// Helper method that waits for any unfulfilled expectations. Defaults to waiting 5.0 seconds.
- (void)waitForExpectations;

// Helper method that waits the specified time (in seconds) for unfulfilled expectations.
- (void)waitForExpectations:(NSTimeInterval)timeout;

// Call this at the end of each test to clean up state (log out any currently logged in user).
- (void)cleanUpFollowingTest;

// Asserts that the given error is not nil and contains the string given.
- (void)assertError:(NSError *)error descriptionContainsString:(NSString *)string;

// Asserts that the given error is not nil and contains yesString and does not contain noString.
- (void)assertError:(NSError *)error descriptionContainsString:(NSString *)yesString doesNotContainString:(NSString *)noString;

// Asserts that the given error is not nil and contains all the strings given.
- (void)assertError:(NSError *)error descriptionContainsStrings:(NSArray *)strings;

@end
