//
//  ChuckPadServiceStressTests.m
//  hello-chuckpad
//  Created by Mark Cerqueira on 1/1/17.
//

#import "ChuckPadBaseTest.h"

@interface ChuckPadServiceStressTests : ChuckPadBaseTest

@end

@implementation ChuckPadServiceStressTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testGetPatchesWithManyPatches {
    ChuckPadUser *user = [self generateLocalUserAndCreate];
    
    ChuckPadPatch *localPatch = [ChuckPadPatch generatePatch:@"chuck-samples-xl" filename:@"adc.ck"];
    NSMutableData *data = [NSMutableData dataWithData:localPatch.fileData];
    
    NSInteger PATCHES_TO_UPLOAD = 500;
    
    for (int i = 0; i < PATCHES_TO_UPLOAD; i++) {
        // Use "adc.ck" as the base data and append 5 bytes each time so we don't hit the duplicate data check on the service.
        char appendingBytes[4] = { 0x01, 0xf0, 0x64, 0x0 };
        [data appendBytes:appendingBytes length:sizeof(appendingBytes)];
        
        XCTestExpectation *expectation = [self expectationWithDescription:@"uploadPatch timed out"];
        [[ChuckPadSocial sharedInstance] uploadPatch:localPatch.name description:localPatch.patchDescription parent:nil patchData:data extraMetaData:nil callback:^(BOOL succeeded, Patch *patch, NSError *error) {
            XCTAssertTrue(succeeded);
            [expectation fulfill];
        }];
        [self waitForExpectations];
    }
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"getMyPatches timed out"];
    [[ChuckPadSocial sharedInstance] getMyPatches:^(NSArray *patchesArray, NSError *error) {
        XCTAssertTrue(patchesArray != nil);
        XCTAssertTrue([patchesArray count] == PATCHES_TO_UPLOAD);
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    expectation = [self expectationWithDescription:@"getPatchesForUserId timed out"];
    [[ChuckPadSocial sharedInstance] getPatchesForUserId:user.userId callback:^(NSArray *patchesArray, NSError *error) {
        XCTAssertTrue(patchesArray != nil);
        XCTAssertTrue([patchesArray count] == PATCHES_TO_UPLOAD);
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
}

@end
