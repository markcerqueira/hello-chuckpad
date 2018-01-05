//
//  ChuckPadServiceLiveTests.m
//  hello-chuckpad
//
//  Created by Mark Cerqueira on 1/3/18.
//

#import "ChuckPadBaseTest.h"

@interface ChuckPadServiceLiveTests : ChuckPadBaseTest

@end

@implementation ChuckPadServiceLiveTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testCreateLiveSession {
    ChuckPadUser *user = [self generateLocalUserAndCreate];
    
    // Create a new live session
    XCTestExpectation *expectation = [self expectationWithDescription:@"createLiveSession timed out"];
    [[ChuckPadSocial sharedInstance] createLiveSession:@"My First Live Session" callback:^(BOOL succeeded, LiveSession *liveSession, NSError *error) {
        XCTAssertTrue(succeeded);
        XCTAssertTrue([liveSession isSessionOpen]);
        XCTAssertFalse([liveSession isSessionClosed]);
        XCTAssertEqual(liveSession.creatorID, user.userId);
        XCTAssertTrue([liveSession.creatorUsername isEqualToString:user.username]);
        XCTAssertTrue([liveSession.sessionTitle isEqualToString:@"My First Live Session"]);

        [expectation fulfill];
    }];
    [self waitForExpectations];
}

- (void)testCloseLiveSession {
    [self generateLocalUserAndCreate];
    
    // Create a new live session and hold onto it so we can close it later
    __block LiveSession *myLiveSession = nil;
    XCTestExpectation *expectation = [self expectationWithDescription:@"createLiveSession timed out"];
    [[ChuckPadSocial sharedInstance] createLiveSession:@"LiveSession710" callback:^(BOOL succeeded, LiveSession *liveSession, NSError *error) {
        XCTAssertTrue(succeeded);
        XCTAssertTrue([liveSession isSessionOpen]);
        XCTAssertFalse([liveSession isSessionClosed]);
        myLiveSession = liveSession;
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    // Close that live session
    expectation = [self expectationWithDescription:@"closeLiveSession timed out"];
    [[ChuckPadSocial sharedInstance] closeLiveSession:myLiveSession callback:^(BOOL succeeded, LiveSession *liveSession, NSError *error) {
        XCTAssertTrue(succeeded);
        XCTAssertFalse([liveSession isSessionOpen]);
        XCTAssertTrue([liveSession isSessionClosed]);

        [expectation fulfill];
    }];
    [self waitForExpectations];
}

@end
