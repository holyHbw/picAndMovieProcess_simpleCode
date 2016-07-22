//
//  ViewController.m
//  picAndMovieProcess_simpleCode
//
//  Created by 黄博闻 on 16/7/21.
//  Copyright © 2016年 黄博闻. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "movieProcess.h"
#import "picProcess.h"
#import "ArcACSupportFiles.h"

@interface ViewController()
@property(nonatomic,strong)NSOpenPanel *openFilePanel;
@property(nonatomic)NSURL *sourceURL;
@end

@implementation ViewController
{
    //for example:  destinationDocumentOfMovieProcess = @"/Users/hbw/Desktop/movie";
    NSString *destinationDocumentOfMovieProcess;
    NSString *destinationDocumentOfPicProcess;
    NSString *sourceDocument;
    
    NSString *destination;
    NSString *movieDumpPath;
    NSString *picSource;
    NSString *picDestination;
    NSString *picRGBDestination;
    AVAssetReader *assetReader;
    AVAssetWriter *assetWriter;
    AVAssetWriterInput *assetInput;
    AVAssetReaderTrackOutput *assetOutput;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"viewDidLoad");
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)openFile:(id)sender {
    self.openFilePanel = [NSOpenPanel openPanel];
    
    _openFilePanel.allowsMultipleSelection = NO;
    _openFilePanel.canChooseDirectories = NO;
    _openFilePanel.canChooseFiles = YES;
    _openFilePanel.allowsOtherFileTypes = NO;
    
    //allowedFileTypes is a NSArray
    _openFilePanel.allowedFileTypes = [[ArcACSupportFiles sharedInstance] supportAllTypes];
    
    [_openFilePanel beginSheetModalForWindow:[NSApplication sharedApplication].mainWindow completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            _sourceURL = [_openFilePanel URL];
            
            [_openFilePanel orderOut:nil];
            [_openFilePanel close];
            // delay for debugging
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                NSString *path = [_sourceURL absoluteString];
                //analyse the file type of url
                NSArray *matchArray = [path componentsSeparatedByString:@"."];
                if ([[matchArray objectAtIndex:1]  isEqual: @"jpg"]) {
                    
                    NSLog(@"jpg file");
                    picProcess *pp = [[picProcess alloc]initWithSourceURL:_sourceURL];
                    [pp picProcessing];
                    
                }else if ([[matchArray objectAtIndex:1]  isEqual: @"mp4"]){
                    
                    NSLog(@"mp4 file");
                    NSDictionary *outputSetting = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};//kCVPixelFormatType_32BGRA
                    NSDictionary *inputSetting = @{
                                                   AVVideoCodecKey:AVVideoCodecH264,
                                                   AVVideoWidthKey:@1280,
                                                   AVVideoHeightKey:@720,
                                                   AVVideoCompressionPropertiesKey:@{
                                                           AVVideoMaxKeyFrameIntervalKey:@1,
                                                           AVVideoAverageBitRateKey:@10500000,
                                                           AVVideoProfileLevelKey:AVVideoProfileLevelH264Main31 }
                                                   };
                    movieProcess *mp = [[movieProcess alloc]initMovieProcessingWithSourceURL:_sourceURL  outputSetting:outputSetting inputSetting:inputSetting];
                    [mp movieProcessing:YES];
                    
                }else if ([[matchArray objectAtIndex:1]  isEqual: @"jpeg"]){
                    NSLog(@"jpeg file");
                }else if ([[matchArray objectAtIndex:1]  isEqual: @"m4v"]){
                    NSLog(@"m4v file");
                }
                
            });
        };
    }];
}
@end
