//
//  ViewController.h
//  picAndMovieProcess_simpleCode
//
//  Created by 黄博闻 on 16/7/21.
//  Copyright © 2016年 黄博闻. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

@property (weak) IBOutlet NSButton *choseFile;

- (IBAction)openFile:(id)sender;

@end

