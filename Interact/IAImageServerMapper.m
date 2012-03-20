//
//  InteractImageServerMapper.m
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-08.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import "IAImageServerMapper.h"
#import "RoutingHTTPServer.h"

@interface IAImageServerMapper() {
    RoutingHTTPServer *httpServer;
}

@property (strong, nonatomic) RKObjectMapping  *serializationMapping;

@end

@implementation IAImageServerMapper

@synthesize imageServer = _imageServer;
@synthesize serializationMapping = _serializationMapping;

- (RKObjectMapping *) serializationMapping {
    if(!_serializationMapping) {
        RKObjectMapping* imageMapping = [RKObjectMapping mappingForClass:[IAImage class]];
        [imageMapping mapKeyPath:@"id" toAttribute:@"identifier"];
        [imageMapping mapKeyPath:@"name" toAttribute:@"name"];
        [imageMapping mapKeyPath:@"src" toAttribute:@"source"];

        _serializationMapping = [imageMapping inverseMapping];
    }
    return _serializationMapping;
}

- (void)startServer{
    // Configure our logging framework.
	// To keep things simple and fast, we're just going to log to the Xcode console.
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	
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
        [response respondWithString:@"{\"images\":[{\"id\": 1,\"name\": \"image\",\"src\": \"https://encrypted.google.com/images/srpr/logo3w.png\"}]}"];
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
        
        RKObjectSerializer* serializer = [RKObjectSerializer serializerWithObject:image mapping:self.serializationMapping];
        
        NSError* error = nil;
        id params = [serializer serializationForMIMEType:RKMIMETypeJSON error:&error];
        
        if (error) {
            DDLogError(@"Serializing failed for source object %@ to MIME Type %@: %@", image, RKMIMETypeJSON, [error localizedDescription]);
        } else {
            NSString* data = [[NSString alloc] initWithData:[params data] encoding:NSUTF8StringEncoding];
            NSString *fullResponse = [[@"{\"images\":" stringByAppendingString:data] stringByAppendingString:@"}"];
            [response respondWithString:fullResponse];
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
