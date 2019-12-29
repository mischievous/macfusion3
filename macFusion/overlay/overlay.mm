//
//  overview.m
//  macFusion
//
//  Created by Alexandra Beebe on 1/6/17.
//  Copyright © 2017 Alexandra Beebe. All rights reserved.
//


//
#define HIDDEN (28)

//
#import "overlay.h"

NSMutableDictionary *overlays;

//
@interface overlay ()
{
    //
    NSView      *mainView;
    NSView      *overlay;
    
    //
    CGFloat     _height;
    
    //
    id        target;
    SEL       action;

}

//
@property NSString *sectionName;

//
-(IBAction) refreshHeight :(overlay  *) sender;

@end


@implementation overlay

+(void    ) initialize
{
    if (self == [overlay class])
    {
        overlays = [NSMutableDictionary dictionaryWithCapacity:0];
    }
}


//
//
+(NSView *) loadView :(NSString *) nibName :(NSBundle *) bundle :(id) owner
{
    //
    NSNib *nib = [[NSNib alloc] initWithNibNamed:nibName bundle:bundle];
    if (!nib)
        return NULL;
    
    //
    NSArray *topLevelObjects;
    if (! [nib instantiateWithOwner:owner topLevelObjects:&topLevelObjects])
        return NULL;
    
    //
    for (id topLevelObject in topLevelObjects)
    {
        //
        if ([topLevelObject isKindOfClass:[NSView class]])
            return topLevelObject;
    }
    
    return NULL;
}
//

//
//
+(overlay *) factory    :(NSString *) nibName :(NSBundle *) bundle :(id) owner
{
    //
    if (overlays[nibName])
        return overlays[nibName];

    //
    overlay *object;
    if (!(object = [overlay new]))
        return NULL;

    //
    object->overlay   = [overlay loadView:nibName    :bundle                :owner];
    object->mainView  = [overlay loadView:@"overlay" :[NSBundle mainBundle] :object];
    
    //
    if (owner)
    {
        SEL action = @selector(refreshHeight:);
        if ([owner respondsToSelector:action])
        {
            object->target    = owner;
            object->action    = action;
        }
    }
    
    //
    object->_view     = object->mainView;
                         
    //
    [object awake];

    //
    overlays[nibName] = object;
    
    //
    return object;
}
//


//
//
-(void) awake
{
    //
    self.hidden       = 0;
    self.hiddenStatus = @"hide";
    
    //
    self.sectionName = [overlay identifier];
    
    //
    NSSize frameSize = overlay.frame.size;
    frameSize.height += HIDDEN;
    
    //
    [mainView setFrameSize: frameSize]; //overlay.frame.size];
    _height           = NSHeight(mainView.frame);
    
    //
    //[mainView addSubview:overlay];
    //[mainView addSubview:overlay positioned:NSWindowBelow relativeTo:NULL];
    [_child addSubview:overlay];
}
//

//
//
-(IBAction) refreshHeight :(overlay  *) sender
{
}
//

//
//
-(IBAction) toggleDisplay:(NSButton *) sender
{
    self.hidden       = 1 - self.hidden;
    self.hiddenStatus = (self.hidden) ? @"show" : @"hide";
    
    if (overlay)
    {
        [overlay setHidden: self.hidden];
    }

    NSLog (@"%@", target);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

    if ((target) && (action))
        [target performSelector:action withObject:self];
#pragma clang diagnostic pop

}
//

//
//
-(CGFloat) height
{
    // NSLog (@"%s : %f", __FUNCTION__,  (hidden) ? HIDDEN : NSHeight(overlay.frame));
    return (self.hidden) ? HIDDEN : _height;
}
//


@end
