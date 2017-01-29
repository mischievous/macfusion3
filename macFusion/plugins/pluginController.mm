//
//  pluginController.m
//  macFusion
//
//  Created by Alexandra Beebe on 1/2/17.
//  Copyright © 2017 Alexandra Beebe. All rights reserved.
//

//
#import <SystemConfiguration/SystemConfiguration.h>

//
#include <sys/types.h>
#include <sys/sysctl.h>
#include <netdb.h>

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>


//
#import "macFusion.h"

//
#import "pluginController.h"
#import "pluginObject.h"
#import "overlay.h"
#import "editor.h"
#import "executeTask.h"

NSDictionary *options = @{
                             @"ignoreDouble" : @"-onoappledouble",
                             @"local"        : @"-olocal",
                             @"vnodeCache"   : @"-onegative_vncache",
                         };



//
//
@interface pluginController ()
{
    //
    NSFileManager         *fileManager;
    NSMutableDictionary   *filesystems;
    
    NSMutableArray        *mountActive;
    NSMutableDictionary   *mountPaths;  // Dictionary of mountPaths to actual mount point data saved in mountPoints.

    //
    NSMutableDictionary   *autoMounts;

    
    //
    NSString              *supportPath;
    
    //
    NSNumber              *sierra;
}
//

//
@property (weak)   IBOutlet NSWindow            *window;
@property          IBOutlet editor              *editorController;

//
@property (assign) IBOutlet NSArrayController   *mountPoints;


@end


@implementation pluginController

//
//
-(void) setup
{    
    //
    NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];

    //
    filesystems = [NSMutableDictionary dictionaryWithCapacity:0];
    
    NSString *path = [[NSBundle mainBundle] builtInPlugInsPath];
    NSString *type = @"filesystem";
    
    //
    // NSLog (@"%@", path);
    for (NSString *fileSystem in [NSBundle pathsForResourcesOfType:type inDirectory:path])
    {
        //
        pluginObject *plugin;
        if ((plugin = [self bundleLoad :fileSystem]))
        {
            filesystems[plugin.name] = plugin;
        
            //
            NSMenuItem *item = [NSMenuItem new];
            [item setTitle: plugin.name];
            [item setRepresentedObject: plugin];
            [item setTarget: self];
            [item setAction: @selector(newMount:)];
        
            //
            [theMenu addItem:item];
        }
    }
    
    //
    [segmentCtrl setMenu:theMenu forSegment:0];
}
//

//
//
-(void) awakeFromNib
{
    //
    [super awakeFromNib];

    //
    [self setup];
    
    //
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector: @selector(volumeAdd:) name:NSWorkspaceDidMountNotification   object: nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector: @selector(volumeRem:) name:NSWorkspaceDidUnmountNotification object: nil];
    
    
    // auto detact if running on sierra.
    char osxversion[256];
    size_t size = sizeof(osxversion);
    sysctlbyname("kern.osrelease", osxversion, &size, NULL, 0);
    
    //
    sierra = atoi (osxversion) >= 16 ? @1:@0;

    //
    mountActive = [NSMutableArray      arrayWithCapacity     :0];
    mountPaths  = [NSMutableDictionary dictionaryWithCapacity:0];
    autoMounts  = [NSMutableDictionary dictionaryWithCapacity:0];


    //
    fileManager = [NSFileManager defaultManager];
    

    //
    supportPath = [NSString pathWithComponents:@[
                                                 NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0],
                                                 [[NSProcessInfo processInfo] processName]
                                                 ]];
    
    //
    if(![fileManager fileExistsAtPath:supportPath])
    {
        if(![fileManager createDirectoryAtPath:supportPath withIntermediateDirectories:YES attributes:nil error:NULL])
        {
            NSLog(@"Error: Create folder failed %@", supportPath);
            supportPath = NULL;
        }
    }

    //
    for (NSURL *url in [fileManager mountedVolumeURLsIncludingResourceValuesForKeys:NULL options:NSVolumeEnumerationSkipHiddenVolumes])
        [mountActive addObject:url.path];
    
    //
    for (__strong NSString *path in [fileManager contentsOfDirectoryAtPath:supportPath error:NULL])
    {
        if ([[path pathExtension] compare:@"mountPoint"] != NSOrderedSame)
            continue;
    
        //
        NSMutableDictionary *data = [NSKeyedUnarchiver unarchiveObjectWithData:[NSData dataWithContentsOfFile:[supportPath stringByAppendingPathComponent:path]]];
        
        //
        mountPaths[data[MNTPATH]] = data;
        [self volumeStatus:data :NULL];
        
        //
        [_mountPoints addObject:data];
    }
}
//

