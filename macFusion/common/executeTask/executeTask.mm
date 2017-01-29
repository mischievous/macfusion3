//
//  executeTask.cpp
//  Chimera
//
//  Created by Alexandra Beebe on 9/11/16.
//  Copyright © 2016 Alexandra Beebe. All rights reserved.
//

#import "executeTask.h"


//
//
void executeTask (NSString *launchPath, NSArray *arguments, BOOL debug)
{
    //
    if ([launchPath characterAtIndex:0] == '.')
        NSLog (@"%@", launchPath);


    //
    NSTask *task = NULL;
    
    //
    if (debug == 0)
        task = [NSTask launchedTaskWithLaunchPath:launchPath arguments:arguments];
    
    //
    NSLog (@"+task : %@ - %@ %@", task, launchPath, [arguments componentsJoinedByString:@" "]);
    
    //
    if (task)
        [task waitUntilExit];
    
    //
    NSLog (@"-task");
}
//
