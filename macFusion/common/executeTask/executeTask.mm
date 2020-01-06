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
NSString *executeTask (NSString *launchPath, NSArray *arguments, BOOL debug )
{
    NSString *output = NULL;

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

        char *bytes;
        if ((bytes = (char *) [[[out fileHandleForReading] readDataToEndOfFile] bytes]))
        {
            //
            output = [[NSString stringWithUTF8String:bytes] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSLog (@" task: *** %@ ***", output);
        }

        //
        if ([task terminationReason] == NSTaskTerminationReasonUncaughtSignal)
            output = NULL;
    }
    
    //
    NSLog (@"-task");

    return output;
}
//
