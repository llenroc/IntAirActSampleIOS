#import "IAImageClient.h"

#import <RestKit/RestKit.h>

#import "IAInteract.h"
#import "IAAction.h"
#import "IADevice.h"
#import "IAImage.h"
#import "IAImages.h"

@interface IAImageClient ()

@property (nonatomic, strong) IAInteract * interact;

@end

@implementation IAImageClient

@synthesize interact = _interact;

+(void)setupMapping:(IAInteract *)interact
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

    RKObjectMapping * imageMapping = [RKObjectMapping mappingForClass:[IAImage class]];
    [imageMapping mapAttributes:@"identifier", nil];
    [interact.objectMappingProvider setMapping:imageMapping forKeyPath:@"images"];
    
    RKObjectMapping * imageSerialization = [imageMapping inverseMapping];
    imageSerialization.rootKeyPath = @"images";
    [interact.objectMappingProvider setSerializationMapping:imageSerialization forClass:[IAImage class]];
    
    // This is a workaround for serializing arrays of images, see https://github.com/RestKit/RestKit/issues/398
    RKObjectMapping * imagesSerialization = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [imagesSerialization hasMany:@"images" withMapping:imageSerialization];
    [interact.objectMappingProvider setSerializationMapping:imagesSerialization forClass:[IAImages class]];
    
    // setup routes
    [interact.router routeClass:[IAImage class] toResourcePath:@"/image/:identifier"];
}

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
    
    [self.interact loadObjectsAtResourcePath:@"/images" fromDevice:device handler:^(RKObjectLoader *loader, NSError *error) {
        if(!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block([[loader result] asCollection]);
            });
        } else {
            DDLogError(@"An error ocurred while getting images: %@", error);
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