//
//
-(void) volumeStatus :(NSMutableDictionary *) data :(NSDictionary *) mp
{
    //
    if (data)
    {
        data[MNTSTATUS] = ([mountActive indexOfObject:data[MNTPATH]] == NSNotFound) ? @0:@1;
    
        //
        if (mp)
        {
            if ([mp[MNTNAME] compare:data[MNTNAME]] == NSOrderedSame)
            {
                [_mountPoints setSelectionIndex:NSNotFound];
                [_mountPoints setSelectedObjects:@[mp]];
            }
        
        }
    }
}
//

//
//
-(void) volumeAdd: (NSNotification*) notification
{
    //
    NSString *devicePath = notification.userInfo[@"NSDevicePath"];

    //
    [mountActive addObject:devicePath];
    
    //
    [self volumeStatus:mountPaths[devicePath] :[self selectedMount]];
}
//

//
//
-(void) volumeRem: (NSNotification*) notification
{
    //
    NSString *devicePath = notification.userInfo[@"NSDevicePath"];
    
    //
    [mountActive removeObject:devicePath];

    //
    [self volumeStatus:mountPaths[devicePath] :[self selectedMount]];
}
//


//
//
-(IBAction) performUnmount   :(NSButton *) sender
{
    //
    NSDictionary *mp;
    if (!(mp = [self selectedMount]))
        return;
    
    [self __unmount:mp];
}
//

//
//
-(IBAction) performMount     :(NSButton *) sender
{
    NSDictionary *mp;
    if (!(mp = [self selectedMount]))
        return;
    
    [self __mount :mp :NULL];
}
//


