//
//  overview.h
//  macFusion
//
//  Created by Alexandra Beebe on 1/6/17.
//  Copyright © 2017 Alexandra Beebe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//
@interface overlay : NSObject
{
}

//
@property            NSView    *view;
@property  IBOutlet  NSView    *child;

//
@property            BOOL      hidden;
@property            NSString *hiddenStatus;
@property (readonly) CGFloat   height;


//
+(overlay *) factory :(NSString *) nibName :(NSBundle *) bundle :(id) owner;

@end
