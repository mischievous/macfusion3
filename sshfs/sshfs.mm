//
//  sshfs_interface.m
//  macFusion
//
//  Created by Alexandra Beebe on 1/2/17.
//  Copyright © 2017 Alexandra Beebe. All rights reserved.
//

#import "sshfs.h"

#define PORT     (@"port"    )


@implementation sshfs

//
//
-(BOOL      ) mount      :(NSDictionary        *) data
{
    return 1;
}
//


//
//
-(NSString *) device     :(NSMutableDictionary *) data
{
    //
    // (x)  host
    // (x)  user
    // (x)  path
    
    //
    NSString *host = data[HOST];
    if (!host)
        return NULL;

    //
    NSString *user = data[USERNAME];
    if (!user)
        user = NSUserName();
    
    //
    NSString *path = data[PATH];
    if (!path)
        path = @"";

    //
    return [NSString stringWithFormat:@"%@@%@:%@", user, host, path];
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
//
// (x)  port
// (x)  compression
// (x)  symlinks
// (x)  autoCache          -- Should be moved to main options!
// (x)  deferPermissions
    
    if (!data[PORT])
        return;
    
    uint32_t port = [((NSString *) data[PORT]) intValue] & 0xffff;
    if ((port == 0) || (port == 22))
        return;


    //
    [data[MOUNT] addObject: [NSString stringWithFormat:@"-p%d", port]];
}
//

@end

//sshfs-static -oCheckHostIP=no -oStrictHostKeyChecking=no -oNumberOfPasswordPrompts=1 -ologlevel=debug1 -f


//sshfs-static alexandra@192.168.1.100: /Volumes/vamp -p22 -oCheckHostIP=no -oStrictHostKeyChecking=no -oNumberOfPasswordPrompts=1 -ofollow_symlinks -ovolname=vamp -ologlevel=debug1 -f -ovolicon=/Users/alexandra/Applications/Macfusion.app/Contents/PlugIns/sshfs.mfplugin/Contents/Resources/sshfs_icon.icns -o local -onoappledouble


