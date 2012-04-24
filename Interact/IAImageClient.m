#import "IAImageClient.h"

#import <RestKit+Blocks/RKObjectManager+Blocks.h>
#import <RestKit+Blocks/RKClient+Blocks.h>

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
    
    dispatch_queue_t queue = dispatch_queue_create("IAImageClient getImages", NULL);
    dispatch_async(queue, ^{
        RKObjectManager * manager = [self.interact objectManagerForDevice:device];
        [manager loadObjectsAtResourcePath:@"/images" handler:^(RKObjectLoader *loader, NSError *error) {
            if(!error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block([[loader result] asCollection]);
                });
            } else {
                DDLogError(@"An error ocurred while getting images: %@", error);
            }
        }];
    });
    dispatch_release(queue);
}

-(void)displayImage:(IAImage *)image ofDevice:(IADevice *)source onDevice:(IADevice *)target
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    dispatch_queue_t queue = dispatch_queue_create("IAImageClient displayImage", NULL);
    dispatch_async(queue, ^{
        RKObjectManager * manager = [self.interact objectManagerForDevice:target];
        IAAction * action = [IAAction new];
        action.action = @"displayImage";
        NSDictionary * imageData = [[self.interact serializerForObject:image] serializedObject:nil];
        NSDictionary * sourceDeviceData = [[self.interact serializerForObject:source] serializedObject:nil];
        action.parameters = [NSDictionary dictionaryWithKeysAndObjects:@"image", imageData, @"device", sourceDeviceData, nil];
        [manager putObject:action delegate:nil];
    });
    dispatch_release(queue);
}

@end
