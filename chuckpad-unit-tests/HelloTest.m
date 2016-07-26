//
//  HelloTest.m
//  chuckpad-social-ios-test
//
//  Created by Mark Cerqueira on 7/25/16.
//
//

#import <XCTest/XCTest.h>

#import "ChuckPadSocial.h"

@interface HelloTest : XCTestCase

@end

@implementation HelloTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    NSLog(@"teardown");
}

- (void)testToggleEnvironmentUrl {
    NSString *url = [[ChuckPadSocial sharedInstance] getBaseUrl];
    
    [[ChuckPadSocial sharedInstance] toggleEnvironment];

    NSString *toggledUrl = [[ChuckPadSocial sharedInstance] getBaseUrl];
    
    XCTAssertFalse([url isEqualToString:toggledUrl], @"Base URL did not change after toggle environment call");
}

- (void)testCreateUser {
    XCTAssertTrue(true);
}

@end
