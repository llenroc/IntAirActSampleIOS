//
//  InteractImageLoader.m
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-07.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import "IAImageLoader.h"
#import "IAImage.h"

#import "RKObjectManager+Blocks.h"
#import "RKClient+Blocks.h"

@implementation IAImageLoader

+ (void) getImages:(void (^)(NSArray *))block fromDevice:(IADevice *)device {
    dispatch_queue_t downloadQueue = dispatch_queue_create("interact image loader", NULL);
    dispatch_async(downloadQueue, ^{
        RKObjectManager * manager = [[RKObjectManager alloc] initWithBaseURL:device.hostAndPort];
        // Ask for & generate JSON
        manager.acceptMIMEType = RKMIMETypeJSON;
        manager.serializationMIMEType = RKMIMETypeJSON;
        
        // Create an ObjectMapping for the InteractImage class
        RKObjectMapping* imageMapping = [RKObjectMapping mappingForClass:[IAImage class]];
        [imageMapping mapKeyPath:@"name" toAttribute:@"name"];
        [imageMapping mapKeyPath:@"src" toAttribute:@"location"];
        
        // Register the mapping for receiving images from /images
        [manager.mappingProvider setMapping:imageMapping forKeyPath:@"images"];
        
        // Register the inverse mapping for sending images
        [manager.mappingProvider setSerializationMapping:[imageMapping inverseMapping] forClass:[IAImage class]];
        
        // Create a router that maps resource paths to request methods
        RKObjectRouter* router = [RKObjectRouter new];
        [router routeClass:[IAImage class] toResourcePath:@"/images" forMethod:RKRequestMethodPOST];
        [router routeClass:[IAImage class] toResourcePath:@"/images/(identifier)"];
        
        // Register the router
        manager.router = router;
        
        [manager loadObjectsAtResourcePath:@"/images" handler:^(RKObjectLoader *loader, NSError *error) {
            DDLogInfo(@"%@", loader.response.bodyAsString);
            DDLogInfo(@"%@", manager);
            DDLogInfo(@"%@", [[loader result] asCollection]);
            dispatch_async(dispatch_get_main_queue(), ^{
                block([[loader result] asCollection]);
            });
        }];
    });
    dispatch_release(downloadQueue);
}

+ (void) displayImage: (IAImage *) image onDevice: (IADevice *) device {
    dispatch_queue_t downloadQueue = dispatch_queue_create("interact image loader", NULL);
    dispatch_async(downloadQueue, ^{
        /*
        [device.client put:[self resourcePathFor:image withAction:@"display"] params:nil withCompletionHandler:^(RKResponse *response, NSError *error) {
            DDLogInfo(@"%@", response);
        }];
         */
    });
    dispatch_release(downloadQueue);
}

+ (NSString*)resourcePathFor:(NSObject*)resource withAction:(NSString*)action{
    NSString* path = [[RKObjectManager sharedManager].router resourcePathForObject:resource method:RKRequestMethodPUT];
    path = [path stringByAppendingString:@"/"];
    path = [path stringByAppendingString:action];
    return path;
}

@end
