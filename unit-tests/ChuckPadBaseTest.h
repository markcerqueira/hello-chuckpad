//
//  ChuckPadBaseTest.h
//  hello-chuckpad
//
//  Created by Mark Cerqueira on 11/30/16.
//
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "ChuckPadSocial.h"

@interface ChuckPadUser : NSObject

@property(nonatomic, strong) NSNumber *userId;
@property(nonatomic, strong) NSString *username;
@property(nonatomic, strong) NSString *password;
@property(nonatomic, strong) NSString *email;
@property(nonatomic, assign) NSInteger totalPatches;

+ (ChuckPadUser *)generateUser;

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

@property(nonatomic, strong) Patch *lastServerPatch;

// Generates a local patch object that we can use to contact the API and then verify its contents. With this default
// method the name of the patch will be the filename, it will have NO parent, and it will not be hidden.
+ (ChuckPadPatch *)generatePatch;

+ (ChuckPadPatch *)generatePatch:(NSString *)filename;

+ (NSInteger)numberOfChuckFilesInSamplesDirectory;

- (void)setHidden:(BOOL)hidden;

- (void)setNewNameAndDescription;

@end

@interface ChuckPadBaseTest : XCTestCase

- (void)callSecretStaticMethod:(NSString *)method class:(NSString *)className;

- (NSString *)randomStringWithLength:(int)length;

- (void)resetChuckPadSocialForPatchType:(PatchType)patchType;

- (ChuckPadUser *)generateLocalUserAndCreate;

- (void)assertPatch:(Patch *)patch localPatch:(ChuckPadPatch *)localPatch isConsistentForUser:(ChuckPadUser *)user;

// Verifies logged in user state is consistent, logs out the user, and verifies logged out state is consistent.
- (void)postAuthCallAssertsChecks:(BOOL)succeeded user:(ChuckPadUser *)user logOut:(BOOL)logOut;

// Once a user logs in this asserts that ChuckPadSocial is in a consistent state for the user that just logged in.
- (void)doPostAuthAssertChecks:(ChuckPadUser *)user;

// Once a user is logged out this asserts that ChuckPadSocial and its internal keychain are in a consistent state.
- (void)doPostLogOutAssertChecks;

- (void)waitForExpectations;

- (void)waitForExpectations:(NSTimeInterval)timeout;

@end
