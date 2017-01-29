//
//  editor.h
//  macFusion
//
//  Created by Alexandra Beebe on 1/6/17.
//  Copyright © 2017 Alexandra Beebe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface editor : NSObject <NSTableViewDataSource, NSTableViewDelegate>

//
@property                     NSMutableDictionary *mountPoint;
@property (weak)     IBOutlet NSWindow            *window;
@property            IBOutlet NSTableView         *stack;

//
@property            IBOutlet NSTextField         *mntPath;
@property            IBOutlet NSTextField         *volName;



//
-(IBAction) cancelSheet   :(NSButton *) sender;
-(IBAction) acceptSheet   :(NSButton *) sender;

//
-(IBAction) refreshHeight :(id)         sender;

//
-(void)     setup         :(NSArray *) overlays :(NSDictionary *) mp;


@end


