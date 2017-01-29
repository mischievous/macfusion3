//
//  mntStatus.m
//  macFusion
//
//  Created by Alexandra Beebe on 1/4/17.
//  Copyright © 2017 Alexandra Beebe. All rights reserved.
//

#import "mntStatus.h"

@implementation mntStatus

-(id) transformedValue :(NSNumber *) value
{
    if (value)
    {
        //
        switch ([value unsignedLongLongValue])
        {
            case 1  : return @"(Mounted)";
            default : break;
        }
    }

    return @"(Unmounted)";
}

@end
