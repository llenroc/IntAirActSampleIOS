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
    
    [app put:@"/images/action" withBlock:^(RouteRequest *request, RouteResponse *response) {
        DDLogVerbose(@"PUT /images/action");
        RKObjectMappingResult * result = [self parseObject:[request body]];
        if(!result) {
            response.statusCode = 500;
        } else {
            response.statusCode = 201;
            IAImageAction * action = [result asObject];
            DDLogVerbose(@"%@", action.image);
            
            // Show image
            UIStoryboard * storyboard = [UIStoryboard storyboardWithName:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIMainStoryboardFile"] bundle: nil];
            IAImageViewController * t = [storyboard instantiateViewControllerWithIdentifier:@"ImageViewController"];
            t.interact = self.interact;
            t.image = action.image;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.navigationController pushViewController:t animated:YES];
            });
        }
    }];
    
    [app get:@"/images/:id.:type" withBlock:^(RouteRequest *request, RouteResponse *response) {
        DDLogVerbose(@"GET /images/%@.%@", [request param:@"id"], [request param:@"type"]);
        
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
    
    [app get:@"/images/:id" withBlock:^(RouteRequest *request, RouteResponse *response) {
        DDLogVerbose(@"GET /images/%@", [request param:@"id"]);
        
        NSNumber* number = [NSNumber numberWithInt:[[request param:@"id"] intValue]];
        IAImage* image = [self.imageProvider image:number];
        [response respondWith:image withInteract:self.interact];
    }];
}

-(RKObjectMappingResult*)parseObject:(NSData*)data
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    NSString * bodyAsString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSError* error = nil;
    id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:RKMIMETypeJSON];
    id parsedData = [parser objectFromString:bodyAsString error:&error];
    
    if (parsedData == nil && error) {
        // Parser error...
        DDLogError(@"An error ocurred: %@", error);
        return NULL;
    } else {
        RKObjectMappingProvider* mappingProvider = self.interact.objectMappingProvider;
        RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:parsedData mappingProvider:mappingProvider];
        RKObjectMappingResult* result = [mapper performMapping];
        return result;
    }
}

@end
