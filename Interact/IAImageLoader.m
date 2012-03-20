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

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation IAImageLoader

+ (void) getImages:(void (^)(NSArray *))block fromDevice:(InteractDevice *)device {
    dispatch_queue_t downloadQueue = dispatch_queue_create("interact image loader", NULL);
    dispatch_async(downloadQueue, ^{
        [device.manager loadObjectsAtResourcePath:@"/images" handler:^(RKObjectLoader *loader, NSError *error) {
            DDLogInfo(@"%@", [[loader result] asCollection]);
            dispatch_async(dispatch_get_main_queue(), ^{
                block([[loader result] asCollection]);
            });
        }];
    });
    dispatch_release(downloadQueue);
}

+ (void) displayImage: (InteractImage *) image onDevice: (InteractDevice *) device {
    dispatch_queue_t downloadQueue = dispatch_queue_create("interact image loader", NULL);
    dispatch_async(downloadQueue, ^{
        [device.client put:[self resourcePathFor:image withAction:@"display"] params:nil withCompletionHandler:^(RKResponse *response, NSError *error) {
            DDLogInfo(@"%@", response);
        }];
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
