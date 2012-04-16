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

-(NSString *)key {
    return @"images";
}

-(void)registerServer:(RoutingHTTPServer *)httpServer {
    [httpServer handleMethod:@"GET" withPath:@"/images" target:self selector:@selector(getImages:withResponse:)];

    [httpServer handleMethod:@"POST" withPath:@"/images" block:^(RouteRequest *request, RouteResponse *response) {
        DDLogVerbose(@"%@", request);
        [response setHeader:@"Content-Type" value:RKMIMETypeJSON];
        response.statusCode = 201;
    }];
    
    [httpServer handleMethod:@"PUT" withPath:@"/images/action" block:^(RouteRequest *request, RouteResponse *response) {
        DDLogVerbose(@"PUT /images/action");
        [response setHeader:@"Content-Type" value:RKMIMETypeJSON];
        response.statusCode = 201;
        NSData * body = [request body];
        NSString * bodyAsString = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];

        NSError* error = nil;
        id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:RKMIMETypeJSON];
        id parsedData = [parser objectFromString:bodyAsString error:&error];
        
        if (parsedData == nil && error) {
            // Parser error...
        } else {
            RKObjectMappingProvider* mappingProvider = self.interact.objectMappingProvider;
            RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:parsedData mappingProvider:mappingProvider];
            RKObjectMappingResult* result = [mapper performMapping];
            if (result) {
                IAImageAction * action = [result asObject];
                DDLogVerbose(@"%@", action.image);
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIMainStoryboardFile"] bundle: nil];
                IAImageViewController *t = [storyboard instantiateViewControllerWithIdentifier:@"ImageViewController"];
                t.interact = self.interact;
                t.image = action.image;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.navigationController pushViewController:t animated:YES];
                });
                /*
                UIViewController * c = [self.navigationController.childViewControllers lastObject];
                if([c respondsToSelector:@selector(setImage:)]) {
                    [c performSelector:@selector(setImage:) withObject:action.image];
                }
                 */
            }
        }
    }];
    
    [httpServer handleMethod:@"PUT" withPath:@"/images/:id" block:^(RouteRequest *request, RouteResponse *response) {
        DDLogVerbose(@"%@", request);
        [response setHeader:@"Content-Type" value:RKMIMETypeJSON];
        response.statusCode = 201;
    }];
    
    [httpServer handleMethod:@"DELETE" withPath:@"/images/:id" block:^(RouteRequest *request, RouteResponse *response) {
        DDLogVerbose(@"%@", request);
        [response setHeader:@"Content-Type" value:RKMIMETypeJSON];
        response.statusCode = 200;
    }];
    
    [httpServer handleMethod:@"GET" withPath:@"/images/:id.:type" block:^(RouteRequest *request, RouteResponse *response) {
        DDLogVerbose(@"%@", request);
        [response setHeader:@"Content-Type" value:@"image/jpeg"];
        
        NSNumber* number = [NSNumber numberWithInt:[[request param:@"id"] intValue]];
        NSData * data = [self.imageProvider imageAsData:number];
        if (!data) {
            response.statusCode = 500;
            DDLogError(@"An error ocurred.");
        } else {
            response.statusCode = 200;
            [response respondWithData:data];
            DDLogInfo(@"Responded with image");
        }
    }];
    
    [httpServer handleMethod:@"GET" withPath:@"/images/:id" block:^(RouteRequest *request, RouteResponse *response) {
        DDLogVerbose(@"%@", request);
        [response setHeader:@"Content-Type" value:RKMIMETypeJSON];
        
        NSNumber* number = [NSNumber numberWithInt:[[request param:@"id"] intValue]];
        IAImage* image = [self.imageProvider image:number];
        
        RKObjectSerializer* serializer = [self.interact serializerForObject:image];
        
        NSError* error = nil;
        id params = [serializer serializationForMIMEType:RKMIMETypeJSON error:&error];
        
        if (error) {
            response.statusCode = 500;
            DDLogError(@"Serializing failed for source object %@ to MIME Type %@: %@", image, RKMIMETypeJSON, [error localizedDescription]);
        } else {
            response.statusCode = 200;
            [response respondWithData:[params data]];
            DDLogInfo(@"%@", [[NSString alloc] initWithData:[params data] encoding:NSUTF8StringEncoding]);
        }
    }];
}

-(void)getImages:(RouteRequest *)request withResponse:(RouteResponse *)response {
    DDLogVerbose(@"%@", request);
    [response setHeader:@"Content-Type" value:RKMIMETypeJSON];
    
    IAImages * images = [IAImages new];
    images.images = self.imageProvider.images;

    RKObjectSerializer* serializer = [self.interact serializerForObject:images];
    
    NSError* error = nil;
    id params = [serializer serializationForMIMEType:RKMIMETypeJSON error:&error];
    
    if (error) {
        response.statusCode = 500;
        DDLogError(@"Serializing failed for source object %@ to MIME Type %@: %@", images, RKMIMETypeJSON, [error localizedDescription]);
    } else {
        response.statusCode = 200;
        [response respondWithData:[params data]];
        DDLogInfo(@"%@", [[NSString alloc] initWithData:[params data] encoding:NSUTF8StringEncoding]);
    }
}

@end
