//
//  InteractImageLoader.m
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-07.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import "IAImageClient.h"

#import <RestKit+Blocks/RKObjectManager+Blocks.h>
#import <RestKit+Blocks/RKClient+Blocks.h>

#import "IAInteract.h"
#import "IAImages.h"
#import "IAImage.h"
#import "IAImageAction.h"

@interface IAImageClient ()

@property (nonatomic, strong) IAInteract * interact;

@end

@implementation IAImageClient

+(void)setupMapping:(IAInteract *)interact
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

    RKObjectMapping* imageMapping = [RKObjectMapping mappingForClass:[IAImage class]];
    imageMapping.rootKeyPath = @"images";
    [imageMapping mapKeyPath:@"id" toAttribute:@"identifier"];
    [imageMapping mapKeyPath:@"name" toAttribute:@"name"];
    [imageMapping mapKeyPath:@"src" toAttribute:@"location"];
    [interact.objectMappingProvider setMapping:imageMapping forKeyPath:@"images"];
    
    RKObjectMapping* imageSerialization = [imageMapping inverseMapping];
    imageSerialization.rootKeyPath = @"images";
    [interact.objectMappingProvider setSerializationMapping:imageSerialization forClass:[IAImage class]];
    
    RKObjectMapping* imagesMapping = [RKObjectMapping mappingForClass:[IAImages class]];
    [imagesMapping hasMany:@"images" withMapping:imageMapping];
    RKObjectMapping* imagesSerialization = [imagesMapping inverseMapping];
    [interact.objectMappingProvider setSerializationMapping:imagesSerialization forClass:[IAImages class]];
    
    RKObjectMapping * actionMapping = [RKObjectMapping mappingForClass:[IAImageAction class]];
    actionMapping.rootKeyPath = @"actions";
    [actionMapping mapKeyPath:@"action" toAttribute:@"action"];
    [actionMapping hasOne:@"image" withMapping:imageMapping];
    [interact.objectMappingProvider setMapping:actionMapping forKeyPath:@"actions"];
    
    RKObjectMapping * actionSerialization = [actionMapping inverseMapping];
    actionSerialization.rootKeyPath = @"actions";
    [interact.objectMappingProvider setSerializationMapping:actionSerialization forClass:[IAImageAction class]];
    
    // setup routes
    [interact.router routeClass:[IAImage class] toResourcePath:@"/images" forMethod:RKRequestMethodPOST];
    [interact.router routeClass:[IAImage class] toResourcePath:@"/images/:identifier"];
    [interact.router routeClass:[IAImageAction class] toResourcePath:@"/images/action" forMethod:RKRequestMethodPUT];
}

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

-(void)displayImage:(IAImage *)image onDevice:(IADevice *)device
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    dispatch_queue_t queue = dispatch_queue_create("IAImageClient displayImage", NULL);
    dispatch_async(queue, ^{
        RKObjectManager * manager = [self.interact objectManagerForDevice:device];
        IAImageAction * action = [IAImageAction new];
        action.action = @"display";
        action.image = image;
        [manager putObject:action delegate:nil];
    });
    dispatch_release(queue);
}

@end
