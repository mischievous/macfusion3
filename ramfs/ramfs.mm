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
    uint64_t bytes;
    if (!(bytes = [data[@"size"] unsignedLongLongValue]))
        bytes = 1;

    //
    bytes *= 1048576;
    while (count)
        { bytes *= 1024; count -= 1; }


    // 1m ==    1048576 [    512 ]
    // 1g == 1073741824 [ 524288 ]

    //
    return [NSString stringWithFormat:@"ram://%lld", bytes / 2048];
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

    //
//    for (NSString *option in [NSArray arrayWithArray:data[MOUNT]])
//    {
//        if (![option hasPrefix:@"-o"])
//            continue;
//
//        //
//        [data[MOUNT] removeObject:option];
//    }
}
//

@end

// size = size / 2048
// hdiutil attach -nomount ram://size
// diskutil erasevolume HFS+ xcode /dev/disk8
