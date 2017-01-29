//
//  editor.m
//  macFusion
//
//  Created by Alexandra Beebe on 1/6/17.
//  Copyright © 2017 Alexandra Beebe. All rights reserved.
//

//
#import "macFusion.h"


//
#import "editor.h"
#import "overlay.h"
#import "kvo_block.h"


@interface editor ()
{
    NSArray *propertyViews;
}

@end



//
@implementation editor

//
//
-(void) awakeFromNib
{
    NSLog (@"%s", __FUNCTION__);
}
//


//
//
-(IBAction) cancelSheet:(NSButton *)sender
{
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}
//

//
//
-(IBAction) acceptSheet:(NSButton *)sender
{
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}
//

//
//
-(void)     setup         :(NSArray *) views :(NSDictionary *) mp
{
    //
    self.mountPoint = [NSMutableDictionary dictionaryWithDictionary : mp];
    
    //
    if (self.mntPath)
    {
        if (mp[MNTNAME])
            self.mntPath.placeholderString = [NSString stringWithFormat:@"/Volumes/%@", mp[MNTNAME]];
        else
            self.mntPath.placeholderString = @"/Volumes";
    }
    
    if (self.volName)
        self.volName.placeholderString = mp[MNTNAME];
    
    //
    propertyViews   = views;
    
    //
    [_stack reloadData];
    
    
    //
    [self observe:_mountPoint keyPath:MNTNAME context:NULL block: ^(id observed, NSDictionary *change, id context, id binding)
        {
            //
            if (self.mntPath)
                self.mntPath.placeholderString = [NSString stringWithFormat:@"/Volumes/%@", change[@"new"]];
            
            if (self.volName)
                self.volName.placeholderString = change[@"new"];
        }
    ];

}
//

//
//
-(void) refreshHeight :(overlay *) object
{
    BOOL hidden = object.hidden;

    NSUInteger row = [propertyViews indexOfObject:object];
    if (row != NSNotFound)
    {
        //
        if ((row == _stack.selectedRow) && (hidden))
            [_stack deselectRow:row];
        
        //
        [_stack noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:row]];
    }
}
//


#pragma mark datasource/delegate

//
//
-(NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    return propertyViews.count;
}
//

//
//
-(CGFloat) tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return ((overlay *) propertyViews[row]).height;
}
//

//
//
-(NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return ((overlay *) propertyViews[row]).view;
}
//


@end
