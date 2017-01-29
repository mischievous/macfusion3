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

//
@protocol macfusion <NSObject>

    @required
        -(BOOL      ) mount      :(NSDictionary        *) data;

        -(NSString *) device     :(NSMutableDictionary *) data;

        -(void      ) prologEdit :(NSMutableDictionary *) data;
        -(void      ) epilogEdit :(NSMutableDictionary *) data;


@end
