//
//  pluginObject.h
//  macFusion
//
//  Created by Alexandra Beebe on 1/4/17.
//  Copyright © 2017 Alexandra Beebe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//
@interface pluginObject : NSObject
{
}

@property Class           principalClass;
@property id              primaryObject;
@property NSString       *name;
@property NSString       *executable;
@property NSImage        *image;
@property NSBundle       *bundle;
@property NSDictionary   *options;

@property NSMutableArray *overlays;

@end
