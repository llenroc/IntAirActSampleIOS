//
//  IAInteract.h
//  Interact
//
//  Created by O'Keeffe Arlo Louis on 12-03-28.
//  Copyright (c) 2012 Fachhochschule Gelsenkirchen Abt. Bocholt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <RestKit/RestKit.h>
#import <RoutingHTTPServer/RoutingHTTPServer.h>

#import "IAServer.h"

@class IADevice;

@interface IAInteract : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate>

@property (strong, nonatomic) RKObjectMappingProvider * objectMappingProvider;
@property (strong, nonatomic) RKObjectRouter * router;
@property (strong, nonatomic) RoutingHTTPServer * httpServer;

- (RKObjectManager *)objectManagerForDevice:(IADevice *)device;
- (NSString *)resourcePathFor:(NSObject*)resource withAction:(NSString*)action forObjectManager:(RKObjectManager *)manager;
- (void) registerServer:(id<IAServer>) server;
- (RKObjectSerializer *)serializerForObject:(id) object;
- (NSArray *)getDevices;

@end
