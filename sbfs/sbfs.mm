//
//  sshfs_interface.m
//  macFusion
//
//  Created by Alexandra Beebe on 1/2/17.
//  Copyright © 2017 Alexandra Beebe. All rights reserved.
//

//
#import "executeTask.h"

//
#import "sbfs.h"

// Weak symbol, should not get called.  Only hear to keep the compiler happy.
NSString *executeTask (NSString *launchPath, NSArray *arguments, BOOL debug )
{
    return NULL;
}
//

//
@implementation sbfs

//
//
-(void     ) callback   :(NSDictionary        *) data : (NSString *) device
{
    // diskutil erasevolume HFS+ xcode /dev/disk8
    //executeTask (@"/usr/sbin/diskutil", @[@"erasevolume", @"HFS+", data[MNTNAME], device], 0 );
}
//


//
//
-(NSArray *) mount      :(NSDictionary        *) data :(NSString *) bindAddress
{
    return @[@"attach", data[MOUNT][0]];
}
//


//
//
-(NSString *) device     :(NSMutableDictionary *) data :(NSString *) supportPath
{
    //
//    NSString *bundlePath = [[NSString pathWithComponents:@[supportPath, [NSString stringWithFormat:@"%@.sparsebundle", data[MNTNAME]]]] stringByReplacingOccurrencesOfString :@" " withString:@"\\ "];
    NSString *bundlePath = [NSString pathWithComponents:@[supportPath, [NSString stringWithFormat:@"%@.sparsebundle", data[MNTNAME]]]];


    // The default size is GB.  So set count to 1 for gb.
    uint64_t count = 1;
    if ([data objectForKey:@"multiplier"])
        count = [data[@"multiplier"] unsignedLongLongValue];

    char multiplier = 'g';
    switch (count)
    {
        case   0: multiplier = 'm'; break;
        case   1: multiplier = 'g'; break;

        default : return @"";
    }

    //
    uint64_t bytes = 1;
     if ([data objectForKey:@"size"])
         bytes = strtoull([data[@"size"] UTF8String], NULL, 10);

    //
    NSString *size = [NSString stringWithFormat:@"%lld%c", bytes, multiplier];


    //
    // hdiutil create -size 150g lutzmacpro_c8bcc88bf7c3.sparsebundle -fs HFS+J  -volname “backup of lutzmac”
    executeTask (@"/usr/bin/hdiutil", @[@"create", @"-size", size,  @"-fs", @"APFS", @"-volname", data[MNTNAME], @"-type", @"SPARSEBUNDLE",  @"-nospotlight", bundlePath], 0);

    //
    return bundlePath;
}
//

//
//
-(void      ) prologEdit:(NSMutableDictionary *)data
{
}
//

//
//
-(void      ) epilogEdit :(NSMutableDictionary *)data
{
    data[MOUNT] = @[data[MOUNT][0]];
}
//

@end

// size = size / 512
// hdiutil attach -nomount ram://size
// diskutil erasevolume HFS+ xcode /dev/disk8
