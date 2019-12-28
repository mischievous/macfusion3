//
//  AppDelegate.m
//  macFusion
//
//  Created by Alexandra Beebe on 1/2/17.
//  Copyright © 2017 Alexandra Beebe. All rights reserved.
//

#import "AppDelegate.h"


@interface AppDelegate ()

//
@property (weak)                IBOutlet NSWindow    *window;

@end

@implementation AppDelegate

//
//
+(void) initialize
{
    if (self == [AppDelegate class])
    {
        //
        NSLog     (@"+%s", __FUNCTION__);
    }
}
//


//
//
-(void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}
//

//
//
-(void) applicationWillTerminate:(NSNotification *)aNotification
{
    // Insert code here to tear down your application
}
//

@end
