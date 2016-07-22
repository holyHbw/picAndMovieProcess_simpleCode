//
//  movieProcess.m
//  picAndMovieProcess_simpleCode
//
//  Created by 黄博闻 on 16/7/21.
//  Copyright © 2016年 黄博闻. All rights reserved.
//

#import "movieProcess.h"

@implementation movieProcess
{
    size_t _width;
    size_t _height;
    size_t _bytesPerRow;
    BOOL test;
}

-(id)initMovieProcessingWithSourceURL:(NSURL *)sourceURL outputSetting:(NSDictionary *)outputSetting inputSetting:(NSDictionary *)inputSetting
{
    if (self = [super init]) {
        _imageArray = [[NSMutableArray alloc]init];
        _sourceURL = sourceURL;
        _outputSetting = outputSetting;
        _inputSetting = inputSetting;
        test = YES;
        
        //specify the destination store path
        NSArray *arr1 = [[_sourceURL absoluteString] componentsSeparatedByString:@"/"];
        NSString *filename = [arr1 lastObject];
        NSString *_filename = [@"/" stringByAppendingString:filename];
        NSArray *arr2 = [[_sourceURL absoluteString] componentsSeparatedByString:_filename];
        _destinationDocument= [arr2 objectAtIndex:0];
        //_destinationPath = [[NSURL URLWithString:[[_destinationDocument stringByAppendingPathComponent:@"new_jpg.jpg"] substringFromIndex:5]] absoluteString];
        
        //specify the destinationURL
        _destinationURL = [NSURL fileURLWithPath:[[_destinationDocument stringByAppendingPathComponent:@"new.mp4"] substringFromIndex:5]];

        
        //create a assetReader
        NSDictionary *inputOptions = @{
                                       AVURLAssetPreferPreciseDurationAndTimingKey : @YES,
                                       /*AVURLAssetReferenceRestrictionsKey:@YES*/
                                       };
        _sourceAVAsset = [[AVURLAsset alloc]initWithURL:_sourceURL options:inputOptions];
        _sourceDuration = _sourceAVAsset.duration;
        
        NSError *error1 = nil;
        _assetReader = [AVAssetReader assetReaderWithAsset:_sourceAVAsset error:&error1];
        
        NSArray *tracks = [_sourceAVAsset tracksWithMediaType:AVMediaTypeVideo];
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        
        _assetReaderTrackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:_outputSetting];
        [_assetReader addOutput:_assetReaderTrackOutput];
        
        //create a assetWriter
        NSError *error2 = nil;
        _assetWriter = [[AVAssetWriter alloc] initWithURL:_destinationURL fileType:AVFileTypeMPEG4 error:&error2];
        
        _assetWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:inputSetting];

        [_assetWriter addInput:_assetWriterInput];
        
        return self;
    }
    NSLog(@"movieProcessing::initMovieProcessingWithSourceURL: fail to init movieProcessing!");
    return  nil;
}


