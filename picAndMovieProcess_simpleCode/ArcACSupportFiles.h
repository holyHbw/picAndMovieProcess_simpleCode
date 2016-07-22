//
//  ArcACSupportFiles.h
//  actionCamera
//
//  Created by samwei12 on 15/12/28.
//  Copyright © 2015年 arcsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger) {
    ArcACMediaTypeUndefined,
    ArcACMediaTypeVideo,
    ArcACMediaTypePicture,
}ArcACMediaType;

typedef NS_ENUM(NSUInteger){
    ArcACVRInfoTypeNormal,
    ArcACVRInfoTypeUnstitched,
    ArcACVRInfoTypeStitched,
} ArcACVRInfoType;

static float kMaxZoomScale = 4.0f;
static float kMinZoomScale = 0.5f;

@interface ArcACSupportFiles : NSObject

+ (instancetype)sharedInstance;

- (NSArray *)supportVideoTypes;
- (NSArray *)supportPictureTypes;
/**
 *  @author samwei12, 16-12-28 11:12:09
 *
 *  All support types,
 *
 */
- (NSArray *)supportAllTypes;

/**
 *  @author samwei12, 16-12-28 11:12:19
 *
 *  check file type
 *
 *  @param url input url
 *
 *  @return media type
 */
- (ArcACMediaType)checkMediaTypeWithURL:(NSURL *)url;
/**
 *  @author samwei12, 16-01-29 10:01:38
 *
 *  check image has sphere info or not
 */
- (BOOL)checkXMPMetadataExistWithFileURL:(NSURL *)url;
@end