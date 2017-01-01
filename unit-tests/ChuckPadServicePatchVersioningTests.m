//
//  ChuckPadServicePatchVersioningTests.m
//  hello-chuckpad
//  Created by Mark Cerqueira on 12/31/16.
//

#import "ChuckPadBaseTest.h"

@interface ChuckPadServicePatchVersioningTests : ChuckPadBaseTest

@end

@implementation ChuckPadServicePatchVersioningTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testGetVersions {
    [self generateLocalUserAndCreate];
    
    ChuckPadPatch *localPatch = [self generatePatchAndUpload:YES];
    __block PatchResource *patchResource = nil;
    __block NSData *patchVersionData = nil;
    __block NSData *patchResourceData = nil;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"getPatchVersions timed out"];
    [[ChuckPadSocial sharedInstance] getPatchVersions:localPatch.lastServerPatch callback:^(BOOL succeeded, NSArray *versions, NSError *error) {
        XCTAssertTrue(succeeded);
        XCTAssertTrue(error == nil);
        XCTAssertTrue([versions count] == 1);
        
        patchResource = [versions objectAtIndex:0];
        
        [expectation fulfill];
    }];
    [self waitForExpectations];

    // Our patch only has one resource associated with it. Download it both ways (traditional download data and download
    // particular version of a patch resource) and they should match exactly.
    
    expectation = [self expectationWithDescription:@"downloadPatchVersion timed out"];
    [[ChuckPadSocial sharedInstance] downloadPatchVersion:localPatch.lastServerPatch version:patchResource.version callback:^(NSData *resourceData, NSError *error) {
        patchVersionData = resourceData;
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    expectation = [self expectationWithDescription:@"downloadPatchResource timed out"];
    [[ChuckPadSocial sharedInstance] downloadPatchResource:localPatch.lastServerPatch callback:^(NSData *resourceData, NSError *error) {
        patchResourceData = resourceData;
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    XCTAssertTrue([localPatch.fileData isEqualToData:patchVersionData]);
    XCTAssertTrue([localPatch.fileData isEqualToData:patchResourceData]);
    XCTAssertTrue([patchVersionData isEqualToData:patchResourceData]);
}

- (void)testGetVersionsForUpdatedPatch {
    [self generateLocalUserAndCreate];
    
    ChuckPadPatch *localPatch = [self generatePatchAndUpload:YES];
    
    for (int i = 0; i < 5; i++) {
        ChuckPadPatch *newPatch = [ChuckPadPatch generatePatch];

        XCTestExpectation *expectation = [self expectationWithDescription:@"updatePatch timed out"];
        [[ChuckPadSocial sharedInstance] updatePatch:localPatch.lastServerPatch hidden:nil name:nil description:nil patchData:newPatch.fileData extraMetaData:nil callback:^(BOOL succeeded, Patch *patch, NSError *error) {
            XCTAssertTrue(succeeded);
            
            [expectation fulfill];
        }];
        [self waitForExpectations];
        
        expectation = [self expectationWithDescription:@"getPatchVersions timed out"];
        [[ChuckPadSocial sharedInstance] getPatchVersions:localPatch.lastServerPatch callback:^(BOOL succeeded, NSArray *versions, NSError *error) {
            XCTAssertTrue(succeeded);
            XCTAssertTrue(error == nil);
            XCTAssertTrue([versions count] == (i + 2));
            
            // First element in the list is the most recent patch.
            PatchResource *patchResource = [versions objectAtIndex:0];
            [[ChuckPadSocial sharedInstance] downloadPatchVersion:localPatch.lastServerPatch version:patchResource.version callback:^(NSData *resourceData, NSError *error) {
                XCTAssertTrue([resourceData isEqualToData:newPatch.fileData]);
                [expectation fulfill];
            }];
        }];
        [self waitForExpectations];
    }
}

- (void)testGetVersionsOnBadGUID {
    Patch *patch = [[Patch alloc] init];
    patch.guid = [self randomStringWithLength:20];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"getPatchVersions timed out"];
    [[ChuckPadSocial sharedInstance] getPatchVersions:patch callback:^(BOOL succeeded, NSArray *versions, NSError *error) {
        XCTAssertFalse(succeeded);
        XCTAssertTrue(error != nil);
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
}

- (void)testGetVersionResourceWithBadGUID {
    Patch *patch = [[Patch alloc] init];
    patch.guid = [self randomStringWithLength:20];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"downloadPatchVersion timed out"];
    [[ChuckPadSocial sharedInstance] downloadPatchVersion:patch version:0 callback:^(NSData *resourceData, NSError *error) {
        XCTAssertTrue(resourceData == nil);
        XCTAssertTrue(error != nil);
        
        [expectation fulfill];
    }];
    [self waitForExpectations];
}

- (void)testGetVersionResourceBeyondLatestVersion {
    [self generateLocalUserAndCreate];
    
    ChuckPadPatch *localPatch = [self generatePatchAndUpload:YES];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"downloadPatchVersion timed out"];
    [[ChuckPadSocial sharedInstance] downloadPatchVersion:localPatch.lastServerPatch version:0 callback:^(NSData *resourceData, NSError *error) {
        XCTAssertTrue(resourceData != nil);
        [expectation fulfill];
    }];
    [self waitForExpectations];
    
    // Version 1 will not exist because we've only uploaded one version
    expectation = [self expectationWithDescription:@"downloadPatchVersion timed out"];
    [[ChuckPadSocial sharedInstance] downloadPatchVersion:localPatch.lastServerPatch version:1 callback:^(NSData *resourceData, NSError *error) {
        XCTAssertTrue(resourceData == nil);
        [expectation fulfill];
    }];
    [self waitForExpectations];
}

- (void)testGetVersionsOnDeletedPatch {
    [self generateLocalUserAndCreate];
    
    ChuckPadPatch *localPatch = [self generatePatchAndUpload:YES];
    
    [self deletePatch:localPatch];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"getPatchVersions timed out"];
    [[ChuckPadSocial sharedInstance] getPatchVersions:localPatch.lastServerPatch callback:^(BOOL succeeded, NSArray *versions, NSError *error) {
        XCTAssertFalse(succeeded);
        [expectation fulfill];
    }];
    [self waitForExpectations];
}

- (void)testDownloadVersionOnDeletedPatch {
    [self generateLocalUserAndCreate];
    
    ChuckPadPatch *localPatch = [self generatePatchAndUpload:YES];
    
    [self deletePatch:localPatch];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"getPatchVersions timed out"];
    [[ChuckPadSocial sharedInstance] downloadPatchVersion:localPatch.lastServerPatch version:0 callback:^(NSData *resourceData, NSError *error) {
        XCTAssertTrue(resourceData == nil);
        XCTAssertTrue(error != nil);
        [expectation fulfill];
    }];
    [self waitForExpectations];
}

@end
