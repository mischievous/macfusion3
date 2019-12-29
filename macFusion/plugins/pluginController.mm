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
void callback (SCDynamicStoreRef store, CFArrayRef changedKeys, void *info)
{
    pluginController *pc = (__bridge pluginController *) info;
    
    for (NSString *key in (__bridge NSArray *) changedKeys)
    {
        //NSString *interface = [key componentsSeparatedByString:@"/"][3];
        NSString *address   = NULL;
    
        CFPropertyListRef value;
        if ((value = SCDynamicStoreCopyValue(store, (__bridge CFStringRef) key)))
            address = ((__bridge NSDictionary *) value)[@"Addresses"][0];

        //
        [pc autoMount:key :address];
        
        //
        if (value)
            CFRelease (value);
    }
}
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
    
    //
    SCDynamicStoreContext  contex;
    SCDynamicStoreRef      networkWatcher;

    
}

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

        //
        if ([data[LNCHMNT] boolValue])
            [self __mount:data :NULL :NULL];
        
    }
    
    //
    contex         = {0, (__bridge void *)(self), NULL, NULL, NULL};
    networkWatcher = SCDynamicStoreCreate (NULL, (__bridge CFStringRef) @"macFusion3", callback, &contex );
    NSLog (@"%p : %@", self, networkWatcher);
    
    //
    SCDynamicStoreSetNotificationKeys(networkWatcher, NULL, (__bridge CFArrayRef) @[@"State:/Network/Interface/.*/IPv4"]);
    
    //
    CFRunLoopAddSource(CFRunLoopGetCurrent(), SCDynamicStoreCreateRunLoopSource(NULL, networkWatcher, 0), kCFRunLoopCommonModes);
    
    //
    const void *matchAllAdapters = CFSTR("State:/Network/Interface/.*/IPv4");
    CFArrayRef      patterns = CFArrayCreate(kCFAllocatorDefault, &matchAllAdapters, 1, &kCFTypeArrayCallBacks);
    
    CFDictionaryRef snapshot = SCDynamicStoreCopyMultiple(networkWatcher, NULL, patterns);
    
    //
    [(__bridge NSDictionary *) snapshot enumerateKeysAndObjectsUsingBlock: ^(NSString *key, NSDictionary *val, BOOL *stop)
        {
            //
            [self autoMount:key :val[@"Addresses"  ][0]];
        }
     ];
    
    //
    CFRelease (patterns);
    CFRelease (snapshot);
}
//