//
//
-(void) __unmount :(NSDictionary *) mp
{
    NSError *error;
    if ([[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtURL:[NSURL fileURLWithPath: mp[MNTPATH]] error:&error] == 0)
        NSLog (@"unmounting %@ : %@", mp[MNTPATH], error);
}
//

//
//
-(void) __mount :(NSDictionary *) mp :(NSString *) interface
{
    // Check to see if the volume is already mounted and get out of dodge if it is.
    if ([mp[MNTSTATUS] boolValue] == 1)
        return;

    //
    if (interface)
    {
        //
        if (autoMounts[interface] == NULL)
            autoMounts[interface] = [NSMutableArray arrayWithCapacity:0];
        
        //
        [autoMounts[interface] addObject:mp];
    }
        

    //
    pluginObject *plugin;
    if (!(plugin = filesystems[mp[PLUGIN]]))
        return;

    //
    if (![mp[SIERRA] boolValue])
    {
        //
        if(![fileManager fileExistsAtPath:mp[MNTPATH]])
        {
            if(![fileManager createDirectoryAtPath:mp[MNTPATH] withIntermediateDirectories:YES attributes:nil error:NULL])
            {
                NSLog(@"Error: Create folder failed %@", mp[MNTPATH]);
                return;
            }
        }
        
    }
    
    //
    if (!([plugin.primaryObject mount:mp]))
        return;
    
    
    //
    executeTask (plugin.executable, mp[MOUNT], 0);
}
//

//
//
#define OptionKey (1 << 19)
// Because apple is soo smart...
// 10.12+ the name is NSEventModifierFlagOption
// 10.11- the name is NSAlternateKeyMask

//
-(IBAction) doubleClick      :(id) sender
{
    //
    uint64_t modifierFlags = [NSApp currentEvent].modifierFlags;
    
    //
    if ((modifierFlags & OptionKey) == OptionKey)
        return [self editMount:sender];

    
    NSDictionary *mp;
    if (!(mp = [self selectedMount]))
        return;

    //
    switch ([mp[MNTSTATUS] boolValue])
    {
        case  0 : // Mount
            [self performMount  :NULL];
            break;
            
        default : // UNmount
            [self performUnmount:NULL];
    }
}
//

//
//
-(pluginObject *) bundleLoad :(NSString *) bundlePath
{
    //
    NSBundle *bundle;
    if (!(bundle = [NSBundle bundleWithPath:bundlePath]))
        return NULL;
    
    //
    [bundle load];
    
    //
    if (! [[bundle principalClass] conformsToProtocol:@protocol (macfusion)] )
        return NULL;
    
    
    // verify the "filesystem"ary
    NSDictionary *fileSystem;
    if (!(fileSystem = [bundle objectForInfoDictionaryKey:@"fileSystem"]))
        return NULL;
    
    
    // If the fileSystem uses an executable make sure it exists...
    if ([fileSystem objectForKey:@"executable"])
    {
        if (![[NSFileManager defaultManager] fileExistsAtPath:[fileSystem objectForKey:@"executable"]])
            return NULL;
    }

    //
    pluginObject *object;
    if (!(object = [pluginObject new]))
        return NULL;
    
    object.principalClass = [bundle principalClass];
    object.primaryObject  = [object.principalClass new];
    object.name           = [fileSystem objectForKey:@"name"      ];
    object.executable     = [fileSystem objectForKey:@"executable"];
    object.options        = [fileSystem objectForKey:@"options"   ];
    object.bundle         = bundle;
    object.overlays       = [NSMutableArray arrayWithCapacity:0];
    
    //
    NSString *imageName   = [bundle pathForImageResource:[fileSystem objectForKey:@"image"]];
    
    //
    object.image          = [[NSImage alloc] initByReferencingFile:imageName];
    object.image.name     = imageName;


    //  credentials come first in any ... any filesystem
    for (NSString *nibName in @[@"credentials"])
    {
        overlay *ol;
        
        //
        if ((ol = [overlay factory :nibName :[NSBundle mainBundle] :_editorController]))
            [object.overlays addObject:ol];
    }

    
    //
    for (NSString *nibName in [fileSystem objectForKey:@"nibs"])
    {
        overlay *ol;
    
        //
        if ((ol = [overlay factory :nibName :bundle :_editorController]))
            [object.overlays addObject:ol];
    }
    
    //
    for (NSString *nibName in @[@"macfusion"])
    {
        overlay *ol;
        
        //
        if ((ol = [overlay factory :nibName :[NSBundle mainBundle] :_editorController]))
            [object.overlays addObject:ol];
    }


    //
    return object;
}
//

//
//
-(NSString *) mountPath :(NSString *) filename
{
    if ((!filename) || (!supportPath))
        return NULL;
    
    if (filename.length == 0)
        return NULL;

    //
    NSString *path = [supportPath stringByAppendingPathComponent:[filename stringByAppendingPathExtension:@"mountPoint"]];
    if([fileManager fileExistsAtPath:path])
        [fileManager removeItemAtPath :path error:NULL];

    //
    return path;
}
//

//
//
-(amMap *) selectedMount
{
    // Grab the selected objects.
    NSArray *so = [_mountPoints selectedObjects];
    
    // Length should only be 1.
    if (so.count != 1)
        return NULL;
    
    //
    return so[0];
}
//


#pragma mark macFusion

//
//
-(void) setOptions :(NSDictionary *) o :(NSDictionary *) data :(NSMutableArray *) mount
{
    //
    [o enumerateKeysAndObjectsUsingBlock: ^(NSString *key, NSString *val, BOOL *stop)
        {
            if ([data[key] boolValue])
                [mount addObject:val];
        }
    ];
}
//

//
//
-(void) prologEdit :(NSMutableDictionary *) data :(pluginObject *) plugin
{
    //
    [plugin.primaryObject prologEdit:data];
}
//

//
//
-(BOOL) epilogEdit :(NSMutableDictionary *) data :(pluginObject *) plugin
{
    //
    // (x) device
    // (x) mount point
    // (x) volname
    // (x) volicon
    // (x) ignoreDouble
    // (x) vnodeCache
    // (x) local
    // ( ) extraOptions
    
    //
    NSMutableArray *mount = [NSMutableArray arrayWithCapacity:0];
    
    //
    NSString *device;
    if (!(device = [plugin.primaryObject device:data]))
        return 0;
    
    //
    data[DEVICE] = device;
    
    //
    [mount addObject:data[DEVICE]];

    //
    //
    NSString *mountPoint = [NSString stringWithFormat:@"/Volumes/%@", data[MNTNAME]];
    if (data[MNTPOINT])
        mountPoint = data[MNTPOINT];

    data[MNTPATH] = mountPoint;

    //
    [mount addObject: data[MNTPATH]];

    //
    //
    NSString *volumeName = data[MNTNAME];
    if (data[VOLNAME])
        volumeName = data[VOLNAME];
    [mount addObject: [NSString stringWithFormat:@"-ovolname=%@", volumeName]];
    
    //
    [mount addObject: [NSString stringWithFormat:@"-ovolicon=%@", ((NSImage *) data[MNTIMAGE])]];
    
    //
    [self setOptions :options        :data :mount];
    [self setOptions :plugin.options :data :mount];
    
    //
    data[MOUNT] = mount;
    
    //
    [plugin.primaryObject epilogEdit:data];

    //
    if (data[EXTRAOPTIONS])
        [mount addObject:data[EXTRAOPTIONS]];
    
    
    //
    return 1;
}
//


//
//
-(void) acceptSheet :(amMap *) mp
{
    //
    pluginObject *plugin;
    if (!(plugin = filesystems[mp[PLUGIN]]))
        return;

    //
    if (![self epilogEdit:mp :plugin])
        return;


    //
    NSString *path;
    if (!(path = [self mountPath:mp[MNTNAME]]))
        return;
    
    //
    NSMutableDictionary *update;
    if ((update = [self selectedMount]))
    {
        if ([mp[MNTNAME] compare:update[MNTNAME]] != NSOrderedSame)
        {
            [self mountPath:update[MNTNAME]];
        }
    }
    
    //
    // Save the _mountPoint point out to the filesystem.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:mp];
    [data writeToFile:path atomically:NO];

    //
    switch ([_mountPoints selectionIndex])
    {
        case NSNotFound:
            [_mountPoints addObject : mp];
            break;
            
        default        :
            [update setDictionary:mp];
            break;
    }
    
    //
    mountPaths[mp[MNTPATH]] = mp;
    
    //
    [self volumeStatus:mp :NULL];
}
//

//
//
-(IBAction) segmentAction:(NSSegmentedControl *)sender
{
    //
    switch (sender.selectedSegment)
    {
        case 0: // New filesystem
            break;
        
        case 1: // Rem filesystem
            [self remMount:[self selectedMount]];
            break;
        
        case 2: // Actions.
            break;
    }
}
//

//
//
-(void)     remMount   :(NSDictionary *) mp
{
    if (!mp)
        return;
    
    // Delete the actual data
    [self mountPath:mp[MNTNAME]];
    
    //
    [_mountPoints remove:self];
}
//

//
//
-(void) edit :(amMap *) mp
{
    if (!mp)
        return;
    
    pluginObject *plugin;
    if (!(plugin = filesystems[mp[PLUGIN]]))
        return;
    
    //
    [self prologEdit:mp :plugin];
    
    //
    [_editorController setup :plugin.overlays :mp];
    
    
    //
    [_window beginSheet:_editorController.window completionHandler:^(NSModalResponse returnCode)
        {
            if (returnCode == NSModalResponseOK)
                [self acceptSheet:_editorController.mountPoint];
        }
    ];
}
//

//
//
-(IBAction) newMount :(NSMenuItem *) sender
{
    if (!self.editorController)
        return;
    
    //
    [_mountPoints setSelectionIndex:NSNotFound];
    
    //
    NSDictionary *mp = @{
                            PLUGIN           : ((pluginObject *) sender.representedObject).name,
                            MNTSTATUS        : [NSNumber numberWithBool:false],
                            MNTIMAGE         : ((pluginObject *) sender.representedObject).image.name,
                            SIERRA           : sierra,
                            
                            USERNAME         : NSUserName(),
                            HOST             : @"",
                            PATH             : @"",
                        };
    
    //
    [self edit :[amMap dictionaryWithDictionary:mp]];
}
//

//
//
-(IBAction) editMount :(NSButton *) sender
{
    //
    if (!self.editorController)
        return;
    
    NSMutableDictionary *mp;
    if (!(mp = [self selectedMount]))
        return;

    //
    if (!mp[USERNAME])
        mp[USERNAME] = NSUserName();
    
    if (!mp[HOST])
        mp[HOST]     = @"";
    
    if (!mp[PATH])
        mp[PATH]     = @"";
    
    //
    [self edit :mp];
}
//

@end
