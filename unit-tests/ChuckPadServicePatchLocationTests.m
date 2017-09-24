//
//  ChuckPadServicePatchLocationTests.m
//  hello-chuckpad
//  Created by Mark Cerqueira on 9/22/16.
//

#import "ChuckPadBaseTest.h"

@interface ChuckPadServicePatchLocationTests : ChuckPadBaseTest

@end

@implementation ChuckPadServicePatchLocationTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testPatchWithLocation {
    [self generateLocalUserAndCreate];
    
    // Upload a new patch with location set and verify
    ChuckPadPatch *localPatch = [ChuckPadPatch generatePatch];
    XCTestExpectation *expectation = [self expectationWithDescription:@"uploadPatch timed out"];
    [[ChuckPadSocial sharedInstance] uploadPatch:localPatch.name description:localPatch.patchDescription latitude:localPatch.latitude longitude:localPatch.longitude patchData:localPatch.fileData extraMetaData:nil callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertTrue(succeeded);
        
        XCTAssertTrue(fabs(localPatch.latitude.floatValue - patch.latitude.floatValue) <= 1.0);
        XCTAssertTrue(fabs(localPatch.longitude.floatValue - patch.longitude.floatValue) <= 1.0);

        [expectation fulfill];
    }];
    [self waitForExpectations];
}

- (void)testPatchWithoutLocation {
    [self generateLocalUserAndCreate];
    
    // Upload a new patch with location unset
    ChuckPadPatch *localPatch = [ChuckPadPatch generatePatch];
    XCTestExpectation *expectation = [self expectationWithDescription:@"uploadPatch timed out"];
    [[ChuckPadSocial sharedInstance] uploadPatch:localPatch.name description:localPatch.patchDescription latitude:nil longitude:nil patchData:localPatch.fileData extraMetaData:nil callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertTrue(succeeded);
        
        XCTAssertTrue(patch.latitude == nil);
        XCTAssertTrue(patch.longitude == nil);
                
        [expectation fulfill];
    }];
    [self waitForExpectations];
}

- (void)testPatchUpdateWithLocation {
    [self generateLocalUserAndCreate];
    
    // Upload a new patch with location set and verify
    ChuckPadPatch *localPatch = [ChuckPadPatch generatePatch];
    XCTestExpectation *expectation = [self expectationWithDescription:@"uploadPatch timed out"];
    [[ChuckPadSocial sharedInstance] uploadPatch:localPatch.name description:localPatch.patchDescription latitude:localPatch.latitude longitude:localPatch.longitude patchData:localPatch.fileData extraMetaData:nil callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertTrue(succeeded);
        
        XCTAssertTrue(fabs(localPatch.latitude.floatValue - patch.latitude.floatValue) <= 1.0);
        XCTAssertTrue(fabs(localPatch.longitude.floatValue - patch.longitude.floatValue) <= 1.0);
        
        localPatch.lastServerPatch = patch;
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    // Update the location to new coordinates and verify
    expectation = [self expectationWithDescription:@"updatePatch timed out"];
    [[ChuckPadSocial sharedInstance] updatePatch:localPatch.lastServerPatch latitude:@42.7 longitude:@(-42.2) callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertTrue(succeeded);
        
        XCTAssertTrue(patch.latitude.integerValue == 43);
        XCTAssertTrue(patch.longitude.integerValue == -42);

        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    // Clear the location and verify
    expectation = [self expectationWithDescription:@"updatePatch timed out"];
    [[ChuckPadSocial sharedInstance] updatePatch:localPatch.lastServerPatch latitude:nil longitude:nil callback:^(BOOL succeeded, Patch *patch, NSError *error) {
        XCTAssertTrue(succeeded);
        
        XCTAssertFalse([patch hasLocation]);
        XCTAssertTrue(patch.latitude == nil);
        XCTAssertTrue(patch.longitude == nil);
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
}

@end
