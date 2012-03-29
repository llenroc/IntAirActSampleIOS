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

@interface IAImageClient ()

@property (nonatomic, strong) IAInteract * interact;

@end

@implementation IAImageClient

+ (void) setupMapping:(IAInteract *)interact
{
    RKObjectMapping* imageMapping = [RKObjectMapping mappingForClass:[IAImage class]];
    imageMapping.rootKeyPath = @"images";
    
    [imageMapping mapKeyPath:@"id" toAttribute:@"identifier"];
    [imageMapping mapKeyPath:@"name" toAttribute:@"name"];
    [imageMapping mapKeyPath:@"src" toAttribute:@"location"];
    
    RKObjectMapping* imageSerialization = [imageMapping inverseMapping];
    imageSerialization.rootKeyPath = @"images";
    
    [interact.objectMappingProvider setMapping:imageMapping forKeyPath:@"images"];
    [interact.objectMappingProvider setSerializationMapping:imageSerialization forClass:[IAImage class]];
    
    RKObjectMapping* imagesMapping = [RKObjectMapping mappingForClass:[IAImages class]];
    [imagesMapping hasMany:@"images" withMapping:imageMapping];
    RKObjectMapping* imagesSerialization = [imagesMapping inverseMapping];
    [interact.objectMappingProvider setSerializationMapping:imagesSerialization forClass:[IAImages class]];
    
    // setup routes
    [interact.router routeClass:[IAImage class] toResourcePath:@"/images" forMethod:RKRequestMethodPOST];
    [interact.router routeClass:[IAImage class] toResourcePath:@"/images/(identifier)"];

}

@synthesize interact = _interact;

- (id)initWithInteract:(IAInteract *)interact
{
    self = [super init];
    if (self) {
        self.interact = interact;
    }
    return self;
}

- (void) getImages:(void (^)(NSArray *))block fromDevice:(IADevice *)device {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    dispatch_queue_t downloadQueue = dispatch_queue_create("interact image loader", NULL);
    dispatch_async(downloadQueue, ^{
        RKObjectManager * manager = [self.interact objectManagerForDevice:device];
        [manager loadObjectsAtResourcePath:@"/images" handler:^(RKObjectLoader *loader, NSError *error) {
#warning find out why i have to use manager inside block to keep manager object "alive"
            // i know why but I have to read on block pointers to resolve this properly
            DDLogVerbose(@"%@", manager);
            if(!error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block([[loader result] asCollection]);
                });
            } else {
                DDLogError(@"%@", error);
            }
        }];
    });
    dispatch_release(downloadQueue);
}

- (void) displayImage: (IAImage *) image onDevice: (IADevice *) device {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    dispatch_queue_t downloadQueue = dispatch_queue_create("interact image loader", NULL);
    dispatch_async(downloadQueue, ^{
        RKObjectManager * manager = [self.interact objectManagerForDevice:device];
        RKClient * client = manager.client;
        [client put:[self.interact resourcePathFor:image withAction:@"display" forObjectManager:manager] params:nil withCompletionHandler:^(RKResponse *response, NSError *error) {
            // somehow I have to resolve this unnecessary output
            DDLogVerbose(@"%@", manager);
            if(!error) {
                DDLogInfo(@"%@", response);
            } else {
                DDLogError(@"%@", error);
            }
        }];
    });
    dispatch_release(downloadQueue);
}

@end
