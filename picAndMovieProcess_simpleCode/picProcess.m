//
//  picProcess.m
//  picAndMovieProcess_simpleCode
//
//  Created by 黄博闻 on 16/7/21.
//  Copyright © 2016年 黄博闻. All rights reserved.
//

#import "picProcess.h"
#import <AppKit/AppKit.h>

@implementation picProcess
{
    size_t imageWidth;
    size_t imageHeight;
    size_t bytesPerRow;
    size_t contextLength;
}

-(instancetype)initWithSourceURL:(NSURL *)sourceURL{
    if (self = [super init]) {
        _sourceURL = sourceURL;
        
        //specify the destination store path
        NSArray *arr1 = [[_sourceURL absoluteString] componentsSeparatedByString:@"/"];
        NSString *filename = [arr1 lastObject];
        NSString *_filename = [@"/" stringByAppendingString:filename];
        NSArray *arr2 = [[_sourceURL absoluteString] componentsSeparatedByString:_filename];
        _destinationDocument= [arr2 objectAtIndex:0];
        _destinationPath = [[NSURL URLWithString:[[_destinationDocument stringByAppendingPathComponent:@"new_jpg.jpg"] substringFromIndex:5]] absoluteString];
        
        return self;
    }
    NSLog(@"failed init");
    return nil;
}

#pragma processing
-(void)picProcessing
{
    NSImage *image = [[NSImage alloc]initWithContentsOfURL:_sourceURL];
    
    unsigned char *pointer = [self convertSourceImageToBitmapRGBA:image];
    
    //engine do process
    //...write you code here...//
    //engine do process
    
    [self convertBitmapToDestinationWithPionter:pointer];
    
    NSLog(@"picProcessing::picProcessing:Done!");
}

-(unsigned char *)convertSourceImageToBitmapRGBA:(NSImage *)image
{
    //convert NSImage to CGImageRef
    struct CGImageSource* source = CGImageSourceCreateWithData((__bridge CFDataRef)[image TIFFRepresentation], NULL);
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                             (id)kCFBooleanFalse, (id)kCGImageSourceShouldCache,
                             (id)kCFBooleanTrue, (id)kCGImageSourceShouldAllowFloat,
                             nil];
    CGImageRef imageRef =  CGImageSourceCreateImageAtIndex(source, 0, (CFDictionaryRef)options);
    
    //create CGContextRef from CGImageRef
    CGContextRef context = [self newBitmapRGBA8ContextFromImage:imageRef];
    if (!context) {
        NSLog(@"picProcessing::convertSourceImageToBitmapRGBA:failed to create a context!");
        return nil;
    }
    
    //get the info of CGImageRef，then draw CGImageRef to CGContextRef中，get the rawdata
    imageWidth = CGImageGetWidth(imageRef);
    imageHeight = CGImageGetHeight(imageRef);
    bytesPerRow = CGBitmapContextGetBytesPerRow(context);
    contextLength = bytesPerRow*imageHeight;
    CGRect imgRect = CGRectMake(0, 0, imageWidth, imageHeight);
    CGContextDrawImage(context, imgRect, imageRef);
    
    //get the pointer of the rawdata of CGContextRef
    unsigned char * bitmapData = CGBitmapContextGetData(context);
    
    //dump test
    NSString *dumpFileName = [NSString stringWithFormat:@"%zux%zu.rgb32",imageWidth,imageHeight];
    NSString *dumpPath = [[NSURL URLWithString:[ [_destinationDocument stringByAppendingPathComponent:dumpFileName] substringFromIndex:5]] absoluteString];
    [self dumpTheRawdataToDestination:dumpPath pointer:bitmapData];
    
    return bitmapData;
}

-(void)convertBitmapToDestinationWithPionter:(unsigned char *)pointer
{
    //create CGContextRef with pointer
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, pointer, contextLength, NULL);
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    //size_t bytesPerRow = 4 * imageWidth;
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    if(colorSpaceRef == NULL) {
        NSLog(@"Error allocating color space");
        CGDataProviderRelease(provider);
    }
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef iref = CGImageCreate(imageWidth,
                                    imageHeight,
                                    bitsPerComponent,
                                    bitsPerPixel,
                                    bytesPerRow,
                                    colorSpaceRef,
                                    bitmapInfo,
                                    provider,    // data provider
                                    NULL,        // decode
                                    YES,            // should interpolate
                                    renderingIntent);
    
    uint32_t* pixels = (uint32_t*)malloc(contextLength);
    
    if(pixels == NULL) {
        NSLog(@"Error: Memory not allocated for bitmap");
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpaceRef);
        CGImageRelease(iref);
    }
    
    CGContextRef context = CGBitmapContextCreate(pixels,
                                                 imageWidth,
                                                 imageHeight,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpaceRef,
                                                 bitmapInfo);
    
    if(context == NULL) {
        NSLog(@"Error context not created");
        free(pixels);
    }
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, imageWidth, imageHeight), iref);
    
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    
    CGSize size = CGSizeMake(imageWidth, imageHeight);
    NSImage *image = [[NSImage alloc]  initWithCGImage:quartzImage size:size];
    
    // convert NSImage to jpg file
    NSData *imageData = [image TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    [imageRep setSize:size];
    
    NSDictionary *properties = nil;
    NSData *imageData1 = [imageRep representationUsingType:NSJPEGFileType properties:properties];
    //NSString *destinationPath = [_destinationURL absoluteString];
    [imageData1 writeToFile:_destinationPath atomically:YES];
    
    // release Quartz image
    CGImageRelease(quartzImage);
}

