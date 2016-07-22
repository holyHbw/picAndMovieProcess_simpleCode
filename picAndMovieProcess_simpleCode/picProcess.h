//
//  picProcess.h
//  picAndMovieProcess_simpleCode
//
//  Created by 黄博闻 on 16/7/21.
//  Copyright © 2016年 黄博闻. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface picProcess : NSObject
@property(nonatomic)NSURL *sourceURL;
@property(nonatomic)NSURL *destinationURL;

@property(nonatomic)NSString *destinationPath;
@property(nonatomic)NSString *destinationDocument;

//-(instancetype)initWithSourceURL:(NSURL *)sourceURL andDestinationURl:(NSURL *)destinationURL destinationPath:(NSString *)str;
-(instancetype)initWithSourceURL:(NSURL *)sourceURL;

-(void *)decodePic:(NSImage *)image;

-(void)saveToJPG:(void *)pointer;

-(void)picProcessing;

-(unsigned char *)convertSourceImageToBitmapRGBA:(NSImage *)image;

-(void)convertBitmapToDestinationWithPionter:(unsigned char *)pointer;

- (CGContextRef) newBitmapRGBA8ContextFromImage:(CGImageRef) image;

//供自己测试用
-(void)dumpTheRawdataToDestination:(NSString *)str pointer:(unsigned char*)pointer;
@end
