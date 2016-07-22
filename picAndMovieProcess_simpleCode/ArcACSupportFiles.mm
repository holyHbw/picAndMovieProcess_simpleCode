//
//  ArcACSupportFiles.m
//  actionCamera
//
//  Created by samwei12 on 15/12/28.
//  Copyright © 2015年 arcsoft. All rights reserved.
//

#import "ArcACSupportFiles.h"
//#import <XMP/XMP.h>
NSString *kVideoKey   = @"Video";
NSString *kPictureKey = @"Picture";

@interface ArcACSupportFiles ()

@property (nonatomic, strong) NSMutableArray *supportVideoTypes;
@property (nonatomic, strong) NSMutableArray *supportPictureTypes;
@property (nonatomic, strong) NSMutableArray *supportAllTypes;
@end
@implementation ArcACSupportFiles
#pragma mark - Initialization
- (instancetype)init
{
    NSAssert(1, @"Please use sharedInstance");
    return nil;
}

+ (instancetype) sharedInstance {
    static ArcACSupportFiles *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[ArcACSupportFiles alloc] initPrivate];
    });

    return _sharedInstance;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _supportVideoTypes   = [NSMutableArray new];
        _supportPictureTypes = [NSMutableArray new];
        _supportAllTypes     = [NSMutableArray new];
        [self loadSupportFiles];
    }
    return self;
}


#pragma mark - Internal Helpers
- (void)loadSupportFiles {
    NSURL *filePath = [[NSBundle mainBundle] URLForResource:@"supportFiles" withExtension:@"plist"];
    NSDictionary *info = [NSDictionary dictionaryWithContentsOfURL:filePath];

    NSDictionary *videoDic = info[kVideoKey];
    NSDictionary *picDic   = info[kPictureKey];

    [videoDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [_supportVideoTypes addObjectsFromArray:obj];
        [_supportAllTypes addObjectsFromArray:obj];
    }];
    [picDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [_supportPictureTypes addObjectsFromArray:obj];
        [_supportAllTypes addObjectsFromArray:obj];
    }];
}

#pragma mark - Public Methods
- (NSArray *)supportVideoTypes {
    return [_supportVideoTypes copy];
}

- (NSArray *)supportPictureTypes {
    return [_supportPictureTypes copy];
}

- (NSArray *)supportAllTypes {
    return [_supportAllTypes copy];
}

- (ArcACMediaType)checkMediaTypeWithURL:(NSURL *)url {
        // ignore upper case
    NSString *extention = [[url pathExtension] lowercaseString];
    if ([self.supportVideoTypes containsObject:extention]) {
        return ArcACMediaTypeVideo;
    }
    else if ([self.supportPictureTypes containsObject:extention]) {
        return ArcACMediaTypePicture;
    }
    else {
        return ArcACMediaTypeUndefined;
    }
}

- (BOOL)checkXMPMetadataExistWithFileURL:(NSURL *)url {
    //bool res = hasSphereXMPMetadata([url.path UTF8String]);
    //return res;
    return YES;
}
@end