//
//
-(void) volumeStatus :(NSMutableDictionary *) data :(NSDictionary *) mp
{
    //
    if (data)
    {
//        NSLog (@"%lu : %s", (unsigned long)[mountActive indexOfObject:data[MNTPATH]], __FUNCTION__);
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
    // https://stackoverflow.com/questions/34552164/unmount-disk-in-osx-with-diskarbitration
    
    //
    NSDictionary *mp;
    if (!(mp = [self selectedMount]))
        return;

    //
    [self performSelectorInBackground:@selector(__unmount:) withObject:mp];

//    [self __unmount:mp];
}
//

//
//
-(IBAction) performMount     :(NSButton *) sender
{
    NSDictionary *mp;
    if (!(mp = [self selectedMount]))
        return;
    
    //
    [self performSelectorInBackground:@selector(__background_mount:) withObject:mp];
}
//


//
//
-(void) __unmount :(NSDictionary *) mp
{
    NSLog (@"+__unmount : %@", mp[MNTPATH]);

    //
    NSError *error;
    if ([[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtURL:[NSURL fileURLWithPath: mp[MNTPATH]] error:&error] == 0)
        NSLog (@"unmounting %@ : %@", mp[MNTPATH], error);
    
    NSLog (@"-__unmount");
}
//

//
//
-(void) __background_mount :(NSDictionary *) mp
{
    [self __mount :mp :NULL :NULL];
}
//


//
//
-(void) __mount :(NSDictionary *) mp :(NSString *) interface :(NSString *) bindAddress
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
    NSArray *mount;
    if (!(mount = [plugin.primaryObject mount:mp :bindAddress]))
        return;

    //
    NSString *output;
    if ((output = executeTask (plugin.executable, mount, 0 )))
    {
        //
        if ( [plugin.primaryObject respondsToSelector:@selector(callback::)] )
            [((NSObject <macfusion> *) plugin.primaryObject) callback :mp :output];
    }
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
    if (![bundle load])
        return NULL;
    
    //
    if (! [[bundle principalClass] conformsToProtocol:@protocol (macfusion)] )
        return NULL;
    
    
    // verify the "filesystem" matches the actual protocol
    NSDictionary *fileSystem;
    if (!(fileSystem = [bundle objectForInfoDictionaryKey:@"fileSystem"]))
        return NULL;
    
    
    // If the fileSystem uses an executable make sure it exists...
    if (![[NSFileManager defaultManager] fileExistsAtPath:[fileSystem objectForKey:@"executable"]])
        return NULL;

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

    // Honor the order of the "nibs", since its an array the order can be re-configured...
    for (NSString *nibName in [fileSystem objectForKey:@"nibs"])
    {
        uint64_t masterBundle = ([@[@"automount", @"credentials", @"macfusion", @"mountpoint"] indexOfObject:nibName] != NSNotFound) ? 1:0;

        //
        overlay *ol;

        //
        if ((ol = [overlay factory :nibName :(masterBundle) ? [NSBundle mainBundle]:bundle :_editorController]))
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
-(NSMutableDictionary *) selectedMount
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
    if (!data[MNTNAME])
        return 0;

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
    if ([data[NTWKMNT] boolValue])
    {
        data[NETMASK] = @0;
        data[NTWKMNT] = (((NSString *) data[NETWORK]).length) ? @1:@0;
    }

    //
    if ([data[NTWKMNT] boolValue])
    {
        uint32_t bits        = 0;

    
        //
        NSArray *a = [data[NETWORK] componentsSeparatedByString:@"/"];
        if (a.count == 2)
            bits = atoi ([a[1] UTF8String]);

        //
        uint32_t count       = 32 - bits;
        

    
        //
        uint32_t networkMask = ((count != 32) ? (1 << count) - 1 : 0xffffffff) << bits;
        uint32_t networkAddr = [self networkAddress:a[0] :networkMask];
            
        //
        data[NETMASK] = [NSNumber numberWithUnsignedInteger:networkMask];
        data[NETADDR] = [NSNumber numberWithUnsignedInteger:networkAddr];
    }
    
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
-(void) acceptSheet :(NSMutableDictionary *) mp
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
-(void) edit :(NSMutableDictionary *) mp
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
    NSMutableDictionary *mp = [NSMutableDictionary dictionaryWithCapacity:0];

    //
    mp[PLUGIN   ] = ((pluginObject *) sender.representedObject).name;
    mp[MNTSTATUS] = @0;
    mp[MNTIMAGE ] = ((pluginObject *) sender.representedObject).image.name;
    mp[SIERRA   ] = sierra;
    mp[USERNAME ] = NSUserName();
    mp[HOST     ] = @"";
    mp[PATH     ] = @"";
    
    //
    [self edit :[NSMutableDictionary dictionaryWithDictionary:mp]];
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


#pragma mark network

//
//
-(uint32_t) networkAddress :(NSString *) data :(uint32_t) mask
{
    //
    NSArray *octets = [data componentsSeparatedByString:@"."];
    
    //
    unsigned int address = 0;
    
    //
    for (NSString *octet in octets)
        address = (address << 8) | atoi ([octet UTF8String]);
    
    //
    uint32_t bits = 8 * (4 - (uint32_t) octets.count);
    
    //    //
    //    while (bits)
    //        { address = (address << 1) | 1; bits -= 1;}
    
    //
    return ((address << bits) & mask);
}
//


#pragma mark automount

//
//
-(bool) mountInterface :(NSDictionary *) mp :(NSString *) data
{
    if (![mp[INTFMNT] boolValue])
        return 0;

    //
    return ([data caseInsensitiveCompare:mp[INTERFACE]] == NSOrderedSame) ? 1:0;
}
//

//
//
-(bool) mountNetwork   :(NSDictionary *) mp :(NSString *) data
{
    if (![mp[NTWKMNT] boolValue])
        return 0;
    
    //
    uint32_t networkMask = (uint32_t) [mp[NETMASK] unsignedIntegerValue];
    uint32_t networkAddr = (uint32_t) [mp[NETADDR] unsignedIntegerValue];
    
    //
    unsigned int address = [self networkAddress:data :networkMask];
    
    //
    return ((address & networkMask) == networkAddr) ? 1:0;
}
//

//
//
-(void) autoMount:(NSString *)key :(NSString *) address
{
    //
    NSString *interface = [key componentsSeparatedByString:@"/"][3];

    // This interface has left... need to unmount everything...
    if (address == NULL)
    {
        NSLog (@"%p : %@\n", autoMounts[interface], interface );
    
        //
        if (autoMounts[interface] != NULL)
        {
            for (NSDictionary *mp in autoMounts[interface])
                [self __unmount:mp];
            
        
            //
            [autoMounts removeObjectForKey:interface];
        }
        
        //
        return;
    }
    
    
    //
    for (NSDictionary *mp in _mountPoints.content)
    {
        // Already mounted.
        if ([mp[MNTSTATUS] boolValue])
            continue;
    
        BOOL mount = 0;
        
        //
        mount |= [self mountInterface:mp :interface];
        mount |= [self mountNetwork  :mp :address  ];
        
        // Check for mount...
        if (!mount)
            continue;
    
        NSLog (@"Automounting : %@ : %@", mp[MNTNAME], interface);
    
        //
        [self __mount:mp :interface :address];
    }
    
}
//



@end
