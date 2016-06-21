//
//  ChuckPadSocial.m
//  chuckpad-social-ios
//
//  Created by Mark Cerqueira on 6/17/16.
//
//

#import <Foundation/Foundation.h>
#import "ChuckPadSocial.h"
#import "AFHTTPSessionManager.h"
#import "Patch.h"

@implementation ChuckPadSocial {

    @private
    AFHTTPSessionManager *httpSessionManager;
    NSString *baseUrl;
}

NSString *const CHUCK_PAD_SOCIAL_BASE_URL = @"https://chuckpad-social.herokuapp.com";
NSString *const CHUCK_PAD_SOCIAL_DEV_BASE_URL = @"http://localhost:9292";

NSString *const GET_DOCUMENTATION_URL = @"/patch/json/documentation";
NSString *const GET_FEATURED_URL = @"/patch/json/featured";
NSString *const GET_ALL_URL = @"/patch/json/all";

NSString *const CREATE_PATCH_URL = @"/patch/create_patch/";

+ (ChuckPadSocial *)sharedInstance {
    static ChuckPadSocial *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ChuckPadSocial alloc] init];
        [sharedInstance initializeNetworkManager];
    });
    return sharedInstance;
}

- (void)initializeNetworkManager {
    httpSessionManager = [AFHTTPSessionManager manager];
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"debugEnvironment"]) {
        baseUrl = CHUCK_PAD_SOCIAL_DEV_BASE_URL;
    } else {
        baseUrl = CHUCK_PAD_SOCIAL_BASE_URL;
    }
}

- (NSString *)getBaseUrl {
    return baseUrl;
}

- (void)toggleEnvironment {
    BOOL isDebugEnvironment;
    if ([baseUrl isEqualToString:CHUCK_PAD_SOCIAL_BASE_URL]) {
        baseUrl = CHUCK_PAD_SOCIAL_DEV_BASE_URL;
        isDebugEnvironment = YES;
    } else {
        baseUrl = CHUCK_PAD_SOCIAL_BASE_URL;
        isDebugEnvironment = NO;
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:isDebugEnvironment forKey:@"debugEnvironment"];
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
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", baseUrl, urlPath]];

    NSLog(@"getPatchesInternal: %@", url.absoluteString);
    
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

NSString *const FILE_DATA_PARAM_NAME = @"patch[data]";
NSString *const FILE_DATA_MIME_TYPE = @"application/octet-stream";

- (void)uploadPatchWithPatchName:(NSString *)patchName isFeatured:(BOOL)isFeatured isDocumentation:(BOOL)isDocumentation
                        filename:(NSString *)filename fileData:(NSData *)fileData {
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", baseUrl, CREATE_PATCH_URL]];

    NSLog(@"uploadPatchWithPatchName: %@", url.absoluteString);
    
    NSMutableDictionary *requestParams = [[NSMutableDictionary alloc] init];

    if (patchName != nil) {
        [requestParams setObject:patchName forKey:@"patch[name]"];
    }

    if (isFeatured) {
        [requestParams setObject:@"1" forKey:@"patch[featured]"];
    }

    if (isDocumentation) {
        [requestParams setObject:@"1" forKey:@"patch[documentation]"];
    }

    [httpSessionManager POST:url.absoluteString parameters:requestParams constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:fileData
                                    name:FILE_DATA_PARAM_NAME
                                fileName:filename
                                mimeType:FILE_DATA_MIME_TYPE];
    } progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"Response: %@", responseObject);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}


@end