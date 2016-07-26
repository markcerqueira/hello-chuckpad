//
//  ChuckPadEnvironmentTest.m
//  chuckpad-social-ios-test
//
//  Created by Mark Cerqueira on 7/25/16.
//
//

#import <XCTest/XCTest.h>

#import "ChuckPadKeychain.h"
#import "ChuckPadSocial.h"

@interface ChuckPadEnvironmentTest : XCTestCase

@end

@implementation ChuckPadEnvironmentTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testToggleEnvironmentUrl {
    NSString *url = [[ChuckPadSocial sharedInstance] getBaseUrl];
    
    [[ChuckPadSocial sharedInstance] toggleEnvironment];

    NSString *toggledUrl = [[ChuckPadSocial sharedInstance] getBaseUrl];
    
    XCTAssertFalse([url isEqualToString:toggledUrl], @"Base URL did not change after toggle environment call");
}

- (void)testCreateUser {
    [[ChuckPadSocial sharedInstance] setEnvironmentToDebug];
    [[ChuckPadSocial sharedInstance] logOut];

    XCTestExpectation *expectation = [self expectationWithDescription:@"testCreateUser timed out"];
    
    NSString *username = [[[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@"iOS"] substringToIndex:18];
    NSString *password = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    NSString *email = [NSString stringWithFormat:@"%@@%@.com", username, username];
    
    [[ChuckPadSocial sharedInstance] createUser:username withEmail:email withPassword:password withCallback:^(BOOL succeeded, NSError *error) {
        XCTAssertTrue(succeeded);
        
        XCTAssertTrue([[ChuckPadSocial sharedInstance] isLoggedIn]);
        
        XCTAssertTrue([username isEqualToString:[[ChuckPadSocial sharedInstance] getLoggedInUserName]]);

        XCTAssertTrue([username isEqualToString:[[ChuckPadKeychain sharedInstance] getLoggedInUserName]]);
        XCTAssertTrue([password isEqualToString:[[ChuckPadKeychain sharedInstance] getLoggedInPassword]]);
        XCTAssertTrue([email isEqualToString:[[ChuckPadKeychain sharedInstance] getLoggedInEmail]]);

        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"testCreateUser - error: %@", error);
        }
    }];
}

@end