-(void)movieProcessing:(BOOL)useEngineOrNot
{
    NSLog(@"movieProcessing::movieProcessing");
    NSLog(@"useEngineOrNot:%c",useEngineOrNot);
    
    //useEngineOrNot == YES means use engine
    if (useEngineOrNot == YES){
        
        [_assetReader startReading];
        [_assetWriter startWriting];
        
        dispatch_queue_t queue = dispatch_get_main_queue();
        
        if (_assetWriterInput) {
            __block NSInteger count = 1;
            __block BOOL isComplete = NO;
            
            //start writing with the begining time of session
            [_assetWriter startSessionAtSourceTime:kCMTimeZero];
            [_assetWriterInput requestMediaDataWhenReadyOnQueue:queue usingBlock:^{
                if (!isComplete && _assetWriterInput.readyForMoreMediaData)
                {
                    //take the CMSampleBuffer from the assetReadertrackOutput
                    CMSampleBufferRef buffer = [_assetReaderTrackOutput copyNextSampleBuffer];
                    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(buffer);
                    
                    // lock the pixelBufferAddress
                    CVPixelBufferLockBaseAddress(imageBuffer, 0);
                    
#pragma self_defination_of_the_use_of_CMSamleBuffer_here
                    //provide the baseAddress pointer for the ArcEngine to stitch the image
                    unsigned char *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
                    _bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
                    _width = CVPixelBufferGetWidth(imageBuffer);
                    _height = CVPixelBufferGetHeight(imageBuffer);
                    
                    //ArcEngine do process
                    //...write you code here...//
                    //ArcEngine do process
                    
                    //dump the rgb file
                    if (count%100 == 0) {
                        [self dumpFileQuickly:baseAddress bytesPerRow:_bytesPerRow height:_height index:(int)(count/100)];
                    }
                    
#pragma self_defination_of_the_use_of_CMSamleBuffer_here
                    //unlock the pixelBuffer baseAddress
                    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
                    
                    if (buffer){
                        [_assetWriterInput appendSampleBuffer:buffer];
                        count++;
                    }
                    else
                    {
                        isComplete = YES;
                    }
                    
                    if(isComplete)
                    {
                        //close the writer
                        [_assetWriter finishWritingWithCompletionHandler:^{
                            
                            AVAssetWriterStatus status = _assetWriter.status;
                            if (status == AVAssetWriterStatusCompleted)
                                NSLog(@"movieProcessing::movieProcessing: finsish processing!");
                            else
                                NSLog(@"movieProcessing::movieProcessing: failed processing!");
                        }];
                    }
                }
            }];
        }

    }else{
        
        //
        
    }//end if, the processing is over
}

-(void)writeNSData:(uint8_t *)dataPointer ToImageBuffer:(uint8_t *)baseAddress
{
    for (int i=0; i<_bytesPerRow*_height; i++) {
        *(baseAddress++) = *(dataPointer++);
    }
}

-(CVImageBufferRef)createNewPixelBufferFromData:(NSData *)data copyToImageBuffer:(CVImageBufferRef)imageBuffer
{
    void *dataPointer = (void *)data.bytes;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    /*CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width,
     frameSize.height, kCVPixelFormatType_32ARGB, (CFDictionaryRef) options,
     &pxbuffer);*/
    CVPixelBufferRef tempPixelBuffer = NULL;
    CVPixelBufferCreateWithBytes(kCFAllocatorDefault, _width, _height, kCVPixelFormatType_32BGRA, dataPointer, _bytesPerRow, nil, nil, (__bridge CFDictionaryRef) options, &tempPixelBuffer);
    
    return tempPixelBuffer;
}

-(void)dumpFileQuickly:(void *)baseAddress bytesPerRow:(size_t)bytesPerRow height:(size_t)height index:(int)index
{
    NSString *storePath3 = [[NSURL URLWithString:[[_destinationDocument stringByAppendingPathComponent:[NSString stringWithFormat:@"%d_%zux%zu.rgb32",index,_width,_height]] substringFromIndex:5]] absoluteString];
    //NSString *storePath4 = [NSString stringWithFormat:@"/Users/hbw/Desktop/about ios/理论学习/workspace/hbw-ios开发/aboutAVFoundation/dump/%d_2560x1280.rgb32",index];
    NSData *Data = [NSData dataWithBytes:baseAddress length:_bytesPerRow*_height];
    [Data writeToFile:storePath3 atomically:YES];
}

