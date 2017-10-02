//
//  ChuckPadServicePatchWorldTests.m
//  hello-chuckpad
//  Created by Mark Cerqueira on 10/1/17.
//

#import "ChuckPadBaseTest.h"

@interface ChuckPadServicePatchWorldTests : ChuckPadBaseTest

@end

@implementation ChuckPadServicePatchWorldTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testGetWorldPatches {
    [self generateLocalUserAndCreate];
    
    ChuckPadPatch *localPatch = [ChuckPadPatch generatePatch:@"chuck-samples-xl" filename:@"adc.ck"];
    NSMutableData *data = [NSMutableData dataWithData:localPatch.fileData];
    
    int latitude = -90;
    int longitude = -180;
    
    // This will upload 180 patches all over the world!
    while (longitude <= 180) {
        // Use "adc.ck" as the base data and append 5 bytes each time so we don't hit the duplicate data check on the service.
        char appendingBytes[4] = { 0x01, 0xf0, 0x64, 0x0 };
        [data appendBytes:appendingBytes length:sizeof(appendingBytes)];
        
        XCTestExpectation *expectation = [self expectationWithDescription:@"uploadPatch timed out"];
        [[ChuckPadSocial sharedInstance] uploadPatch:localPatch.name description:localPatch.patchDescription latitude:@(latitude) longitude:@(longitude) patchData:data extraMetaData:nil callback:^(BOOL succeeded, Patch *patch, NSError *error) {
            XCTAssertTrue(succeeded);
            [expectation fulfill];
        }];
        [self waitForExpectations];
        
        latitude += 1;
        longitude += 2;
    }
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"getWorldPatches timed out"];
    [[ChuckPadSocial sharedInstance] getWorldPatches:^(NSArray *patchesArray, NSError *error) {
        // Cheesy way to check if we found a patch in each of the "regions" we define on the server
        BOOL range1Found, range2Found, range3Found, range4Found, range5Found, range6Found;
        
        for (Patch *patch in patchesArray) {
            XCTAssertTrue([patch hasLocation]);
            
            int patchLongitude = [patch.longitude intValue];
            
            if (patchLongitude >= -180 && patchLongitude <= -120) range1Found = YES;
            else if (patchLongitude >= -120 && patchLongitude <= -60) range2Found = YES;
            else if (patchLongitude >= -60 && patchLongitude <= 0) range3Found = YES;
            else if (patchLongitude >= 0 && patchLongitude <= 60) range4Found = YES;
            else if (patchLongitude >= 60 && patchLongitude <= 120) range5Found = YES;
            else if (patchLongitude >= 120 && patchLongitude <= 180) range6Found = YES;
        }
        
        XCTAssertTrue(range1Found && range2Found && range3Found && range4Found && range5Found && range6Found);

        [expectation fulfill];
    }];
    [self waitForExpectations];
}

@end
