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
//    NSTask *task = NULL;

    NSPipe *out  = [NSPipe pipe];

    //
    NSTask *task = (debug == 0) ? [[NSTask alloc] init] : NULL;
    
    //
    NSLog (@"+task : %@ - %@ %@", task, launchPath, [arguments componentsJoinedByString:@" "]);
    
    //
    if (task)
    {
        //
        [task setLaunchPath    :launchPath];
        [task setArguments     :arguments];
        [task setStandardOutput:out];
//        [task setStandardError :out];

        [task launch];
        [task waitUntilExit];
        
        
//        NSFileHandle *file = [out fileHandleForReading];
//        
//        NSData *pipe = [file availableData];
        
    
        NSLog (@" task: %s", (char *) [[[out fileHandleForReading] readDataToEndOfFile] bytes]);
    }
    
    
    
    //
    NSLog (@"-task");
}
//
