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
#import "ramfs.h"

// Weak symbol, should not get called.  Only hear to keep the compiler happy.
NSString *executeTask (NSString *launchPath, NSArray *arguments, BOOL debug )
{
    return NULL;
}
//

//
@implementation ramfs

//
//
-(void     ) callback   :(NSDictionary        *) data : (NSString *) device
{
    // diskutil erasevolume HFS+ xcode /dev/disk8
    executeTask (@"/usr/sbin/diskutil", @[@"erasevolume", @"HFS+", data[MNTNAME], device], 0 );
}
//


//
//
-(NSArray *) mount      :(NSDictionary        *) data :(NSString *) bindAddress
{
    //
    return @[@"attach", @"-nomount", data[MOUNT][0]];
}
//


//
//
-(NSString *) device     :(NSMutableDictionary *) data
{
    // The default size is GB.  So set count to 1 for gb.
    uint64_t count = 1;
    if ([data objectForKey:@"multiplier"])
        count = [data[@"multiplier"] unsignedLongLongValue];

    //
    uint64_t bytes = 1;
    if ([data objectForKey:@"size"])
        bytes = strtoull([data[@"size"] UTF8String], NULL, 10);

    //
    bytes *= 1048576;
    while (count)
        { bytes *= 1024; count -= 1; }


    // 1m ==    1048576 [    512 ]
    // 1g == 1073741824 [ 524288 ]

    //
    return [NSString stringWithFormat:@"ram://%lld", bytes / 512];
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
