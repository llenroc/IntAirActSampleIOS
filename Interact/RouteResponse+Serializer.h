//
//  RouteResponse+Serializer.h
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 2012-04-18.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import <RoutingHTTPServer/RoutingHTTPServer.h>

@class IAInteract;

@interface RouteResponse (Serializer)

-(void)respondWith:(id)data withInteract:(IAInteract*)interact;

@end
