//
//  RouteResponse+Serializer.m
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 2012-04-18.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import "RouteResponse+Serializer.h"

#import <RestKit/RestKit.h>

#import "IAInteract.h"

@implementation RouteResponse (Serializer)

-(void)respondWith:(id)data withInteract:(IAInteract *)interact
{
    RKObjectSerializer* serializer = [interact serializerForObject:data];
    
    NSError* error = nil;
    id params = [serializer serializationForMIMEType:RKMIMETypeJSON error:&error];
    
    if (error) {
        self.statusCode = 500;
        DDLogError(@"Serializing failed for source object %@ to MIME Type %@: %@", data, RKMIMETypeJSON, [error localizedDescription]);
    } else {
        self.statusCode = 200;
        [self respondWithData:[params data]];
        DDLogInfo(@"%@", [[NSString alloc] initWithData:[params data] encoding:NSUTF8StringEncoding]);
    }
}

@end
