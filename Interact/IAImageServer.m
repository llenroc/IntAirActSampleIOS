//
//  InteractImageServerMapper.m
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-08.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import "IAImageServer.h"

#import <RestKit/RestKit.h>
#import <RoutingHTTPServer/RoutingHTTPServer.h>

#import "IAInteract.h"
#import "IAImages.h"
#import "IAImageProvider.h"
#import "IAImageAction.h"
#import "IAImageViewController.h"
#import "RouteResponse+Serializer.h"

@interface IAImageServer ()

@property (strong, nonatomic) IAInteract* interact;
@property (strong, nonatomic) IAImageProvider* imageProvider;

@end

@implementation IAImageServer

@synthesize navigationController = _navigationController;

@synthesize interact = _interact;
@synthesize imageProvider = _imageProvider;

-(id)initWithInteract:(IAInteract *)interact
{
    self = [super init];
    if (self) {
        self.interact = interact;
        self.imageProvider = [IAImageProvider new];
        [self registerServer:interact.httpServer];
    }
    return self;
}

-(void)registerServer:(RoutingHTTPServer *)app {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    [app setDefaultHeader:@"Content-Type" value:RKMIMETypeJSON];
    
    [app get:@"/images" withBlock:^(RouteRequest *request, RouteResponse *response) {
        DDLogVerbose(@"GET /images");

        IAImages * images = [IAImages new];
        images.images = self.imageProvider.images;
        [response respondWith:images withInteract:self.interact];
    }];
    
    [app put:@"/action" withBlock:^(RouteRequest *request, RouteResponse *response) {
        DDLogVerbose(@"PUT /action");

        RKObjectMappingResult * result = [self.interact deserializeObject:[request body]];
        if(!result && [[result asObject] isKindOfClass:[IAImageAction class]]) {
            DDLogError(@"Could not parse request body: %@", [request body]);
            response.statusCode = 500;
        } else {
            response.statusCode = 201;
            IAImageAction * action = [result asObject];
            DDLogVerbose(@"%@", action);
            
            // Show image
            UIStoryboard * storyboard = [UIStoryboard storyboardWithName:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIMainStoryboardFile"] bundle: nil];
            IAImageViewController * t = [storyboard instantiateViewControllerWithIdentifier:@"ImageViewController"];
            t.interact = self.interact;
            t.device = action.device;
            t.image = action.image;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.navigationController pushViewController:t animated:YES];
            });
        }
    }];
    
    [app get:@"/image/:id.jpg" withBlock:^(RouteRequest *request, RouteResponse *response) {
        DDLogVerbose(@"GET /image/%@.jpg", [request param:@"id"]);
        
        NSNumber* number = [NSNumber numberWithInt:[[request param:@"id"] intValue]];
        NSData * data = [self.imageProvider imageAsData:number];
        if (!data) {
            DDLogError(@"An error ocurred.");
            response.statusCode = 500;
        } else {
            response.statusCode = 200;
            [response setHeader:@"Content-Type" value:@"image/jpeg"];
            [response respondWithData:data];
        }
    }];
}

@end