-(CGContextRef)newBitmapRGBA8ContextFromImage:(CGImageRef)image
{
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    uint32_t *bitmapData;
    
    size_t bitsPerPixel = 32;
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = bitsPerPixel / bitsPerComponent;
    
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    
    size_t bytesperRow = width * bytesPerPixel;
    size_t bufferLength = bytesperRow * height;
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if(!colorSpace) {
        NSLog(@"Error allocating color space RGB\n");
        return NULL;
    }
    
    // Allocate memory for image data
    bitmapData = (uint32_t *)malloc(bufferLength);
    
    if(!bitmapData) {
        NSLog(@"Error allocating memory for bitmap\n");
        CGColorSpaceRelease(colorSpace);
        return NULL;
    }
    
    //Create bitmap context
    
    context = CGBitmapContextCreate(bitmapData,
                                    width,
                                    height,
                                    bitsPerComponent,
                                    bytesperRow,
                                    colorSpace,
                                    kCGImageAlphaPremultipliedLast);    // RGBA
    if(!context) {
        free(bitmapData);
        NSLog(@"picProcessing::newBitmapRGBA8ContextFromImage:Bitmap context not created");
    }
    
    CGColorSpaceRelease(colorSpace);
    
    return context;
}

-(void)dumpTheRawdataToDestination:(NSString *)str pointer:(unsigned char*)pointer
{
    NSData *data = [NSData dataWithBytes:pointer length:contextLength];
    [data writeToFile:str atomically:YES];
}
#pragma processed




-(void)saveToJPG:(void *)pointer
{
    NSLog(@"saveToJPG pointer is %p",pointer);
    
    //const Byte *dataAddress = pointer;
    
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(pointer, imageWidth, imageHeight, 8,
                                                 imageWidth*4, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    
    // 释放context和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // 用Quartz image创建一个UIImage对象image
    CGSize size = CGSizeMake(imageWidth, imageHeight);
    NSImage *image = [[NSImage alloc]  initWithCGImage:quartzImage size:size];
    
    //将NSImage转为jpg存储
    NSData *imageData = [image TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    [imageRep setSize:size];
    
    NSDictionary *properties = nil;
    NSData *imageData1 = [imageRep representationUsingType:NSJPEGFileType properties:properties];
    NSString *destinationPath = [_destinationURL absoluteString];
    [imageData1 writeToFile:destinationPath atomically:YES];
    
    // 释放Quartz image对象
    CGImageRelease(quartzImage);
    
    
    
}

-(void *)decodePic:(NSImage *)image
{
    //将源NSImage转化为CGImageRef（bitmap）,并获取bitmap的相关信息
    struct CGImageSource* source = CGImageSourceCreateWithData((__bridge CFDataRef)[image TIFFRepresentation], NULL);
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                             (id)kCFBooleanFalse, (id)kCGImageSourceShouldCache,
                             (id)kCFBooleanTrue, (id)kCGImageSourceShouldAllowFloat,
                             nil];
    CGImageRef imageRef =  CGImageSourceCreateImageAtIndex(source, 0, (CFDictionaryRef)options);
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    CGDataProviderRef provider = CGImageGetDataProvider(imageRef);
    void *data =(void*) CFDataGetBytePtr(CGDataProviderCopyData(provider));
    bytesPerRow = CGImageGetBytesPerRow(imageRef);
    imageWidth = CGImageGetWidth(imageRef);
    imageHeight = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // It calculates the bytes-per-row based on the bitsPerComponent and width arguments.
    //创建CGContextRef
    CGContextRef context = CGBitmapContextCreate(data,
                                                 imageSize.width,
                                                 imageSize.height,
                                                 8,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGColorSpaceRelease(colorSpace);
    
    // If failed, return undecompressed image
    if (!context) NSLog(@"picProcessing::decodePic:failed!");
    
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    //将CGImageRef转为NSImage，再转为NSData
    NSImage *decompressedImage = [[NSImage alloc]initWithCGImage:decompressedImageRef size:imageSize];
    NSData *imageData = [decompressedImage TIFFRepresentation];
    CGImageRelease(decompressedImageRef);
    
    //写NSData
    NSString *storePath4 = [NSString stringWithFormat:@"/Users/hbw/Desktop/about ios/理论学习/workspace/hbw-ios开发/aboutAVFoundation/dump/%zux%zu.rgb",imageWidth,imageHeight];
    [imageData writeToFile:storePath4 atomically:YES];
    
    return imageData.bytes;
}

-(void)useless{
    /*
     //根据pointer转为NSImage
     CGDataProviderRef pv=CGDataProviderCreateWithData(pointer, pointer, imageWidth*imageHeight*3, nil);
     CGImageRef content=CGImageCreate(imageWidth , imageHeight, 8, 24, bytesPerRow,
     CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast,
     pv, NULL, true, kCGRenderingIntentDefault);
     CGSize size = CGSizeMake(imageWidth, imageHeight);
     NSImage *ci = [[NSImage alloc]initWithCGImage:content size:size];
     */
}

@end