-(void)dumpFromTheSampleBuffer:(CMSampleBufferRef)sampleBuffer pixelBuffer:(CVImageBufferRef)imageBuffer index:(int)index
{
    //get the baseAddress of CVPixelBuffer
    uint8_t *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // bytesPerRow
    _bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    _width = CVPixelBufferGetWidth(imageBuffer);
    _height = CVPixelBufferGetHeight(imageBuffer);
    
    //1.dump a jpg file to the destination path
    NSString *fileStorePath = @"/Users/hbw/Desktop/about ios/理论学习/workspace/hbw-ios开发/aboutAVFoundation/dump";
    NSString *fileType = @"jpg";
    [self dumpJPEGFile:fileStorePath fileType:fileType baseAddress:baseAddress bytesPerRow:_bytesPerRow fileWidth:_width fileHeight:_height CVImageBufferRef:imageBuffer index:index];
    
    //2.dump a rgb32 file to the destination path
    NSString *storePath4 = [NSString stringWithFormat:@"/Users/hbw/Desktop/about ios/理论学习/workspace/hbw-ios开发/aboutAVFoundation/dump/%d_2560x1280.rgb32",index];
    NSData *Data = [NSData dataWithBytes:baseAddress length:_bytesPerRow*_height];
    [Data writeToFile:storePath4 atomically:YES];
    
}

-(void)dumpFromTheSampleBuffer:(CMSampleBufferRef)sampleBuffer index:(int)index
{
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    uint8_t *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    _bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    _width = CVPixelBufferGetWidth(imageBuffer);
    _height = CVPixelBufferGetHeight(imageBuffer);
    
    //1.dump a jpg file to the destination path
    NSString *fileStorePath = @"/Users/hbw/Desktop/about ios/理论学习/workspace/hbw-ios开发/aboutAVFoundation/dump";
    NSString *fileType = @"jpg";
    [self dumpJPEGFile:fileStorePath fileType:fileType baseAddress:baseAddress bytesPerRow:_bytesPerRow fileWidth:_width fileHeight:_height CVImageBufferRef:imageBuffer index:index];
    
    //2.dump a rgb32 file to the destination path
    NSString *storePath4 = [NSString stringWithFormat:@"/Users/hbw/Desktop/about ios/理论学习/workspace/hbw-ios开发/aboutAVFoundation/dump/%d_2560x1280.rgb32",index];
    NSData *Data = [NSData dataWithBytes:baseAddress length:_bytesPerRow*_height];
    [Data writeToFile:storePath4 atomically:YES];
    
}

-(void)dumpJPEGFile:(NSString *)storePath fileType:(NSString *)fileType baseAddress:(void *)baseAddress bytesPerRow:(size_t)bytesPerRow fileWidth:(size_t)width fileHeight:(size_t)height CVImageBufferRef:(CVImageBufferRef)imageBuffer index:(int)index
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);

    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    

    CGSize size = CGSizeMake(width, height);
    NSImage *image = [[NSImage alloc]  initWithCGImage:quartzImage size:size];
    
    NSData *imageData = [image TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    [imageRep setSize:size];
    
    NSDictionary *properties = nil;
    NSData *imageData1 = [imageRep representationUsingType:NSJPEGFileType properties:properties];
    NSString *docPath = [NSString stringWithFormat:@"%d_%zux%zu.%@",index,width,height,fileType];
    NSString *destinationPath = [storePath stringByAppendingPathComponent:docPath];
    [imageData1 writeToFile:destinationPath atomically:YES];
    
    CGImageRelease(quartzImage);
    NSLog(@"dump %@ file finished!",fileType);
}

-(NSData *)getRawDataFromCMSampleBuffer:(CMSampleBufferRef)sampleBuffer pixelBuffer:(CVImageBufferRef)imageBuffer
{
    uint8_t *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    _bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    _width = CVPixelBufferGetWidth(imageBuffer);
    _height = CVPixelBufferGetHeight(imageBuffer);
    
    NSData *Data = [NSData dataWithBytes:baseAddress length:_bytesPerRow*_height];
    
    return Data;
}


-(NSData *)getRawDataFromCMSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    uint8_t *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    _bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    _width = CVPixelBufferGetWidth(imageBuffer);
    _height = CVPixelBufferGetHeight(imageBuffer);
    
    NSData *Data = [NSData dataWithBytes:baseAddress length:_bytesPerRow*_height];
    
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    return Data;
}

