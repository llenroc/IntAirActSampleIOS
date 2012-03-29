//
//  InteractImageServerMapper.m
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-08.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import "IAImageServerMapper.h"
#import <RoutingHTTPServer/RoutingHTTPServer.h>

@interface IAImageServerMapper() {
    RoutingHTTPServer *httpServer;
}

@end

@implementation IAImageServerMapper

@synthesize imageServer = _imageServer;
@synthesize objectMappingProvider = _objectMappingProvider;

- (id)initWithObjectMappingProvider:(RKObjectMappingProvider *)objectMappingProvider
{
    self = [super init];
    if (self) {
        self.objectMappingProvider = objectMappingProvider;
    }
    return self;
}

- (void)startServer{
	// Create server using our custom MyHTTPServer class
	httpServer = [[RoutingHTTPServer alloc] init];
    
    // Tell server to use our custom MyHTTPConnection class.
	// [httpServer setConnectionClass:[RESTConnection class]];
	
	// Tell the server to broadcast its presence via Bonjour.
	// This allows browsers such as Safari to automatically discover our service.
	[httpServer setType:@"_http._tcp."];
	
	// Normally there's no need to run our server on any specific port.
	// Technologies like Bonjour allow clients to dynamically discover the server's port at runtime.
	// However, for easy testing you may want force a certain port so you can just hit the refresh button.
	[httpServer setPort:12345];
	
	// Serve files from our embedded Web folder
	NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Web"];
	DDLogInfo(@"Setting document root: %@", webPath);
	
	[httpServer setDocumentRoot:webPath];
    
    [httpServer handleMethod:@"GET" withPath:@"/images" block:^(RouteRequest *request, RouteResponse *response) {
        DDLogVerbose(@"%@", request);
        [response setHeader:@"Content-Type" value:@"application/json"];
        response.statusCode = 200;
        
        NSArray * images = self.imageServer.getImages;
        
#warning find out why the mapping is done so weirdly
        
        RKObjectMapping * mapping = [self.objectMappingProvider serializationMappingForClass:[IAImage class]];
        RKObjectSerializer* serializer = [RKObjectSerializer serializerWithObject:images mapping:mapping];
        
        NSError* error = nil;
        id params = [serializer serializationForMIMEType:RKMIMETypeJSON error:&error];
        
        if (error) {
            DDLogError(@"Serializing failed for source object %@ to MIME Type %@: %@", images, RKMIMETypeJSON, [error localizedDescription]);
        } else {
            NSString* data = [[NSString alloc] initWithData:[params data] encoding:NSUTF8StringEncoding];
            NSString *fullResponse = [[@"{\"images\":" stringByAppendingString:data] stringByAppendingString:@"}"];
            [response respondWithString:fullResponse];
        }
    }];
    
    [httpServer handleMethod:@"POST" withPath:@"/images" block:^(RouteRequest *request, RouteResponse *response) {
        DDLogVerbose(@"%@", request);
        [response setHeader:@"Content-Type" value:@"application/json"];
        response.statusCode = 201;
    }];
    
    [httpServer handleMethod:@"PUT" withPath:@"/images/:id" block:^(RouteRequest *request, RouteResponse *response) {
        DDLogVerbose(@"%@", request);
        [response setHeader:@"Content-Type" value:@"application/json"];
        response.statusCode = 201;
    }];
    
    [httpServer handleMethod:@"DELETE" withPath:@"/images/:id" block:^(RouteRequest *request, RouteResponse *response) {
        DDLogVerbose(@"%@", request);
        [response setHeader:@"Content-Type" value:@"application/json"];
        response.statusCode = 200;
    }];
    
    [httpServer handleMethod:@"GET" withPath:@"/images/:id" block:^(RouteRequest *request, RouteResponse *response) {
        DDLogVerbose(@"%@", request);
        [response setHeader:@"Content-Type" value:@"application/json"];
        response.statusCode = 200;
        
        NSNumber* number = [NSNumber numberWithInt:[[request param:@"id"] intValue]];
        IAImage* image = [self.imageServer getImage:number];
        
        RKObjectMapping * mapping = [self.objectMappingProvider serializationMappingForClass:[IAImage class]];
        RKObjectSerializer* serializer = [RKObjectSerializer serializerWithObject:image mapping:mapping];
        
        NSError* error = nil;
        id params = [serializer serializationForMIMEType:RKMIMETypeJSON error:&error];
        
        if (error) {
            DDLogError(@"Serializing failed for source object %@ to MIME Type %@: %@", image, RKMIMETypeJSON, [error localizedDescription]);
        } else {
            NSString* data = [[NSString alloc] initWithData:[params data] encoding:NSUTF8StringEncoding];
            DDLogInfo(@"%@", data);
            [response respondWithData:[params data]];
        }
    }];
    
    [httpServer handleMethod:@"PUT" withPath:@"/images/:id/display" block:^(RouteRequest *request, RouteResponse *response) {
        DDLogVerbose(@"%@", request);
        [response setHeader:@"Content-Type" value:@"application/json"];
        response.statusCode = 201;
    }];
    
	// Start the server (and check for problems)
	
	NSError *error;
	if(![httpServer start:&error])
	{
		DDLogError(@"Error starting HTTP Server: %@", error);
	}
}

@end
