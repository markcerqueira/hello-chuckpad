//
//  ChuckNation.h
//  chuck-nation-ios
//
//  Created by Mark Cerqueira on 6/17/16.
//
//

#ifndef ChuckNation_h
#define ChuckNation_h

#import <objc/NSObject.h>

typedef void(^GetPatchesCallback)(NSArray *patchesArray, NSError *error);

@interface ChuckNation : NSObject

+ (ChuckNation *)sharedInstance;

- (void)getDocumentationPatches:(GetPatchesCallback)callback;

- (void)getAllPatches:(GetPatchesCallback)callback;

- (void)getFeaturedPatches:(GetPatchesCallback)callback;

- (void)uploadPatchWithPatchName:(NSString *)patchName isFeatured:(BOOL)isFeatured isDocumentation:(BOOL)isDocumentation filename:(NSString *)filename fileData:(NSData *)fileData;

@end

#endif /* ChuckNation_h */
