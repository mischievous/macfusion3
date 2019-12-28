//
//  pluginController.h
//  macFusion
//
//  Created by Alexandra Beebe on 1/2/17.
//  Copyright © 2017 Alexandra Beebe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface pluginController : NSObject
{
    IBOutlet NSSegmentedControl *segmentCtrl;
}

//
-(void) acceptSheet:(NSDictionary *) mp;

////
//-(IBAction) cancelSheet   :(NSButton *) sender;
//-(IBAction) acceptSheet   :(NSButton *) sender;

//
-(IBAction) segmentAction :(NSSegmentedControl *) sendder;


//
-(IBAction) performMount  :(NSButton *) sender;
-(IBAction) editMount     :(NSButton *) sender;

//
-(void    ) autoMount     :(NSString *) interface :(NSString *) address;

@end
