//
//  afp.m
//  macFusion
//
//  Created by Alexandra Beebe on 1/12/17.
//  Copyright © 2017 Alexandra Beebe. All rights reserved.
//

#import "afp.h"


@implementation afp

//
//
-(NSArray  *) mount      :(NSDictionary        *) data :(NSString *) bindAddress
{
    NSString *device;
    if (!(device = data[DEVICE]))
        return NULL;

    NSURL *volume    = [NSURL URLWithString:[device stringByAddingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding]];

    
    //
    NSString *mntPath;
    if (!(mntPath = data[MNTPATH]))
        return NULL;
    
    NSURL *mountpath = [NSURL URLWithString: mntPath];

#if 0
    //
    FSMountServerVolumeSync ((__bridge CFURLRef) volume,  (__bridge CFURLRef) mountpath, (__bridge CFStringRef) data[USERNAME], (__bridge CFStringRef) @"euthanat0s", NULL, kFSMountServerMountOnMountDir);

#else

    
    //
    CFArrayRef mountpoints = NULL;

    CFMutableDictionaryRef mountOpts = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(mountOpts, kNetFSMountAtMountDirKey, CFSTR("true"));
    CFDictionarySetValue(mountOpts, kNetFSAllowSubMountsKey , CFSTR("true"));



    
    int results;
    results = NetFSMountURLSync ((__bridge CFURLRef) volume,  (__bridge CFURLRef) mountpath, (__bridge CFStringRef) data[USERNAME], (__bridge CFStringRef) @"euthanat0s", NULL, mountOpts, &mountpoints);
    NSLog (@"afp::mount : %d : %@", results, mountpoints);

#endif

    return NULL;
}
//


//
-(NSString *) device     :(NSMutableDictionary *) data
{
    //
    NSString *host = data[HOST];
    if (!host)
        return NULL;
    
    //
    NSString *path = data[PATH];
    if (!path)
        path = @"";


    return [NSString stringWithFormat:@"afp://%@/%@", host, path];
}
//

//
//
-(void      ) prologEdit :(NSMutableDictionary *) data
{
}
//

//
//
-(void      ) epilogEdit :(NSMutableDictionary *) data
{
}
//


@end


// FSMountServerVolumeAsync
