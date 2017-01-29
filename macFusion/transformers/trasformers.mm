//
//  mntStatus.m
//  macFusion
//
//  Created by Alexandra Beebe on 1/4/17.
//  Copyright © 2017 Alexandra Beebe. All rights reserved.
//

//
#import "macFusion.h"

//
#import "trasformers.h"


id performCheck (NSArray *value, id t, id f)
{
    //
    if (value.count != 1)
        return @1;

    return ([value[0][MNTSTATUS] boolValue] == 1) ? t:f;
}


@implementation unmount

-(id) transformedValue :(NSArray *) value
{
    return performCheck (value, @0, @1);
}

@end


@implementation mount

-(id) transformedValue :(NSArray *) value
{
    return performCheck (value, @1, @0);
}

@end
