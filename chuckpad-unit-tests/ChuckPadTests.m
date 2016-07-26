//
//  ChuckPadTests.m
//  chuckpad-social-ios-test
//
//  Created by Mark Cerqueira on 7/25/16.
//
//

#import <XCTest/XCTest.h>

#import "ChuckPadKeychain.h"
#import "ChuckPadSocial.h"
#import "Patch.h"

@interface ChuckPadTests : XCTestCase {
    NSString *_username;
    NSString *_password;
    NSString *_email;
    NSInteger _userId;
}

@end

@implementation ChuckPadTests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [[ChuckPadSocial sharedInstance] setEnvironmentToDebug];
    [[ChuckPadSocial sharedInstance] logOut];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [[ChuckPadSocial sharedInstance] logOut];
    
    [super tearDown];
}

- (void)testToggleEnvironmentUrl {
    NSString *url = [[ChuckPadSocial sharedInstance] getBaseUrl];
    
    [[ChuckPadSocial sharedInstance] toggleEnvironment];

    NSString *toggledUrl = [[ChuckPadSocial sharedInstance] getBaseUrl];
    
    XCTAssertFalse([url isEqualToString:toggledUrl], @"Base URL did not change after toggle environment call");
}

- (void)testUserAPI {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"createUser timed out"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"logIn with username timed out"];

    _username = [[[[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@"iOS"] substringToIndex:12] lowercaseString];
    _password = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    _email = [NSString stringWithFormat:@"%@@%@.com", _username, _username];
    
    [[ChuckPadSocial sharedInstance] createUser:_username withEmail:_email withPassword:_password withCallback:^(BOOL succeeded, NSError *error) {
        [self postAuthCallAssertsChecks:succeeded];
        
        [expectation1 fulfill];

        [[ChuckPadSocial sharedInstance] logIn:_username withPassword:_password withCallback:^(BOOL succeeded, NSError *error) {
            // TODO Once logIn supports sending username/email, we can call this method and test logging in with email
            // [self postAuthCallAssertsChecks:succeeded];
            
            XCTAssertTrue([[ChuckPadSocial sharedInstance] isLoggedIn]);
            
            [[ChuckPadSocial sharedInstance] logOut];
            [self doPostLogOutAssertChecks];
            
            [expectation2 fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"testCreateUser - error: %@", error);
        }
    }];
}

- (void)testPatchAPI {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"createUser timed out"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"uploadPatch timed out"];
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"getMyPatches timed out"];
    XCTestExpectation *expectation4 = [self expectationWithDescription:@"getAllPatches timed out"];
    XCTestExpectation *expectation5 = [self expectationWithDescription:@"getPatchesForUserId timed out"];

    _username = [[[[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@"iOS"] substringToIndex:12] lowercaseString];
    _password = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    _email = [NSString stringWithFormat:@"%@@%@.com", _username, _username];
    
    [[ChuckPadSocial sharedInstance] createUser:_username withEmail:_email withPassword:_password withCallback:^(BOOL succeeded, NSError *error) {
        NSString *filename = @"demo0.ck";
        NSString *chuckSamplesPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"chuck-samples"];
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", chuckSamplesPath, filename];
        NSData *fileData = [NSData dataWithContentsOfFile:filePath];
        
        [expectation1 fulfill];

        [[ChuckPadSocial sharedInstance] uploadPatch:filename isFeatured:NO isDocumentation:YES filename:filename fileData:fileData callback:^(BOOL succeeded, Patch *patch) {
            XCTAssertTrue(succeeded);

            XCTAssertTrue(patch != nil);
            
            XCTAssertTrue([patch.name isEqualToString:filename]);
            XCTAssertTrue([patch.creatorUsername isEqualToString:_username]);
            XCTAssertFalse(patch.isFeatured);
            XCTAssertTrue(patch.isDocumentation);

            [expectation2 fulfill];

            [[ChuckPadSocial sharedInstance] getAllPatches:^(NSArray *patchesArray, NSError *error) {
                XCTAssertTrue(patchesArray != nil);
                XCTAssertTrue([patchesArray count] >= 1);

                [expectation3 fulfill];
                
                [[ChuckPadSocial sharedInstance] getMyPatches:^(NSArray *patchesArray, NSError *error) {
                    XCTAssertTrue(patchesArray != nil);
                    XCTAssertTrue([patchesArray count] >= 1);
                    
                    [expectation4 fulfill];
                    
                    Patch *patch = [patchesArray objectAtIndex:0];
                    _userId = patch.creatorId;
                
                    [[ChuckPadSocial sharedInstance] getPatchesForUserId:_userId withCallback:^(NSArray *patchesArray, NSError *error) {
                        XCTAssertTrue(patchesArray != nil);
                        XCTAssertTrue([patchesArray count] >= 1);
                        
                        for (Patch *patch in patchesArray) {
                            XCTAssertTrue(patch.creatorId == _userId);
                            XCTAssertTrue([patch.creatorUsername isEqualToString:_username]);
                        }
                        
                        [expectation5 fulfill];
                    }];
                }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"testPatchAPI - error: %@", error);
        }
    }];
}

- (void)postAuthCallAssertsChecks:(BOOL)succeeded {
    XCTAssertTrue(succeeded);

    [self doPostAuthAssertChecks];
    [[ChuckPadSocial sharedInstance] logOut];
    [self doPostLogOutAssertChecks];
}

- (void)doPostAuthAssertChecks {
    XCTAssertTrue([[ChuckPadSocial sharedInstance] isLoggedIn]);

    XCTAssertTrue([_username isEqualToString:[[ChuckPadSocial sharedInstance] getLoggedInUserName]]);

    XCTAssertTrue([_username isEqualToString:[[ChuckPadKeychain sharedInstance] getLoggedInUserName]]);
    XCTAssertTrue([_password isEqualToString:[[ChuckPadKeychain sharedInstance] getLoggedInPassword]]);
    XCTAssertTrue([_email isEqualToString:[[ChuckPadKeychain sharedInstance] getLoggedInEmail]]);
}

- (void)doPostLogOutAssertChecks {
    XCTAssertFalse([[ChuckPadSocial sharedInstance] isLoggedIn]);

    XCTAssertTrue([[ChuckPadKeychain sharedInstance] getLoggedInUserName] == nil);
    XCTAssertTrue([[ChuckPadKeychain sharedInstance] getLoggedInPassword] == nil);
    XCTAssertTrue([[ChuckPadKeychain sharedInstance] getLoggedInEmail] == nil);
}

@end
