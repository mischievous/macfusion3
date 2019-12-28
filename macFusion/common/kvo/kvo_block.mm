#import "kvo_block.h"
#import <objc/runtime.h>

#define ASSOCIATED_OBJ_OBSERVERS_KEY @"rayh_block_based_observers"
#define ASSOCIATED_OBJ_OBSERVING_KEY @"rayh_block_based_observing"

@interface WSObservationBinding ()
@property (nonatomic, assign) BOOL valid;
@property (nonatomic, assign) id owner;
@property (nonatomic, retain) NSString *keyPath;
@property (nonatomic, copy) WSObservationBlock block;
@property (nonatomic, assign) id observed;
@property (nonatomic, assign) id context;
@end

@implementation WSObservationBinding 
@synthesize valid=valid_;
@synthesize block=block_;
@synthesize observed=observed_;
@synthesize context=context_;
@synthesize keyPath=keyPath_;
@synthesize owner=owner_;

- (id)init {
    if((self = [super init])) {
        self.valid = YES;
    }
    return self;
    
}
- (void)dealloc {
    if(self.valid)
        [self invalidate];
    
    self.block = nil;
    self.keyPath = nil;
//    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)path 
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context
{
    if(self.valid && ![[change valueForKey:NSKeyValueChangeNewKey] isEqual:[change valueForKey:NSKeyValueChangeOldKey]]) 
        self.block(self.observed, change, self.context, self);
}

- (void)invalidate
{
    [self.observed removeObserver:self forKeyPath:self.keyPath];
    self.valid = NO;
}

- (void)invoke 
{
    self.block(self.observed, [NSDictionary dictionary], self.context, self);
}
@end

@implementation NSObject (WSObservation)

-(NSMutableArray*)allBlockBasedObservations
{
	NSMutableArray *objects = objc_getAssociatedObject(self, (__bridge void *) ASSOCIATED_OBJ_OBSERVING_KEY);
    if(!objects) {
        objects = [NSMutableArray array];
        objc_setAssociatedObject(self, (__bridge void *) ASSOCIATED_OBJ_OBSERVING_KEY, objects, OBJC_ASSOCIATION_RETAIN);
    }
    
    return objects;
}

- (void)removeAllObservationsOn:(id)object
{
    for(WSObservationBinding *binding in [NSArray arrayWithArray:[self allBlockBasedObservations]]) {
        if([binding.observed isEqual:object]) {
            [binding invalidate];
            [[self allBlockBasedObservations] removeObject:binding];
        }
    }
}

- (void)removeAllObservations
{
    for(WSObservationBinding *binding in [NSArray arrayWithArray:[self allBlockBasedObservations]]) {
        [binding invalidate];
        [[self allBlockBasedObservations] removeObject:binding];
    }
}


- (void)removeAllObserverationsOn:(id)object keyPath:(NSString*)keyPath
{
    for(WSObservationBinding *binding in [NSArray arrayWithArray:[self allBlockBasedObservations]]) {
        if([binding.observed isEqual:object] && [binding.keyPath isEqualToString:keyPath]) {
            [binding invalidate];
            [[self allBlockBasedObservations] removeObject:binding];
        }
    }
}

-(WSObservationBinding*)observe:(id)object 
                   keyPath:(NSString *)keyPath
                   options:(NSKeyValueObservingOptions)options 
                   context:(id) context
                     block:(WSObservationBlock)block 
{
    WSObservationBinding *binding = [[WSObservationBinding alloc] init];
    binding.block    = block;
    binding.observed = object;
    binding.keyPath  = keyPath;
    binding.owner    = self;
    binding.context  = context;
    
    [[self allBlockBasedObservations] addObject:binding];
    
    [object addObserver:binding forKeyPath:keyPath options:options context:nil];
    
    return binding;
}

-(WSObservationBinding*)observe:(id)object 
                        keyPath:(NSString *)keyPath
                        context:(id) context
                          block:(WSObservationBlock)block 
{
    
    return [self observe:object 
                 keyPath:keyPath 
                 options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld 
                 context:context
                   block:block];
}
- (NSMutableArray *) bind:(id)source keyPath:(NSString *)sourcePath to:(id) target keyPath:(NSString *)targetPath addReverseBinding:(BOOL)addReverseBinding {
    NSMutableArray *bindings = [[NSMutableArray alloc] init];
    
    [bindings addObject:[self observe:source keyPath:sourcePath context:NULL block:^(id observed, NSDictionary *change, id context, id binding) {
        [target setValue:[change valueForKey:NSKeyValueChangeNewKey] forKey:targetPath];
    }]];
    
    if (addReverseBinding) {
        [bindings addObject:[self observe:target keyPath:targetPath context:NULL block:^(id observed, NSDictionary *change, id context, id binding) {
            [source setValue:[change valueForKey:NSKeyValueChangeNewKey] forKey:sourcePath];
        }]];
    }

    return bindings;
}

@end

@implementation NSObject (KVOBlockBinding)

-(NSMutableArray*)allBlockBasedObservers
{
	NSMutableArray *objects = objc_getAssociatedObject(self, (__bridge void *) ASSOCIATED_OBJ_OBSERVERS_KEY);
    if(!objects) {
        objects = [NSMutableArray array];
        objc_setAssociatedObject(self, (__bridge void *) ASSOCIATED_OBJ_OBSERVERS_KEY, objects, OBJC_ASSOCIATION_RETAIN);
    }
        
    return objects;
}

- (void)removeAllBlockBasedObserversForKeyPath:(NSString*)keyPath
{
    for(WSObservationBinding *binding in [NSArray arrayWithArray:[self allBlockBasedObservers]]) {
        if([binding.keyPath isEqualToString:keyPath]) {
            [binding invalidate];
            [[self allBlockBasedObservers] removeObject:binding];
        }
    }
}

- (void)removeAllBlockBasedObservers
{
    for(WSObservationBinding *binding in [NSArray arrayWithArray:[self allBlockBasedObservers]]) {
        [binding invalidate];
        [[self allBlockBasedObservers] removeObject:binding];
    }
}

- (void)removeAllBlockBasedObserversForOwner:(id)owner
{
    for(WSObservationBinding *binding in [NSArray arrayWithArray:[self allBlockBasedObservers]]) {
        if([binding.owner isEqual:owner]) {
            [binding invalidate];
            [[self allBlockBasedObservers] removeObject:binding];
        }
    }
}

-(WSObservationBinding*)addObserverForKeyPath:(NSString*)keyPath 
                                   owner:(id)owner 
                                 options:(NSKeyValueObservingOptions)options 
                                 context:context
                                   block:(WSObservationBlock)block 
{
    WSObservationBinding *binding = [[WSObservationBinding alloc] init];
    binding.block    = block;
    binding.observed = self;
    binding.keyPath  = keyPath;
    binding.owner    = owner;
    binding.context  = context;
        
    [[self allBlockBasedObservers] addObject:binding];
    
    [self addObserver:binding forKeyPath:keyPath options:options context:nil];
    
    return binding;
}

-(WSObservationBinding*)addObserverForKeyPath:(NSString*)keyPath  
                                   owner:(id)owner 
                                   context:context
                                   block:(WSObservationBlock)block 
{
    return [self addObserverForKeyPath:keyPath  
                                 owner:owner 
                               options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld 
                               context:context
                                 block:block];
}

@end