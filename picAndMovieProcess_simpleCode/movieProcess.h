//
//  movieProcess.h
//  picAndMovieProcess_simpleCode
//
//  Created by 黄博闻 on 16/7/21.
//  Copyright © 2016年 黄博闻. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface movieProcess : NSObject

@property(nonatomic,copy)NSURL *sourceURL;
@property(nonatomic)NSString *destinationPath;
@property(nonatomic)NSString *destinationDocument;
@property(nonatomic,copy)NSURL *destinationURL;

@property(nonatomic,readonly)AVAsset *sourceAVAsset;
@property(nonatomic,copy)NSDictionary *outputSetting;
@property(nonatomic,copy)NSDictionary *inputSetting;
@property(nonatomic)AVAssetReader *assetReader;
@property(nonatomic)AVAssetReaderTrackOutput *assetReaderTrackOutput;
@property(nonatomic)AVAssetWriter *assetWriter;
@property(nonatomic)AVAssetWriterInput *assetWriterInput;
@property(nonatomic,readonly)CMSampleBufferRef sampleBuffer;
@property(nonatomic)NSImage *testImage;
@property(nonatomic)AVAssetWriterInputPixelBufferAdaptor *p_bufferAdaptor;
@property(nonatomic)NSMutableArray *imageArray;
@property(nonatomic)CMTime sourceDuration;

//-(id)initMovieProcessingWithSourceURL:(NSURL *)sourceURL destinationURL:(NSURL *)destinationURL outputSetting:(NSDictionary *)outputSetting inputSetting:(NSDictionary *)inputSetting;
-(id)initMovieProcessingWithSourceURL:(NSURL *)sourceURL outputSetting:(NSDictionary *)outputSetting inputSetting:(NSDictionary *)inputSetting;

-(void)dumpFileQuickly:(void *)baseAddress bytesPerRow:(size_t)bytesPerRow height:(size_t)height index:(int)index;
-(void)dumpFromTheSampleBuffer:(CMSampleBufferRef)sampleBuffer pixelBuffer:(CVImageBufferRef)imageBuffer index:(int)index; //test
-(void)dumpFromTheSampleBuffer:(CMSampleBufferRef)sampleBuffer index:(int)index;

-(void)dumpJPEGFile:(NSString *)storePath fileType:(NSString *)fileType baseAddress:(void *)baseAddress bytesPerRow:(size_t)bytesPerRow fileWidth:(size_t)width fileHeight:(size_t)height CVImageBufferRef:(CVImageBufferRef)imageBuffer index:(int)index;

-(NSData *)getRawDataFromCMSampleBuffer:(CMSampleBufferRef)sampleBuffer pixelBuffer:(CVImageBufferRef)imageBuffer;//test
-(NSData *)getRawDataFromCMSampleBuffer:(CMSampleBufferRef)sampleBuffer;

-(CVImageBufferRef)createNewPixelBufferFromData:(NSData *)data copyToImageBuffer:(CVImageBufferRef)imageBuffer;

-(void)convertNSDataToNSImage:(NSData *)nsData;

-(void)movieProcessing:(BOOL)useEngineOrNot;

- (void) createMovieFromSource:(NSArray *)images;
- (CVPixelBufferRef)newPixelBufferFromCGImage:(CGImageRef)image;

@end
