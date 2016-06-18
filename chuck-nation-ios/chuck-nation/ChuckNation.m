//
//  ChuckNation.m
//  chuck-nation-ios
//
//  Created by Mark Cerqueira on 6/17/16.
//
//

#import <Foundation/Foundation.h>
#import "ChuckNation.h"
#import "AFHTTPSessionManager.h"
#import "Patch.h"

@implementation ChuckNation {

    @private
    AFHTTPSessionManager *httpSessionManager;
}

NSString *const CHUCK_NATION_BASE_URL = @"https://chuck-nation.herokuapp.com/";

NSString *const GET_DOCUMENTATION_URL = @"patch/json/documentation";
NSString *const GET_FEATURED_URL = @"patch/json/featured";
NSString *const GET_ALL_URL = @"patch/json/all";

+ (ChuckNation *)sharedInstance {
    static ChuckNation *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ChuckNation alloc] init];
        [sharedInstance initializeNetworkManager];
    });
    return sharedInstance;
}

- (void)initializeNetworkManager {
    httpSessionManager = [AFHTTPSessionManager manager];
}

- (void)getDocumentationPatches:(GetPatchesCallback)callback {
    [self getPatchesInternal:GET_DOCUMENTATION_URL withCallback:callback];
}

- (void)getFeaturedPatches:(GetPatchesCallback)callback {
    [self getPatchesInternal:GET_FEATURED_URL withCallback:callback];
}

- (void)getAllPatches:(GetPatchesCallback)callback {
    [self getPatchesInternal:GET_ALL_URL withCallback:callback];
}

- (void)getPatchesInternal:(NSString *)urlPath withCallback:(GetPatchesCallback)callback {
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", CHUCK_NATION_BASE_URL, urlPath]];

    [httpSessionManager GET:url.absoluteString parameters:nil progress:nil
         success:^(NSURLSessionTask *task, id responseObject) {
             NSMutableArray *patchesArray = [[NSMutableArray alloc] init];

             for (id object in responseObject) {
                 Patch *patch = [[Patch alloc] initWithDictionary:object];
                 // NSLog(@"Patch: %@", patch.description);
                 [patchesArray addObject:patch];
             }

             callback(patchesArray, nil);
         }
         failure:^(NSURLSessionTask *operation, NSError *error) {
             callback(nil, error);
         }];
}

@end