#import "IAImageClient.h"

#import <CocoaLumberjack/DDLog.h>
#import <Interact/IAAction.h>
#import <Interact/IADevice.h>
#import <Interact/IAInteract.h>
#import <RestKit/RestKit.h>
#import <RestKit+Blocks/RKObjectManager+Blocks.h>

#import "IAImage.h"
#import "IAImages.h"

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_WARN;

@interface IAImageClient ()

@property (nonatomic, strong) IAInteract * interact;

@end

@implementation IAImageClient

@synthesize interact = _interact;

-(id)initWithInteract:(IAInteract *)interact
{
    self = [super init];
    if (self) {
        self.interact = interact;
    }
    return self;
}

-(void)getImages:(void(^)(NSArray *))block fromDevice:(IADevice *)device
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    RKObjectManager * manager = [self.interact objectManagerForDevice:device];
    [manager loadObjectsAtResourcePath:@"/images" handler:^(RKObjectLoader *loader, NSError *error) {
        if(!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block([[loader result] asCollection]);
            });
        } else {
            DDLogError(@"%@: An error ocurred while getting images: %@", THIS_FILE, error);
        }
    }];
}

-(void)displayImage:(IAImage *)image ofDevice:(IADevice *)source onDevice:(IADevice *)target
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    IAAction * action = [IAAction new];
    action.action = @"displayImage";
    action.parameters = [NSDictionary dictionaryWithObjectsAndKeys:image, @"image", source, @"device", nil];
    [self.interact callAction:action onDevice:target];
}

@end
