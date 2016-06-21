//
//  ChuckPadSocial.h
//  chuckpad-social-ios
//
//  Created by Mark Cerqueira on 6/17/16.
//
//

#ifndef ChuckPadSocial_h
#define ChuckPadSocial_h

#import <objc/NSObject.h>

typedef void(^GetPatchesCallback)(NSArray *patchesArray, NSError *error);

@interface ChuckPadSocial : NSObject

+ (ChuckPadSocial *)sharedInstance;

- (NSString *)getBaseUrl;

- (void)toggleEnvironment;

- (void)getDocumentationPatches:(GetPatchesCallback)callback;

- (void)getAllPatches:(GetPatchesCallback)callback;

- (void)getFeaturedPatches:(GetPatchesCallback)callback;

- (void)uploadPatch:(NSString *)patchName filename:(NSString *)filename fileData:(NSData *)fileData;

- (void)uploadPatch:(NSString *)patchName isFeatured:(BOOL)isFeatured isDocumentation:(BOOL)isDocumentation filename:(NSString *)filename fileData:(NSData *)fileData;

@end

#endif /* ChuckPadSocial_h */
