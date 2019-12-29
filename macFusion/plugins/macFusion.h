//
//  pluginProtocol.h
//  macFusion
//
//  Created by Alexandra Beebe on 1/3/17.
//  Copyright © 2017 Alexandra Beebe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define MNTNAME      (@"mntName"      )
#define PLUGIN       (@"plugin"       )
#define MNTSTATUS    (@"mntStatus"    )
#define MNTIMAGE     (@"mntImage"     )
#define MOUNT        (@"mount"        )
#define MNTPOINT     (@"mntPoint"     )
#define VOLNAME      (@"volName"      )
#define EXTRAOPTIONS (@"extraOptions" )
#define MNTPATH      (@"mntPath"      )
#define SIERRA       (@"sierra"       )
#define HOST         (@"host"         )
#define USERNAME     (@"username"     )
#define PATH         (@"path"         )
#define DEVICE       (@"device"       )

#define LNCHMNT      (@"amLaunch"     ) // Auto mount launch
#define INTFMNT      (@"amInterface"  ) // Auto mount interface : utun0
#define NTWKMNT      (@"amNetwork"    ) // Auto mount network   : 192.168/16

#define INTERFACE    (@"interface"    ) // Auto mount interface name 
#define NETWORK      (@"network"      ) // Auto mount network address
#define NETMASK      (@"netmask"      ) // Auto mount network address
#define NETADDR      (@"netaddr"      ) // Auto mount network address


//
@protocol macfusion <NSObject>

    @optional
        -(void      ) callback   :(NSDictionary        *) data :(NSString *) output;

    @required
        -(NSArray  *) mount      :(NSDictionary        *) data :(NSString *) bindAddress;

        -(NSString *) device     :(NSMutableDictionary *) data;

        -(void      ) prologEdit :(NSMutableDictionary *) data;
        -(void      ) epilogEdit :(NSMutableDictionary *) data;


@end
