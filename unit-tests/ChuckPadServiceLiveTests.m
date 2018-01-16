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
    [[ChuckPadSocial sharedInstance] createLiveSession:@"My First Live Session" sessionData:nil callback:^(BOOL succeeded, LiveSession *liveSession, NSError *error) {
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

- (void)testCreateLiveSessionWithData {
    [self generateLocalUserAndCreate];
    
    NSString *folderPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"chuck-samples"];
    NSData *data = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", folderPath, @"adc.ck"]];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"createLiveSession timed out"];
    [[ChuckPadSocial sharedInstance] createLiveSession:@"My First Data" sessionData:data callback:^(BOOL succeeded, LiveSession *liveSession, NSError *error) {
        XCTAssertTrue(succeeded);
        XCTAssertTrue([liveSession.sessionData isEqualToData:data]);

        [expectation fulfill];
    }];
    [self waitForExpectations];
}

- (void)testCloseLiveSession {
    [self generateLocalUserAndCreate];
    
    // Create a new live session and hold onto it so we can close it later
    __block LiveSession *myLiveSession = nil;
    XCTestExpectation *expectation = [self expectationWithDescription:@"createLiveSession timed out"];
    [[ChuckPadSocial sharedInstance] createLiveSession:@"SessionAboutToClose" sessionData:nil callback:^(BOOL succeeded, LiveSession *liveSession, NSError *error) {
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

- (void)testGetRecentlyCreatedOpenLiveSessions {
    [self generateLocalUserAndCreate];

    // Create a bunch of live sessions
    __block NSMutableSet<NSString *> *liveSessionGUIDSet = [NSMutableSet new];
    for (int i = 0; i < 20; i++) {
        XCTestExpectation *expectation = [self expectationWithDescription:@"createLiveSession timed out"];
        [[ChuckPadSocial sharedInstance] createLiveSession:[self randomStringWithLength:20] sessionData:nil  callback:^(BOOL succeeded, LiveSession *liveSession, NSError *error) {
            [liveSessionGUIDSet addObject:liveSession.sessionGUID];
            [expectation fulfill];
        }];
        [self waitForExpectations];
    }
    
    // Ensure that getRecentlyCreatedOpenLiveSessions all those sessions
    XCTestExpectation *expectation = [self expectationWithDescription:@"getRecentlyCreatedOpenLiveSessions timed out"];
    [[ChuckPadSocial sharedInstance] getRecentlyCreatedOpenLiveSessions:^(BOOL succeeded, NSArray<LiveSession *> *liveSessionsArray, NSError *error) {
        for (LiveSession *liveSession in liveSessionsArray) {
            XCTAssertTrue([liveSession isSessionOpen]);
            XCTAssertTrue([liveSessionGUIDSet containsObject:liveSession.sessionGUID]);
            [liveSessionGUIDSet removeObject:liveSession.sessionGUID];
        }
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
}

- (void)testGetRecentlyCreatedOpenLiveSessionsReturnsOnlyOpenSessions {
    [self generateLocalUserAndCreate];
    
    // Create a bunch of live sessions and close half of them
    __block NSMutableSet<LiveSession *> *sessionsToKeepOpen = [NSMutableSet new];
    __block NSMutableSet<LiveSession *> *sessionsToClose = [NSMutableSet new];
    __block NSMutableSet<NSString *> *sessionGUIDsToClose = [NSMutableSet new];
    for (int i = 0; i < 20; i++) {
        XCTestExpectation *expectation = [self expectationWithDescription:@"createLiveSession timed out"];
        [[ChuckPadSocial sharedInstance] createLiveSession:[self randomStringWithLength:20] sessionData:nil callback:^(BOOL succeeded, LiveSession *liveSession, NSError *error) {
            if (i % 2 == 0) {
                [sessionsToClose addObject:liveSession];
                [sessionGUIDsToClose addObject:liveSession.sessionGUID];
            } else {
                [sessionsToKeepOpen addObject:liveSession];
            }
            
            [expectation fulfill];
        }];
        [self waitForExpectations];
    }
    
    for (LiveSession *sessionToClose in sessionsToClose) {
        XCTestExpectation *expectation = [self expectationWithDescription:@"closeLiveSession timed out"];
        [[ChuckPadSocial sharedInstance] closeLiveSession:sessionToClose callback:^(BOOL succeeded, LiveSession *liveSession, NSError *error) {
            XCTAssertTrue(succeeded);
            
            [expectation fulfill];
        }];
        [self waitForExpectations];
    }
    
    // Ensure that getRecentlyCreatedOpenLiveSessions returns only open sessions
    XCTestExpectation *expectation = [self expectationWithDescription:@"getRecentlyCreatedOpenLiveSessions timed out"];
    [[ChuckPadSocial sharedInstance] getRecentlyCreatedOpenLiveSessions:^(BOOL succeeded, NSArray<LiveSession *> *liveSessionsArray, NSError *error) {
        for (LiveSession *liveSession in liveSessionsArray) {
            XCTAssertTrue([liveSession isSessionOpen]);
            XCTAssertFalse([sessionGUIDsToClose containsObject:liveSession.sessionGUID]);
        }
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
}

    
@end