-(void)convertNSDataToNSImage:(NSData *)nsData
{
    NSData *tempData = nsData;
    void *dataPointer = tempData.bytes;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(dataPointer, _width, _height, 8,
                                                 _bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    CGSize size = CGSizeMake(_width, _height);
    NSImage *image = [[NSImage alloc]  initWithCGImage:quartzImage size:size];
    
    //test************************test
    NSData *imageData = [image TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    [imageRep setSize:size];
    
    NSDictionary *properties = nil;
    NSData *imageData1 = [imageRep representationUsingType:NSJPEGFileType properties:properties];
    NSString *storePath4 = [NSString stringWithFormat:@"/Users/hbw/Desktop/about ios/理论学习/workspace/hbw-ios开发/aboutAVFoundation/dump/%d_shishi.jpg",22];
    if (test) {
        [imageData1 writeToFile:storePath4 atomically:YES];
        test = NO;
    }
    //test************************test
    
    CGImageRelease(quartzImage);
    
    
    [_imageArray addObject:image];
}

- (void) createMovieFromSource:(NSArray *)images
{
    NSLog(@"movieProcessing::createMovieFromSource");
    [_assetWriter startWriting];
    [_assetWriter startSessionAtSourceTime:kCMTimeZero];
    
    dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
    
    __block NSInteger i = 0;
    
    NSInteger frameNumber = [images count];
    
    [_assetWriterInput requestMediaDataWhenReadyOnQueue:mediaInputQueue usingBlock:^{
        while (YES){
            if (i >= frameNumber) {
                break;
            }
            if ([_assetWriterInput isReadyForMoreMediaData]) {
                NSImage* img = [images objectAtIndex:i];
                if (img == nil) {
                    i++;
                    NSLog(@"Warning: could not extract one of the frames");
                    continue;
                }
                NSData * imageData = [img TIFFRepresentation];
                CGImageRef imageRef;
                if(imageData)
                {
                    CGImageSourceRef imageSource =
                    CGImageSourceCreateWithData(
                                                (CFDataRef)imageData,  NULL);
                    
                    imageRef = CGImageSourceCreateImageAtIndex(
                                                               imageSource, 0, NULL);
                }else{ NSLog(@"movieProcessing::createMovieFromSource:if log this ,means imageData is null"); }
                
                CVPixelBufferRef sampleBuffer = [self newPixelBufferFromCGImage:imageRef];
                
                if (sampleBuffer) {
                    if (i == 0) {
                        [_p_bufferAdaptor appendPixelBuffer:sampleBuffer withPresentationTime:kCMTimeZero];
                    }else{
                        CMTime lastTime = CMTimeMake(i-1, _sourceDuration.timescale);
                        CMTime presentTime = CMTimeAdd(lastTime, _sourceDuration);
                        [_p_bufferAdaptor appendPixelBuffer:sampleBuffer withPresentationTime:presentTime];
                    }
                    CFRelease(sampleBuffer);
                    i++;
                }
            }
        }
        
        [_assetWriterInput markAsFinished];
        //关闭写入会话
        [_assetWriter finishWritingWithCompletionHandler:^{
            
            AVAssetWriterStatus status = _assetWriter.status;
            if (status == AVAssetWriterStatusCompleted)
            {
                NSLog(@"movieProcessing::movieProcessing: finsish processing!");
            }
            else
            {NSLog(@"movieProcessing::movieProcessing: failed processing!");}
        }];
        
        CVPixelBufferPoolRelease(_p_bufferAdaptor.pixelBufferPool);
    }];
}


- (CVPixelBufferRef)newPixelBufferFromCGImage:(CGImageRef)image
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          _width,
                                          _height,
                                          kCVPixelFormatType_32BGRA,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    /*CGContextRef context = CGBitmapContextCreate(pxdata, _width, _height, 8,
     _bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);*/
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 _width,
                                                 _height,
                                                 8,
                                                 _bytesPerRow,
                                                 colorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0,
                                           0,
                                           CGImageGetWidth(image),
                                           CGImageGetHeight(image)),
                       image);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}


@end
