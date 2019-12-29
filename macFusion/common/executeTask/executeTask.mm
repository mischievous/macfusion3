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



        //
        output = [[NSString stringWithUTF8String:(const char *) [[[out fileHandleForReading] readDataToEndOfFile] bytes]] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSLog (@" task: *** %@ ***", output);


        
//        NSFileHandle *file = [out fileHandleForReading];
//        
//        NSData *pipe = [file availableData];
//        output = (char *) [[[out fileHandleForReading] readDataToEndOfFile] bytes];
//        NSLog (@" task: %s", output);

        if ([task terminationReason] == NSTaskTerminationReasonUncaughtSignal)
            output = NULL;

//        NSLog (@" task: %s", (char *) [[[out fileHandleForReading] readDataToEndOfFile] bytes]);
    }
    
    //
    NSLog (@"-task");

    return output;
}
//
